import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/text_styles.dart';

import 'logic.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Resolving the logic is what starts the session check — `onInit` owns
    // the delay and the routing decision.
    Get.find<SplashLogic>();

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
            const SizedBox(height: 10),
            const Text("TARA DRIVER - តារា តាក់សុី",
                style: AppTextStyles.heading),
          ],
        ),
      ),
    );
  }
}
