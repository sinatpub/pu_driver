import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/logic.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

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
/// Not interactive. The pill in the app bar stays the single place
/// availability is toggled (`DD-09`).
class DriverStatusCard extends StatelessWidget {
  const DriverStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLogic app = Get.find<AppLogic>();
    return Obx(() {
      final bool isOnline = app.state.isOnline.value;
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
    required this.badgeLabel,
  });

  final bool isOnline;
  final String title;
  final String message;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      floating: true,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: context.texts.subtitle.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: context.texts.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.s12),
          TBadge(
            label: badgeLabel,
            tone: isOnline ? TBadgeTone.success : TBadgeTone.neutral,
          ),
        ],
      ),
    );
  }
}
