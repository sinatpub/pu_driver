import 'dart:async';

import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/services/session_service.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';

import 'state.dart';

/// D-01 (`12`) — was a presence-only check against the legacy `RegisterModel`
/// blob in shared prefs, with no error handling: a malformed stored blob would
/// throw out of this (uncaught, since it was a fire-and-forget call from a
/// `Future.delayed` in `initState`) and strand the driver on the splash screen
/// forever, matching the passenger app's documented M-14 bug. Now goes through
/// [SessionService], which also migrates that legacy blob into secure storage
/// on first read, and any failure reading it falls back to login.
///
/// Moved out of `_SplashScreenState` per `14` §3.3 — routing on a session
/// check is orchestration, not rendering.
class SplashLogic extends GetxController {
  final SplashState state = SplashState();

  /// Matches the delay the screen has always used.
  static const splashDelay = Duration(seconds: 3);

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    requestPermissionLocation();
    _timer = Timer(splashDelay, checkDriverToken);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> checkDriverToken() async {
    String? token;
    try {
      token = await SessionService.instance.getToken();
    } catch (_) {
      token = null;
    }
    if (token != null) {
      Taxi.shared.checkDriverAvailability();
      // Every other route to `home` clears the stack instantly (login,
      // logout, language switch, cancel) — this is the one case leaving
      // the splash screen, so it keeps a visible transition.
      Get.offNamed(AppRoutes.home);
    } else {
      Get.offNamed(AppRoutes.login);
    }
  }
}
