import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/app/logic.dart';
import 'package:pu_taxi_driver/app/state.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/screens/contact_us/logic.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

/// The approval gate over the shell body (UX-redesign C1, redrawn in DD-52).
///
/// **It appears only for a driver who is blocked**: waiting for approval, or
/// not approved. Then it is a full page under the app bar, because the map
/// behind it is of no use to a driver who cannot work.
///
/// It no longer appears while the status is being checked. That used to put
/// a card over a washed-out home on every launch, for every driver — nearly
/// all of whom are approved — and the same card stayed up, still saying
/// "checking", when the check had failed. Both of those are now a line on
/// the home status card (`DriverStatusCard`), with a retry when it failed.
///
/// **Going online still fails closed.** Hiding the gate is not approval:
/// `AppLogic.toggle` and the app-bar pill both test `isApproved`, which is
/// false until a check has answered.
///
/// It covers the body only. The app bar stays reachable, as it always has —
/// that is how a blocked driver still gets to the drawer and to support.
class ApprovalGate extends StatelessWidget {
  const ApprovalGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLogic app = Get.find<AppLogic>();
    return Obx(() {
      final DriverApprovalStatus status = app.state.approvalStatus.value;
      final bool rejected = status == DriverApprovalStatus.rejected;
      if (!rejected && status != DriverApprovalStatus.pending) {
        return const SizedBox.shrink();
      }

      return Positioned.fill(
        child: ApprovalGateView(
          status: status,
          title: rejected
              ? 'APPROVAL_REJECTED_TITLE'.tr()
              : 'WAITING_APPROVED_FROM_ADMIN'.tr(),
          message:
              rejected ? 'APPROVAL_REJECTED_DESC'.tr() : 'WAITING_DES'.tr(),
          // A rejected application has no next step to show: the page says
          // what to do instead.
          steps: rejected
              ? const <ApprovalStep>[]
              : <ApprovalStep>[
                  ApprovalStep(
                    'APPROVAL_STEP_SENT'.tr(),
                    ApprovalStepState.done,
                  ),
                  ApprovalStep(
                    'APPROVAL_STEP_REVIEW'.tr(),
                    ApprovalStepState.current,
                  ),
                  ApprovalStep(
                    'APPROVAL_STEP_READY'.tr(),
                    ApprovalStepState.upcoming,
                  ),
                ],
          supportLabel: 'CONTACT_SUPPORT'.tr(),
          onSupport: _contactSupport,
          checkAgainLabel: 'APPROVAL_CHECK_AGAIN'.tr(),
          checking: app.state.approvalChecking.value,
          onCheckAgain: app.fetchCurrentDriveInfo,
        ),
      );
    });
  }

  /// Reuses the contact screen's launcher rather than re-implementing a
  /// `tel:` intent. Guarded because the binding lives on the shell route.
  static void _contactSupport() {
    if (!Get.isRegistered<ContactUsLogic>()) return;
    final ContactUsLogic logic = Get.find<ContactUsLogic>();
    logic.callPhone(logic.state.smartPhone.replaceAll(' ', ''));
  }
}

/// Where one step of the approval stands.
enum ApprovalStepState { done, current, upcoming }

/// One line of "what happens next" on the waiting page.
class ApprovalStep {
  const ApprovalStep(this.label, this.state);

  final String label;
  final ApprovalStepState state;
}

/// The blocked page for one status: [DriverApprovalStatus.pending] or
/// [DriverApprovalStatus.rejected].
///
/// Takes its copy as parameters and holds no GetX or localisation lookups, so
/// each state can be pumped in a widget test.
class ApprovalGateView extends StatelessWidget {
  const ApprovalGateView({
    super.key,
    required this.status,
    required this.title,
    required this.message,
    this.steps = const <ApprovalStep>[],
    required this.supportLabel,
    this.onSupport,
    required this.checkAgainLabel,
    this.onCheckAgain,
    this.checking = false,
  });

  final DriverApprovalStatus status;
  final String title;
  final String message;

  /// Shown as a short list under the message. Empty for a rejection.
  final List<ApprovalStep> steps;

  final String supportLabel;
  final VoidCallback? onSupport;

  /// The driver's own way to ask again, rather than restarting the app to
  /// find out whether they were approved.
  final String checkAgainLabel;
  final VoidCallback? onCheckAgain;

  /// A check is on its way: the "check again" button spins.
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return ColoredBox(
      color: c.bgPage,
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Insets.screen,
                  Insets.s32,
                  Insets.screen,
                  Insets.s16,
                ),
                child: Column(
                  children: <Widget>[
                    _icon(context),
                    const SizedBox(height: Insets.s16),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style:
                            context.texts.title.copyWith(color: c.textPrimary),
                      ),
                    ),
                    const SizedBox(height: Insets.s8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: context.texts.bodySecondary.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    if (steps.isNotEmpty) ...<Widget>[
                      const SizedBox(height: Insets.s24),
                      TCard(
                        child: Column(
                          children: <Widget>[
                            for (int i = 0; i < steps.length; i++) ...<Widget>[
                              if (i > 0) const SizedBox(height: Insets.s12),
                              _ApprovalStepRow(step: steps.elementAt(i)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen,
                0,
                Insets.screen,
                Insets.s16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TButton(label: supportLabel, onPressed: onSupport),
                  const SizedBox(height: Insets.s8),
                  TButton(
                    label: checkAgainLabel,
                    variant: TButtonVariant.tertiary,
                    size: TButtonSize.small,
                    loading: checking,
                    onPressed: onCheckAgain,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool rejected = status == DriverApprovalStatus.rejected;
    final Color tone = rejected ? c.danger : c.warning;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: TIcon(
          rejected ? DsIcons.close : DsIcons.clock,
          size: TIconSize.lg,
          color: tone,
        ),
      ),
    );
  }
}

class _ApprovalStepRow extends StatelessWidget {
  const _ApprovalStepRow({required this.step});

  final ApprovalStep step;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool current = step.state == ApprovalStepState.current;

    return Row(
      children: <Widget>[
        SizedBox(
          width: TIconSize.md.value,
          height: TIconSize.md.value,
          child: switch (step.state) {
            ApprovalStepState.done => TIcon(DsIcons.check, color: c.success),
            ApprovalStepState.current => TIcon(DsIcons.clock, color: c.warning),
            // Not started: an empty ring, the same size as the icons above.
            ApprovalStepState.upcoming => Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.borderControl, width: 1.5),
                  ),
                ),
              ),
          },
        ),
        const SizedBox(width: Insets.s12),
        Expanded(
          child: Text(
            step.label,
            style: (current ? context.texts.bodyStrong : context.texts.body)
                .copyWith(
              color: step.state == ApprovalStepState.upcoming
                  ? c.textSecondary
                  : c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
