import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/widgets/ds/t_motion.dart';

/// UX-redesign P1 — the route transition (`02 §15`): fade + 10 px rise over
/// [Motion.screen], fade only under reduced motion.
///
/// GetX uses `GetMaterialApp.customTransition` only for routes without a
/// transition of their own, so `/home` keeps `Transition.noTransition`.
///
/// **Android only** ([appRouteTransition]). GetX's custom-transition branch
/// does not wrap the page in its iOS back-swipe detector, so installing this
/// on iOS would silently remove swipe-to-go-back. iOS keeps the platform
/// slide (and the gesture), at the same [Motion.screen] duration.
class FadeRiseTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> eased =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final Widget faded = FadeTransition(opacity: eased, child: child);
    if (reduceMotion(context)) return faded;
    return AnimatedBuilder(
      animation: eased,
      builder: (BuildContext context, Widget? child) => Transform.translate(
        offset: Offset(0, Motion.screenRise * (1 - eased.value)),
        child: child,
      ),
      child: faded,
    );
  }
}

/// The transition to install app-wide for [platform].
CustomTransition? appRouteTransition(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ? null : FadeRiseTransition();
