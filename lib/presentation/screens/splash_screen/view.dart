import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/core/theme/tokens.dart';

import 'logic.dart';

/// UX-redesign S4 (`03 S01`, `DD-23`): the logo in a badge and the wordmark,
/// on `bg.page`. No Skip and no boot log — the delay, the permission request
/// and the routing all stay in [SplashLogic], untouched.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Resolving the logic is what starts the session check — `onInit` owns
    // the delay and the routing decision.
    Get.find<SplashLogic>();

    return Scaffold(
      backgroundColor: context.colors.bgPage,
      body: const Center(child: SplashMark()),
    );
  }
}

/// Logo badge, brand name and role, stacked in one column.
///
/// The badge shows the launcher icon itself (`launcher_driver_1024.png`), so
/// the splash matches the home-screen icon. Below it: "PU TAXI" with the Khmer
/// brand name under it, then a "Driver · អ្នកបើកបរ" pill that names the app's
/// audience without competing with the brand.
class SplashMark extends StatelessWidget {
  const SplashMark({super.key});

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 96,
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: Elevations.float,
          ),
          child: Image.asset(
            'assets/launcher/launcher_driver_1024.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: Insets.s20),
        Text(
          'PU TAXI',
          textAlign: TextAlign.center,
          style: context.texts.display.copyWith(
            color: c.textPrimary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: Insets.s4),
        Text(
          'ពូ តាក់ស៊ី',
          textAlign: TextAlign.center,
          style: context.texts.subtitle.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: Insets.s16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.s12,
            vertical: Insets.s4,
          ),
          decoration: BoxDecoration(
            color: c.brandTint,
            borderRadius: BorderRadius.circular(Radii.full),
          ),
          child: Text(
            'Driver · អ្នកបើកបរ',
            textAlign: TextAlign.center,
            style: context.texts.label.copyWith(color: c.brandText),
          ),
        ),
      ],
    );
  }
}
