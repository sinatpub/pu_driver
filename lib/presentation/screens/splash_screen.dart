import 'dart:async';
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/storages/get_storages.dart';
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
  void checkDriverToken() async {
    var driverData = await StorageGet.getDriverData();
    if (driverData != null) {
      Taxi.shared.checkDriverAvailability();
      // Every other route to `home` clears the stack instantly (login,
      // logout, language switch, cancel) — this is the one case leaving
      // the splash screen, so it keeps a visible transition.
      Get.offNamed(AppRoutes.home, transition: Transition.fadeIn);
    } else {
      Get.offNamed(AppRoutes.login, transition: Transition.fadeIn);
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
