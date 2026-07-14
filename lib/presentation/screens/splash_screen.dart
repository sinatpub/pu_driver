import 'dart:async';
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/storages/get_storages.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/presentation/screens/drawer_screen.dart';
import 'package:tara_driver_application/presentation/screens/login_page.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void checkDriverToken(BuildContext context) async {
    var driverData = await StorageGet.getDriverData();
    if (driverData != null) {
      Taxi.shared.checkDriverAvailability();
      AppConstant.driverToken = driverData.data?.token;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => DrawerScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermissionLocation();
    Future.delayed(const Duration(seconds: 3), () {
      checkDriverToken(context);
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
