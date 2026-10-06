import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/app/logic.dart';
import 'package:pu_taxi_driver/app/state.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

/// UX-redesign C2 — what the home map says about the driver's availability.
///
/// The prototype floats an earnings card here ("Today · 6 trips · ៛45,200").
/// **That card is not built** (`DD-07`): there is no earnings endpoint, and
/// what a trip earns a driver is an open business question — the earnings
/// domain deliberately refuses to guess it. Showing a number here would
/// mean inventing one.
///
/// So the card states the one thing the app does know, and which the map
/// otherwise leaves ambiguous: whether requests are coming.
///
/// The pill in the app bar stays the single place availability is toggled
/// (`DD-09`).
///
/// It is also where the approval check shows (DD-52), now that no card covers
/// the home for it: a line and a thin bar while the check runs, and "couldn't
/// check" with a retry — the card's one button — when it gave no answer.
class DriverStatusCard extends StatelessWidget {
  const DriverStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLogic app = Get.find<AppLogic>();
    return Obx(() {
      final bool isOnline = app.state.isOnline.value;
      if (app.state.approvalStatus.value == DriverApprovalStatus.unknown) {
        return app.state.approvalCheckFailed.value
            ? DriverStatusCardView(
                isOnline: false,
                title: 'APPROVAL_CHECK_FAILED'.tr(),
                message: 'APPROVAL_CHECK_FAILED_DES'.tr(),
                actionLabel: 'PLEASE_TRY_AGAIN'.tr(),
                onAction: app.fetchCurrentDriveInfo,
              )
            : DriverStatusCardView(
                isOnline: false,
                title: 'YOU_ARE_OFFLINE'.tr(),
                message: 'APPROVAL_CHECKING'.tr(),
                busy: true,
              );
      }
      return DriverStatusCardView(
        isOnline: isOnline,
        title: isOnline ? 'YOU_ARE_ONLINE'.tr() : 'YOU_ARE_OFFLINE'.tr(),
        message: isOnline ? 'ONLINE_SUB'.tr() : 'OFFLINE_SUB'.tr(),
        badgeLabel: isOnline ? 'ONLINE'.tr() : 'OFFLINE'.tr(),
      );
    });
  }
}

/// The card itself — no GetX, no localisation lookups, so it can be pumped.
class DriverStatusCardView extends StatelessWidget {
  const DriverStatusCardView({
    super.key,
    required this.isOnline,
    required this.title,
    required this.message,
    this.badgeLabel,
    this.busy = false,
    this.actionLabel,
    this.onAction,
  });

  final bool isOnline;
  final String title;
  final String message;

  /// "Online" / "Offline" at the right. Left out while the approval check is
  /// running or has failed: the card is then about the check.
  final String? badgeLabel;

  /// Something is on its way: a thin moving bar under the text.
  final bool busy;

  /// One button under the text, when there is something to retry.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    final String? badge = badgeLabel;
    final String? action = actionLabel;

    return TCard(
      floating: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style:
                          context.texts.subtitle.copyWith(color: c.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: context.texts.caption
                          .copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...<Widget>[
                const SizedBox(width: Insets.s12),
                TBadge(
                  label: badge,
                  tone: isOnline ? TBadgeTone.success : TBadgeTone.neutral,
                ),
              ],
            ],
          ),
          if (busy) ...<Widget>[
            const SizedBox(height: Insets.s12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: c.brandIdentity,
                backgroundColor: c.borderDivider,
              ),
            ),
          ],
          // Under the text, not beside it: a Khmer label is long, and at
          // 320 px there is no room for both on one line.
          if (action != null) ...<Widget>[
            const SizedBox(height: Insets.s12),
            TButton(
              label: action,
              variant: TButtonVariant.secondary,
              size: TButtonSize.small,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
