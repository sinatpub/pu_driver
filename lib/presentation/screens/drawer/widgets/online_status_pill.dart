import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/logic.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_motion.dart';

/// UX-redesign C1 — the driver's availability control in the shell app bar.
///
/// Replaces `SwitchOnlineWidget` (a `flutter_switch`) with the prototype's
/// pill. **The toggle logic is unchanged**, including its asymmetry: the
/// approval gate only blocks going *online*. Turning off is always allowed,
/// exactly as before.
///
/// Everything else still belongs to [AppLogic] — the optimistic flip, the
/// rollback on failure and the EasyLoading overlay. This widget reads and
/// reports, nothing more.
///
/// No busy state: `AppState` has no in-flight flag, and adding one would be a
/// controller change rather than a restyle. The themed EasyLoading overlay
/// remains the signal that a toggle is in flight.
class OnlineStatusPill extends StatelessWidget {
  const OnlineStatusPill({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLogic app = Get.find<AppLogic>();
    return Obx(() {
      final bool isOnline = app.state.isOnline.value;
      return OnlineStatusPillView(
        isOnline: isOnline,
        label: isOnline ? 'ONLINE'.tr() : 'OFFLINE'.tr(),
        onTap: () {
          final bool next = !isOnline;
          // Carried over verbatim from `switch_online_widget.dart`: the guard
          // fires only when going online.
          if (next && !app.isApproved) {
            EasyLoading.showToast('WAITING_APPROVED_FROM_ADMIN'.tr());
            return;
          }
          app.toggle(next);
        },
      );
    });
  }
}

/// The pill itself. No GetX and no localisation lookups, so it can be pumped
/// in a widget test.
class OnlineStatusPillView extends StatelessWidget {
  const OnlineStatusPillView({
    super.key,
    required this.isOnline,
    required this.label,
    required this.onTap,
  });

  final bool isOnline;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
          child: Center(
            child: AnimatedContainer(
              duration: Motion.colorChange,
              padding: const EdgeInsets.symmetric(horizontal: Insets.s12),
              height: 40,
              decoration: BoxDecoration(
                color: isOnline ? c.successTint : c.bgRaised,
                borderRadius: BorderRadius.circular(Radii.full),
                border: Border.all(
                  color: isOnline ? c.success : c.borderControl,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // P1 (`02 §13`): the dot pulses at 1.4 s only while online.
                  TPulseDot(
                    size: 10,
                    color: isOnline ? c.successGraphic : c.borderControl,
                    period: Motion.pulseOnline,
                    active: isOnline,
                  ),
                  const SizedBox(width: Insets.s8),
                  Text(
                    label,
                    style: context.texts.micro.copyWith(
                      color: isOnline ? c.success : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
