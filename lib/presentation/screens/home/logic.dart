import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pu_taxi_driver/app/alert_widget.dart';
import 'package:pu_taxi_driver/core/contracts/booking_status.dart';
import 'package:pu_taxi_driver/core/helper/local_notification_helper.dart';
import 'package:pu_taxi_driver/routes/app_routes.dart';
import 'package:pu_taxi_driver/routes/route_arguments.dart';
import 'package:pu_taxi_driver/core/utils/pretty_logger.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/domain/trip_state_machine.dart';
import 'package:pu_taxi_driver/presentation/screens/home/trip_resume.dart';
import 'package:pu_taxi_driver/core/storage/get_storages.dart';
import 'package:pu_taxi_driver/core/utils/app_constant.dart';
import 'package:pu_taxi_driver/core/utils/check_platform_device.dart';
import 'package:pu_taxi_driver/core/utils/load_custom_marker.dart';
import 'package:pu_taxi_driver/data/datasources/device_info_repo.dart';
import 'package:pu_taxi_driver/data/models/current_driver_info_model.dart';
import 'package:pu_taxi_driver/data/models/register_model.dart';
import 'package:pu_taxi_driver/app/logic.dart';
import 'package:pu_taxi_driver/presentation/screens/home/data/repository/version_check_repository.dart';
import 'package:pu_taxi_driver/services/location_service.dart';
import 'package:pu_taxi_driver/services/socket_service.dart';

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

    // DD-53: the app goes online by itself once the driver can be located,
    // so it has to be told when that is.
    final AppLogic app = Get.find<AppLogic>();
    app.setLocationReady(
      state.locationStatus.value == LocationLoadStatus.success,
    );
    ever<LocationLoadStatus>(
      state.locationStatus,
      (status) => app.setLocationReady(status == LocationLoadStatus.success),
    );

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
    state.markers.putMarker(Marker(
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
      return;
    }
    // Audit D-6, D-7: only an accepted, unfinished trip reopens, and only
    // when the server sent enough of it to drive. Otherwise the driver stays
    // on Home rather than being sent into a trip that is not there.
    final TripStage? stage = resumeStage(dataDriver.status);
    if (stage == null) return;
    final BookingScreenArgs? args = resumeBookingArgs(dataDriver, stage);
    if (args == null) {
      tlog('Not resuming trip ${dataDriver.id}: the server sent too little '
          'of it (status ${dataDriver.status})');
      return;
    }
    navigateToBookingScreen(args);
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

  void navigateToBookingScreen(BookingScreenArgs args) {
    // The 2s dialog-then-navigate sequence is carried over verbatim: the
    // "processing" dialog is shown first, then the push happens under it.
    // The arguments are built before it opens (audit D-6), so nothing in the
    // delayed callback can throw and leave the dialog up.
    AlertWidget().onProcessBooking(Get.context!);
    Future.delayed(const Duration(seconds: 2), () {
      Get.offNamed(AppRoutes.booking, arguments: args);
    });
  }
}
