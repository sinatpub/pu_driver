import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';

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

/// Logo badge + wordmark.
///
/// Which logo belongs in the badge (`Tara2.png` or `logo_app.jpg`) is an open
/// brand question (`03 S01`); this keeps today's `Tara2.png` and today's words
/// ("TARA DRIVER - តារា តាក់សុី"), set on two lines.
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
          padding: const EdgeInsets.all(Insets.s12),
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.borderDivider),
            boxShadow: Elevations.float,
          ),
          child: Image.asset('assets/image/png/Tara2.png'),
        ),
        const SizedBox(height: Insets.s16),
        Text(
          'TARA DRIVER',
          textAlign: TextAlign.center,
          style: context.texts.display.copyWith(
            color: c.textPrimary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: Insets.s4),
        Text(
          'តារា តាក់សុី',
          textAlign: TextAlign.center,
          style: context.texts.subtitle.copyWith(color: c.brandText),
        ),
      ],
    );
  }
}
