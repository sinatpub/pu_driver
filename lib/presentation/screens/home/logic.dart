import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tara_driver_application/app/alert_widget.dart';
import 'package:tara_driver_application/core/contracts/booking_status.dart';
import 'package:tara_driver_application/core/helper/local_notification_helper.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/core/storage/get_storages.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/check_platform_device.dart';
import 'package:tara_driver_application/core/utils/load_custom_marker.dart';
import 'package:tara_driver_application/data/datasources/device_info_repo.dart';
import 'package:tara_driver_application/data/models/current_driver_info_model.dart';
import 'package:tara_driver_application/data/models/register_model.dart';
import 'package:tara_driver_application/app/logic.dart';
import 'package:tara_driver_application/features/version_check/data/repository/version_check_repository.dart';
import 'package:tara_driver_application/services/location_service.dart';
import 'package:tara_driver_application/taxi_single_ton/init_socket.dart';

import '../profile/logic.dart';
import '../profile/state.dart';
import 'state.dart';

/// D-04 (`12`). Everything below lived in `_HomeScreenState`: the GPS
/// subscription, the marker set, the version check, the profile worker and
/// the ride-status routing. Moved per `14` §3.3 — none of it is rendering.
///
/// `VersionCheckController` was built by hand inside `initState`
/// (`VersionCheckController(VersionCheckRepository(VersionCheckDatasource()))`);
/// its work is folded in here and its repository comes from [HomeBinding].
class HomeLogic extends GetxController {
  HomeLogic(this._versionRepository);

  final VersionCheckRepository _versionRepository;
  final DeviceInfoRepo _deviceInfoRepo = DeviceInfoRepo();
  final DriverSocketService driverSocket = DriverSocketService();

  final HomeState state = HomeState();

  // Version pins, carried over verbatim. P-16/D-14 territory: these are
  // hardcoded rather than read from the running build (`12`).
  static const currentVersionIos = "1.1.9";
  static const currentVersionAndroid = "1.1.9";
  static const releaseDateVersionIos = "2026-04-25";
  static const releaseDateVersionAndroid = "026-04-25";

  StreamSubscription<Position>? _positionSub;
  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    NotificationLocal().requestPermission();
    pushFCMToken();

    final profileLogic = Get.find<ProfileLogic>();
    profileLogic.fetchProfile();
    // Reacts to every load, not just this one — ProfileLogic is a permanent,
    // app-lifetime singleton re-fetched elsewhere too (see calculate_fee).
    ever<ProfileStatus>(profileLogic.state.status, (status) {
      if (status != ProfileStatus.loaded) return;
      final vehicle = profileLogic.state.profile.value?.data?.vehicle;
      if (vehicle?.typeVehicleId == null) return;
      state.typeVehicleId.value = vehicle!.typeVehicleId!;
      // Regenerate the marker with the now-known vehicle icon from the last
      // known fix — no need to re-fetch GPS or re-report to the server just
      // to redraw an icon.
      final position = LocationService.instance.lastPosition;
      if (position != null) {
        updateMarker(
          LatLng(position.latitude, position.longitude),
          position.heading,
        );
      }
    });

    checkVersion();

    // Replaces BlocConsumer<CurrentDriverInfoBloc, CurrentDriverInfoState>.
    // The fetch is triggered once from DrawerLogic.onInit
    // (AppLogic.fetchCurrentDriveInfo), the same trigger point the
    // bloc dispatch had; this reacts to each new value as the listener did.
    ever<CurrentDriverInfoModel?>(
      Get.find<AppLogic>().state.currentDriveInfo,
      (data) {
        if (data?.data != null) navigateBasedOnDriverStatus(data!.data!);
      },
    );

