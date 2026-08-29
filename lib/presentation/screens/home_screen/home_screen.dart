import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tara_driver_application/app/alert_widget.dart';
import 'package:tara_driver_application/core/helper/local_notification_helper.dart';
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/routing/route_arguments.dart';
import 'package:tara_driver_application/core/storages/get_storages.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/check_platform_device.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:tara_driver_application/data/models/current_driver_info_model.dart';
import 'package:tara_driver_application/data/models/register_model.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/profile/presentation/controller/profile_controller.dart';
import 'package:tara_driver_application/presentation/blocs/get_current_driver_info_bloc.dart';
import 'package:tara_driver_application/presentation/blocs/get_version_app.dart';
import 'package:tara_driver_application/presentation/screens/home_screen/bloc/home_bloc.dart';
import 'package:tara_driver_application/presentation/widgets/widge_update.dart';
import 'package:tara_driver_application/services/location_service.dart';
import 'package:tara_driver_application/taxi_single_ton/init_socket.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/datasources/device_info_repo.dart';

enum _LocationLoadStatus { inProgress, success, permissionDenied, failure }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DeviceInfoRepo deviceInfoRepo = DeviceInfoRepo();

  // * Socket Class
  DriverSocketService driverSocket = DriverSocketService();
  bool isCameraInitialized = false;
  int typeVehicleId = 0;

  ///=========== Update Version ==============
  bool updateVersion = false;
  String currentVersionIos = "1.1.9";
  String currentVersionAndroid = "1.1.9";
  String releaseDateVersionIos = "2026-04-25";
  String releaseDateVersionAndroid = "026-04-25";

  double _currentZoom = 19.0;

  final Set<Marker> _markers = {};
  late BitmapDescriptor driverMarker;
  StreamSubscription<Position>? _positionSub;
  GoogleMapController? _mapController;

  LatLng? currentLocation;
  _LocationLoadStatus _locationStatus = _LocationLoadStatus.inProgress;
  String? _locationError;

  ///=========== Update Version ==============

  Future<void> _initLocation() async {
    setState(() => _locationStatus = _LocationLoadStatus.inProgress);

    final hasPermission = await LocationService.instance.requestPermission();
    if (!mounted) return;
    if (!hasPermission) {
      setState(() => _locationStatus = _LocationLoadStatus.permissionDenied);
      return;
    }

    try {
      final position = await LocationService.instance.primeCurrentLocation();
      if (!mounted) return;
      if (position == null) {
        setState(() => _locationStatus = _LocationLoadStatus.failure);
        return;
      }
      _updateMarker(LatLng(position.latitude, position.longitude), position.heading);
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        _locationStatus = _LocationLoadStatus.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString();
        _locationStatus = _LocationLoadStatus.failure;
      });
    }

    LocationService.instance.start();
    _positionSub = LocationService.instance.positionStream.listen((position) {
      _updateMarker(
        LatLng(position.latitude, position.longitude),
        position.heading,
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _updateMarker(LatLng position, double bearing) async {
    driverMarker = await loadCustomMarkerTukTuk(typeVehicleId: typeVehicleId);
    _markers.add(Marker(
      markerId: const MarkerId("driverMarker"),
      position: position,
      icon: driverMarker,
      rotation: bearing, // rotate in direction of heading
      anchor: const Offset(0.5, 0.5),
      flat: true,
    ));
    setState(() {});
  }

  Future<void> pushFCMToken() async {
    try {
      SharedPreferences _pref = await SharedPreferences.getInstance();
      String? fcmToken = _pref.getString("fcm_token_data");
      if (fcmToken == null || fcmToken == '') {
        await deviceInfoRepo.deviceCreateOrUpdate();
      }
    } catch (e) {
      debugPrint("Error fcm token $e");
    }
  }

  int _mapKey = 0;

  @override
  void initState() {
    super.initState();
    NotificationLocal().requestPermission();

    /// Get FCM Token for notification
    pushFCMToken();
    final profileController = Get.find<ProfileController>();
    profileController.fetchProfile();
    // Reacts to every load, not just this one — the controller is a
    // permanent, app-lifetime singleton re-fetched elsewhere too
    // (see calculate_fee_screen.dart), mirroring the old global bloc.
    ever<ProfileStatus>(profileController.status, (status) {
      if (status == ProfileStatus.loaded) {
        final vehicle = profileController.profile.value?.data?.vehicle;
        if (vehicle?.typeVehicleId != null) {
          typeVehicleId = vehicle!.typeVehicleId!;
          // Regenerate the marker with the now-known vehicle icon from the
          // last known fix — no need to re-fetch GPS or re-report to the
          // server just to redraw an icon.
          final position = LocationService.instance.lastPosition;
          if (position != null) {
            _updateMarker(
              LatLng(position.latitude, position.longitude),
              position.heading,
            );
          }
        }
      }
    });
    BlocProvider.of<VersionAppBloc>(context).add(GetVersionApp());
    BlocProvider.of<HomeBloc>(context).add(CheckDriverStatusEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      registerSocket();
    });
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _mapKey = 0;
      });
    });
    initAsync();
  }

  Future<void> initAsync() async {
    await NotificationLocal().requestPermission();
    BlocProvider.of<HomeBloc>(context).add(CheckDriverStatusEvent());
    await _initLocation();
  }

  // * Register Socket
  void registerSocket() async {
    RegisterModel? driverData = await StorageGet.getDriverData();
    if (driverData?.data?.driver?.id != null) {
      driverSocket.connectToSocket(
        AppConstant.socketBasedUrl,
        "${driverData?.data?.driver?.id}",
        "Driver",
        context: context,
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CurrentDriverInfoBloc, CurrentDriverInfoState>(
        listener: (blocContext, state) {
          if (state is CurrentDriverInfoLoaded) {
            if (state.currentDriverInfoModel.data != null &&
                state.currentDriverInfoModel.data!.driver != null &&
                state.currentDriverInfoModel.data!.driver!.vehicle != null) {
              setState(() {});
            }
          }
          handleStateChanges(state);
        },
        builder: (blocContext, state) {
          return BlocListener<VersionAppBloc, VersionAppState>(
            listener: (context, state) {
              if (state is VersionAppLoaded) {
                var data = state.versionData.data;
                var plateform = checkPlatformDevice();
                if (plateform == "Android") {
                  if (data!.versionAndroid.toString() ==
                          currentVersionAndroid ||
                      data.releaseDate == releaseDateVersionAndroid) {
                    setState(() {
                      updateVersion = false;
                    });
                  } else {
                    setState(() {
                      updateVersion = true;
                    });
                  }
                }
                if (plateform == "ios") {
                  if (data!.versionIos.toString() == currentVersionIos ||
                      data.releaseDateIos == releaseDateVersionIos) {
                    setState(() {
                      updateVersion = false;
                    });
                  } else {
                    setState(() {
                      updateVersion = true;
                    });
                  }
                }
              }
            },
            child: Column(
              children: [
                Expanded(
                    child: Stack(
                  children: [
                    buildGoogleMap(),
                    updateVersion == false
                        ? Container()
                        : Positioned.fill(
                            left: 0,
                            right: 0,
                            child: Container(
                                color: AppColors.dark1.withAlpha(60),
                                child: Center(child: WidgetUpdate())),
                          ),
                  ],
                )),
                if (state is CurrentDriverLoading) const SizedBox(),
              ],
            ),
          );
        },
      ),
    );
  }

  void handleStateChanges(CurrentDriverInfoState state) {
    if (state is CurrentDriverLoading) {
      tlog("Current Driver Loading");
    } else if (state is CurrentDriverInfoLoaded) {
      tlog("Current Driver Loaded");
      navigateBasedOnDriverStatus(state.currentDriverInfoModel.data!);
    } else {
      tlog("Current Driver Fail");
    }
  }

  void navigateBasedOnDriverStatus(DataDriverInfo dataDriver) {
    if (dataDriver.status == 6) {
      navigateToCalculateFeeScreen(dataDriver);
    } else if (dataDriver.status != null) {
      navigateToBookingScreen(dataDriver);
    }
  }

  void navigateToCalculateFeeScreen(DataDriverInfo dataDriver) {
    Get.offNamed(
      AppRoutes.calculateFee,
      arguments: CalculateFeeScreenArgs(
        dataDriverInfo: dataDriver,
        routFrom: "FromHome",
        startAddress: dataDriver.startAddress.toString(),
        endAddress: dataDriver.endAddress.toString(),
      ),
    );
  }

  void navigateToBookingScreen(DataDriverInfo dataDriver) {
    AlertWidget().onProcessBooking(
      context,
    );
    Future.delayed(Duration(seconds: 2), () {
      Get.offNamed(
        AppRoutes.booking,
        arguments: BookingScreenArgs(
          startTime: dataDriver.startTime.toString(),
          latStart: double.parse(dataDriver.startLatitude.toString()),
          lngStart: double.parse(dataDriver.startLongitude.toString()),
          refreshApp: true,
          typeVehicleId: dataDriver.driver!.vehicle!.typeVehicleId!,
          pricrVehicle: dataDriver.driver!.vehicle!.pricrVehicle == null
              ? 1200
              : dataDriver.driver!.vehicle!.pricrVehicle!,
          namePassanger: dataDriver.passenger!.name.toString(),
          phonePassanger: dataDriver.passenger!.phone.toString(),
          imagePassanger: dataDriver.passenger!.profileImage.toString(),
          timeOut: 30,
          processStepBook: getProcessStepBook(dataDriver.status!),
          bookingCode: int.parse(dataDriver.bookingCode.toString()),
          bookingId: int.parse(dataDriver.id.toString()),
          latPassenger: double.parse(
              dataDriver.passenger!.lastLocation!.latitude.toString()),
          lngPassenger: double.parse(
              dataDriver.passenger!.lastLocation!.longitude.toString()),
          latDriver: double.parse(
              dataDriver.driver!.lastLocation!.latitude.toString()),
          lngDriver: double.parse(
              dataDriver.driver!.lastLocation!.longitude.toString()),
          passengerId: dataDriver.passenger!.id!,
          desLatPassenger: dataDriver.endLatitude == null
              ? null
              : double.parse(dataDriver.endLatitude!.toString()),
          desLngPassenger: dataDriver.endLongitude == null
              ? null
              : double.parse(dataDriver.endLongitude!.toString()),
        ),
      );
    });
  }

  int getProcessStepBook(int status) {
    switch (status) {
      case 8:
        return 3;
      case 3:
        return 4;
      default:
        return 2;
    }
  }

  Widget buildGoogleMap() {
    switch (_locationStatus) {
      case _LocationLoadStatus.inProgress:
        return const Center(child: CircularProgressIndicator());
      case _LocationLoadStatus.success:
        return GoogleMap(
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          key: ValueKey(_mapKey),
          mapType: MapType.normal,
          myLocationEnabled: false,
          indoorViewEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          trafficEnabled: true,
          initialCameraPosition: CameraPosition(
            target: currentLocation!,
            zoom: _currentZoom,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          onCameraMove: (CameraPosition position) {
            setState(() {
              _currentZoom = position.zoom;
            });
          },
        );
      case _LocationLoadStatus.permissionDenied:
        return const Center(child: Text('Location permission denied'));
      case _LocationLoadStatus.failure:
        return Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load location: ${_locationError ?? ''}'),
            MaterialButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: AppColors.info,
              onPressed: () async {
                await openAppSettings();
              },
              child: Text(
                'Open location permission',
                style: ThemeConstands.font16SemiBold
                    .copyWith(color: AppColors.dark4),
              ),
            )
          ],
        ));
    }
  }
}

Future<BitmapDescriptor> loadCustomMarker() async {
  BitmapDescriptor convertMarkerIcon = await BitmapDescriptor.asset(
    const ImageConfiguration(size: Size(90, 90)),
    "assets/marker/passenger_marker.png",
  );
  return convertMarkerIcon;
}

Future<BitmapDescriptor> loadCustomMarkerTukTuk({
  required int typeVehicleId,
}) async {
  BitmapDescriptor convertMarkerIcon = await BitmapDescriptor.asset(
    const ImageConfiguration(size: Size(30, 50)),
    typeVehicleId == 1
        ? "assets/marker/rickshaw_icon_svg.png"
        : typeVehicleId == 2
            ? "assets/marker/classis_car.png"
            : typeVehicleId == 3
                ? "assets/marker/mini_van.png"
                : typeVehicleId == 4
                    ? "assets/marker/SUV.png"
                    : typeVehicleId == 5
                        ? "assets/marker/alphard_vip.png"
                        : "",
  );
  return convertMarkerIcon;
}
