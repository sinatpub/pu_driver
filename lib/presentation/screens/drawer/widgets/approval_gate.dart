import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/logic.dart';
import 'package:tara_driver_application/app/state.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/contact_us/logic.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C1 — the approval gate over the shell body.
///
/// **Fails closed, exactly as before**: only [DriverApprovalStatus.approved]
/// lifts it, so `unknown` — the value before the first
/// `get-current-drive-info` resolves — still blocks. That is the same test the
/// old overlay used (`AppLogic.isApproved`).
///
/// What changed is that the three blocked states no longer look identical
/// (`DD-08`). A rejected driver used to be told to wait for approval, and
/// every driver saw that message for a moment on each launch.
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
      if (status == DriverApprovalStatus.approved) {
        return const SizedBox.shrink();
      }

      final bool checking = status == DriverApprovalStatus.unknown;
      return Positioned.fill(
        child: ApprovalGateView(
          status: status,
          title: switch (status) {
            DriverApprovalStatus.unknown => 'APPROVAL_CHECKING'.tr(),
            DriverApprovalStatus.pending => 'WAITING_APPROVED_FROM_ADMIN'.tr(),
            DriverApprovalStatus.rejected => 'APPROVAL_REJECTED_TITLE'.tr(),
            DriverApprovalStatus.approved => '',
          },
          message: switch (status) {
            DriverApprovalStatus.unknown => 'APPROVAL_CHECKING_DES'.tr(),
            // Shipped in the translations since before the redesign and never
            // rendered until now.
            DriverApprovalStatus.pending => 'WAITING_DES'.tr(),
            DriverApprovalStatus.rejected => 'APPROVAL_REJECTED_DESC'.tr(),
            DriverApprovalStatus.approved => '',
          },
          // The fetch swallows its errors (`AppLogic.fetchCurrentDriveInfo`),
          // so a failed call leaves `unknown` forever. Without a retry the
          // driver's only way out is restarting the app.
          actionLabel:
              checking ? 'PLEASE_TRY_AGAIN'.tr() : 'CONTACT_SUPPORT'.tr(),
          onAction: checking ? app.fetchCurrentDriveInfo : _contactSupport,
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

/// The gate's appearance for one status.
///
/// Takes its copy as parameters and holds no GetX or localisation lookups, so
/// each of the three blocked states can be pumped in a widget test.
class ApprovalGateView extends StatelessWidget {
  const ApprovalGateView({
    super.key,
    required this.status,
    required this.title,
    required this.message,
    required this.actionLabel,
    this.onAction,
  });

  final DriverApprovalStatus status;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Container(
      color: c.blockingOverlay,
      padding: const EdgeInsets.all(Insets.s24),
      alignment: Alignment.center,
      child: TCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _icon(context),
            const SizedBox(height: Insets.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.texts.title.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: Insets.s8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.texts.bodySecondary.copyWith(
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: Insets.s24),
            TButton(
              label: actionLabel,
              variant: status == DriverApprovalStatus.rejected
                  ? TButtonVariant.primary
                  : TButtonVariant.secondary,
              size: TButtonSize.small,
              expand: false,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(BuildContext context) {
    final TaarraaColors c = context.colors;
    final (Color tone, String? icon) = switch (status) {
      DriverApprovalStatus.unknown => (c.textSecondary, null),
      DriverApprovalStatus.pending => (c.warning, DsIcons.clock),
      DriverApprovalStatus.rejected => (c.danger, DsIcons.close),
      DriverApprovalStatus.approved => (c.success, DsIcons.check),
    };

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: icon == null
            // `unknown` is a pending answer, not a verdict — a spinner says
            // "still checking", which is what is actually happening.
            ? SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(tone),
                ),
              )
            : TIcon(icon, size: TIconSize.lg, color: tone),
      ),
    );
  }
}
