import 'dart:async';
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/services/session_service.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // D-01 (docs/12) — was a presence-only check against the legacy
  // `RegisterModel` blob in shared prefs, with no error handling: a
  // malformed stored blob would throw out of this (uncaught, since it's a
  // fire-and-forget call from a `Future.delayed` in initState) and strand
  // the driver on the splash screen forever, matching the passenger app's
  // documented M-14 bug. Now goes through `SessionService`, which also
  // migrates that legacy blob into secure storage on first read, and any
  // failure reading it falls back to login instead of hanging.
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
      Get.offNamed(
        AppRoutes.home,
      );
    } else {
      Get.offNamed(
        AppRoutes.login,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermissionLocation();
    Future.delayed(const Duration(seconds: 3), () {
      checkDriverToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Image.asset("assets/image/png/Tara2.png"),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text("TARA DRIVER - តារា តាក់សុី",
                style: AppTextStyles.heading),
          ],
        ),
      ),
    );
  }
}
