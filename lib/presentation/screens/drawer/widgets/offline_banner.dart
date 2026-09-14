import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/screens/drawer/logic.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import '../../../widgets/ds/t_motion.dart';

/// UX-redesign C1 — the shell's connectivity banner.
///
/// Amber rather than the old full-width red (`DD-26`): losing signal is a
/// condition to state, not a crash to alarm about, and red next to a
/// red-orange brand reads as failure.
///
/// The copy promises reconnection because that is true — the socket retries
/// indefinitely with a backoff and buffers emits meanwhile
/// (`docs/reverse-engineering/04 §4-§5`).
///
/// Renders **nothing** while connected, so it cannot disturb the layout in the
/// normal case. That was already true of the banner it replaces.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final DrawerLogic logic = Get.find<DrawerLogic>();
    final bool reduce = reduceMotion(context);
    // P1 (`05` Motion): slides down over 200 ms; fades only under reduced
    // motion. The online check itself is unchanged.
    return Obx(
      () => AnimatedSwitcher(
        duration: Motion.banner,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final Widget faded = FadeTransition(opacity: animation, child: child);
          if (reduce) return faded;
          return SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
                    .animate(animation),
            child: faded,
          );
        },
        // Keyed children: the switcher animates when the connection flips.
        child: logic.state.connection.value
            ? const SizedBox.shrink(key: ValueKey<String>('online'))
            : TBanner(
                key: const ValueKey<String>('offline'),
                message: 'NO_INTERNET_RECONNECTING'.tr(),
              ),
      ),
    );
  }
}