    initAsync();
  }

  @override
  void onClose() {
    _positionSub?.cancel();
    super.onClose();
  }

  Future<void> initAsync() async {
    await NotificationLocal().requestPermission();
    Get.find<AppLogic>().checkStatus();
    await initLocation();
  }

  Future<void> pushFCMToken() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final fcmToken = pref.getString("fcm_token_data");
      if (fcmToken == null || fcmToken == '') {
        await _deviceInfoRepo.deviceCreateOrUpdate();
      }
    } catch (e) {
      debugPrint("Error fcm token $e");
    }
  }

  Future<void> registerSocket() async {
    final RegisterModel? driverData = await StorageGet.getDriverData();
    if (driverData?.data?.driver?.id != null) {
      driverSocket.connectToSocket(
        AppConstant.socketBasedUrl,
        "${driverData?.data?.driver?.id}",
        "Driver",
        context: Get.context!,
      );
    }
  }

  Future<void> checkVersion() async {
    final result = await _versionRepository.getCurrentVersion();
    result.when(
      ok: (model) {
        final data = model.data;
        if (data == null) return;
        final platform = checkPlatformDevice();
        if (platform == "Android") {
          state.updateVersion.value =
              !(data.versionAndroid.toString() == currentVersionAndroid ||
                  data.releaseDate == releaseDateVersionAndroid);
        }
        if (platform == "ios") {
          state.updateVersion.value =
              !(data.versionIos.toString() == currentVersionIos ||
                  data.releaseDateIos == releaseDateVersionIos);
        }
      },
      err: (_) {},
    );
  }

  Future<void> initLocation() async {
    state.locationStatus.value = LocationLoadStatus.inProgress;

    final hasPermission = await LocationService.instance.requestPermission();
    if (!hasPermission) {
      state.locationStatus.value = LocationLoadStatus.permissionDenied;
      return;
    }

    try {
      final position = await LocationService.instance.primeCurrentLocation();
      if (position == null) {
        state.locationStatus.value = LocationLoadStatus.failure;
        return;
      }
      updateMarker(
          LatLng(position.latitude, position.longitude), position.heading);
      state.currentLocation.value =
          LatLng(position.latitude, position.longitude);
      state.locationStatus.value = LocationLoadStatus.success;
    } catch (e) {
      state.locationError.value = e.toString();
      state.locationStatus.value = LocationLoadStatus.failure;
      return;
    }

    LocationService.instance.start();
    _positionSub = LocationService.instance.positionStream.listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      updateMarker(latLng, position.heading);
      mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      state.currentLocation.value = latLng;
    });
  }

  Future<void> updateMarker(LatLng position, double bearing) async {
    final driverMarker =
        await loadCustomMarkerTukTuk(typeVehicleId: state.typeVehicleId.value);
    state.markers.add(Marker(
      markerId: const MarkerId("driverMarker"),
      position: position,
      icon: driverMarker,
      rotation: bearing, // rotate in direction of heading
      anchor: const Offset(0.5, 0.5),
      flat: true,
    ));
  }

  void navigateBasedOnDriverStatus(DataDriverInfo dataDriver) {
    if (dataDriver.status == BookingStatus.pendingPayment) {
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
    // The 2s dialog-then-navigate sequence is carried over verbatim: the
    // "processing" dialog is shown first, then the push happens under it.
    AlertWidget().onProcessBooking(Get.context!);
    Future.delayed(const Duration(seconds: 2), () {
      Get.offNamed(
        AppRoutes.booking,
        arguments: BookingScreenArgs(
          startTime: dataDriver.startTime.toString(),
          latStart: double.parse(dataDriver.startLatitude.toString()),
          lngStart: double.parse(dataDriver.startLongitude.toString()),
          refreshApp: true,
          typeVehicleId: dataDriver.driver!.vehicle!.typeVehicleId!,
          pricrVehicle: dataDriver.driver!.vehicle!.pricrVehicle ?? 1200,
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

  /// `08` M-21: any status outside 8/3 falls through to `enRouteToPickup`,
  /// including `cancel` (5) and `completed` (4/7). Pre-existing, carried over
  /// unchanged — flagged, not fixed, in this move.
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
}
