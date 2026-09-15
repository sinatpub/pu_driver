import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/contracts/booking_status.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/history/data/models/history_driver_info_model.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/routes/route_arguments.dart';

/// One trip in the riding-history list.
///
/// UX-redesign S1 (`03 S09`, `04 § B` HistoryCard, `DD-19`): avatar, invoice
/// in tabular figures with "passenger · date", the amount right, a status
/// badge, the route box and the distance/duration meta.
///
/// The fake `image_map.png` thumbnail is gone. Its `onTap` moved, unchanged,
/// to the card root — same route, same [MapHistoryDetailArgs] — and only when
/// [canOpenDetail] is true, which is exactly when the thumbnail used to render
/// (the completed tab). Cancelled cards stay non-tappable.
///
/// Every value keeps the formatter and the "UNKNOWN" rule the old card used.
class HistoryCardWidget extends StatelessWidget {
  const HistoryCardWidget({
    super.key,
    required this.item,
    required this.canOpenDetail,
  });

  final DataHistory item;

  /// True on the completed tab. A cancelled trip has no route to show.
  final bool canOpenDetail;

  bool get _isCompleted => item.status == BookingStatus.completed;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool isCancelled = item.status == BookingStatus.cancel;
    final String? method = item.payment!.paymentMethod;

    return TCard(
      padding: const EdgeInsets.all(14),
      onTap: canOpenDetail ? () => _openDetail(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _header(context, c),
          const SizedBox(height: Insets.s8),
          Wrap(
            spacing: Insets.s8,
            runSpacing: Insets.s4,
            children: <Widget>[
              TBadge(
                label: item.statusName.toString().toUpperCase().tr(),
                tone: _isCompleted ? TBadgeTone.success : TBadgeTone.danger,
                icon: _isCompleted ? DsIcons.check : DsIcons.close,
              ),
              if (method != null && method.isNotEmpty)
                TBadge(label: method, tone: TBadgeTone.neutral),
            ],
          ),
          const SizedBox(height: Insets.s12),
          _route(context, c, isCancelled),
          const SizedBox(height: Insets.s12),
          _meta(context, c),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Get.toNamed(
      AppRoutes.mapHistoryDetail,
      arguments: MapHistoryDetailArgs(
        cost: formatRielAmount(item.payment!.amount.toString()),
        duration: convertTimeString(item.payment!.duration.toString()),
        distand:
            formatDistanceWithUnits(item.payment!.distance.toString(), context),
        typeVehicleId: item.driver!.vehicle!.typeVehicleId!,
        latEnd: double.parse(item.endLatitude.toString()),
        latStart: double.parse(item.startLatitude.toString()),
        lngEnd: double.parse(item.endLongitude.toString()),
        lngStart: double.parse(item.startLongitude.toString()),
      ),
    );
  }

  Widget _header(BuildContext context, TaarraaColors c) {
    final String passengerName = item.passenger!.name.toString();
    // The old card printed "UNKNOWN" beside DATE_TIME for a trip that isn't
    // completed; here the subtitle simply omits the date.
    final String subtitle = _isCompleted
        ? '$passengerName · ${formatDateTime(item.startTime.toString())}'
        : passengerName;

    return Row(
      children: <Widget>[
        TAvatar(
          name: passengerName,
          imageUrl: item.passenger!.profileImage,
          size: 44,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '#${item.payment!.invoiceId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodyStrong.copyWith(
                  color: c.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.texts.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: Insets.s8),
        TAmount(text: '៛${formatRielAmount(item.payment!.amount.toString())}'),
      ],
    );
  }

  Widget _route(BuildContext context, TaarraaColors c, bool isCancelled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Insets.s12, vertical: 8),
      decoration: BoxDecoration(
        color: c.bgPage,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.borderDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _routeLine(
            context,
            dot: c.brandIdentity,
            label: 'PICKUP'.tr(),
            text: _isCompleted ? item.startAddress.toString() : 'UNKNOWN'.tr(),
          ),
          if (!isCancelled)
            _routeLine(
              context,
              dot: c.textSecondary,
              label: 'DESTINATION'.tr(),
              text: _isCompleted ? item.endAddress.toString() : 'UNKNOWN'.tr(),
            ),
        ],
      ),
    );
  }

  /// A compact route line (`.hroute` HTML:222-223): dot + 13 px text. The
  /// overline is spoken, not shown — the list stays scannable.
  Widget _routeLine(
    BuildContext context, {
    required Color dot,
    required String label,
    required String text,
  }) {
    final TaarraaColors c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: Insets.s8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: '$label: $text',
              style: context.texts.body.copyWith(
                fontSize: 13,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, TaarraaColors c) {
    final TextStyle style = context.texts.caption.copyWith(
      color: c.textSecondary,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return Wrap(
      spacing: 14,
      runSpacing: Insets.s4,
      children: <Widget>[
        _metaItem(
          DsIcons.route,
          formatDistanceWithUnits(item.payment!.distance.toString(), context),
          style,
          c,
        ),
        _metaItem(
          DsIcons.clock,
          _isCompleted
              ? convertTimeString(item.payment!.duration.toString())
              : 'UNKNOWN'.tr(),
          style,
          c,
        ),
      ],
    );
  }

  Widget _metaItem(String icon, String text, TextStyle style, TaarraaColors c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TIcon(icon, size: TIconSize.sm, color: c.textSecondary),
        const SizedBox(width: Insets.s4),
        Text(text, style: style),
      ],
    );
  }
}

/// A loading placeholder shaped like [HistoryCardWidget] (`02 §11`).
class HistoryCardSkeleton extends StatelessWidget {
  const HistoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const TCard(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              TSkeleton(width: 44, height: 44, radius: Radii.full),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TSkeleton.line(width: 120),
                    SizedBox(height: Insets.s8),
                    TSkeleton(width: 160, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Insets.s12),
          TSkeleton(width: 84, height: 22, radius: Radii.full),
          SizedBox(height: Insets.s12),
          TSkeleton.box(height: 76, radius: Radii.md),
          SizedBox(height: Insets.s12),
          TSkeleton(width: 140, height: 12),
        ],
      ),
    );
  }
}
