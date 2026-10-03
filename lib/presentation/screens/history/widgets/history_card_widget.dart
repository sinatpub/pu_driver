import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/app/funtion_convert.dart';
import 'package:pu_taxi_driver/core/contracts/booking_status.dart';
import 'package:pu_taxi_driver/core/helper/address_parts.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/core/utils/clock_format.dart';
import 'package:pu_taxi_driver/core/utils/distance_format.dart';
import 'package:pu_taxi_driver/presentation/screens/calculate_fee/widgets/receipt_card.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/models/history_driver_info_model.dart';
import 'package:pu_taxi_driver/presentation/screens/history/widgets/history_days.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';
import 'package:pu_taxi_driver/routes/app_routes.dart';
import 'package:pu_taxi_driver/routes/route_arguments.dart';

/// One trip in the riding-history list.
///
/// DD-41 (after DD-40's compact card read as thin): three clear tiers. The
/// time in bold with the payment method and the amount; the pickup and
/// destination by place name in semi-bold, joined by a line between their
/// markers; then, under a divider, the passenger and invoice with the
/// distance and duration. The day is in the list's header.
///
/// A trip that is not completed shows its status instead of an amount, and
/// no route or figures — the old card printed "Unknown", ៛0 and 0 km there.
///
/// The tap is unchanged (`DD-19`): the whole card, same route, same
/// [MapHistoryDetailArgs], and only when [canOpenDetail] is true (the
/// completed tab). A chevron says so.
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
    final DateTime? at = historyDate(item);
    final String? method = item.payment!.paymentMethod;
    final bool hasMethod = method != null && method.trim().isNotEmpty;
    final bool hasDestination =
        item.endAddress != null && item.endAddress.toString().trim().isNotEmpty;

    return TCard(
      padding: const EdgeInsets.all(14),
      onTap: canOpenDetail ? () => _openDetail(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (at != null) ...<Widget>[
                Text(
                  historyTime(at),
                  style: context.texts.bodyStrong.copyWith(
                    color: c.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: Insets.s8),
              ],
              // Takes the room between the time and the amount. On a narrow
              // screen with large text the badge scales down to fit rather
              // than overflowing.
              Expanded(
                child: _isCompleted && hasMethod
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: TBadge(
                            label: PaymentKind.of(method).badge(method),
                            tone: TBadgeTone.neutral,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: Insets.s8),
              if (_isCompleted)
                Text(
                  '៛${formatRielAmount(item.payment!.amount.toString())}',
                  style: context.texts.subtitle.copyWith(
                    color: c.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                )
              else
                TBadge(
                  label: item.statusName.toString().toUpperCase().tr(),
                  tone: TBadgeTone.danger,
                  icon: DsIcons.close,
                ),
            ],
          ),
          if (_isCompleted) ...<Widget>[
            const SizedBox(height: Insets.s12),
            _routeLine(
              context,
              isPickup: true,
              label: 'PICKUP'.tr(),
              address: item.startAddress.toString(),
            ),
            if (hasDestination) ...<Widget>[
              // The line between the two markers, centred under them.
              Padding(
                padding: const EdgeInsets.only(left: 4.25),
                child:
                    Container(width: 1.5, height: 10, color: c.borderControl),
              ),
              _routeLine(
                context,
                isPickup: false,
                label: 'DESTINATION'.tr(),
                address: item.endAddress.toString(),
              ),
            ],
          ],
          const SizedBox(height: Insets.s12),
          Divider(height: 1, thickness: 1, color: c.borderDivider),
          const SizedBox(height: Insets.s8),
          _footer(context, c),
        ],
      ),
    );
  }

  /// Who, and — for a completed trip — how far and how long.
  ///
  /// On one line when the passenger's name keeps at least [_minNameWidth]
  /// beside the figures; otherwise the figures go on a line of their own, so
  /// a narrow screen or a large text setting never squeezes the name to
  /// nothing or overflows.
  Widget _footer(BuildContext context, TaarraaColors c) {
    const double avatar = 24;
    final TextStyle figureStyle = context.texts.caption.copyWith(
      color: c.textSecondary,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final String? figures = _isCompleted ? _figures().join(' · ') : null;

    final Widget who = Text(
      '${item.passenger!.name} · #${item.payment!.invoiceId}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.texts.bodySecondary.copyWith(color: c.textPrimary),
    );
    final Widget face = TAvatar(
      name: item.passenger!.name.toString(),
      imageUrl: item.passenger!.profileImage,
      size: avatar,
    );
    final List<Widget> chevron = <Widget>[
      if (canOpenDetail) ...<Widget>[
        const SizedBox(width: Insets.s4),
        TIcon(DsIcons.chevron, size: TIconSize.sm, color: c.textSecondary),
      ],
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        bool oneLine = true;
        if (figures != null) {
          final TextPainter painter = TextPainter(
            text: TextSpan(text: figures, style: figureStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final double taken = avatar +
              Insets.s8 * 2 +
              painter.width +
              (canOpenDetail ? Insets.s4 + TIconSize.sm.value : 0);
          painter.dispose();
          oneLine = constraints.maxWidth - taken >= _minNameWidth;
        }

        if (oneLine) {
          return Row(
            children: <Widget>[
              face,
              const SizedBox(width: Insets.s8),
              Expanded(child: who),
              if (figures != null) ...<Widget>[
                const SizedBox(width: Insets.s8),
                Text(figures, style: figureStyle),
              ],
              ...chevron,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                face,
                const SizedBox(width: Insets.s8),
                Expanded(child: who),
                ...chevron,
              ],
            ),
            const SizedBox(height: Insets.s4),
            Padding(
              padding: const EdgeInsets.only(left: avatar + Insets.s8),
              child: Text(
                figures!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: figureStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  static const double _minNameWidth = 96;

  /// "3.5 km", "14:00" — the trip screens' formats (DD-38, DD-39). Server
  /// text that does not parse is shown as given.
  List<String> _figures() {
    final String durationText = item.payment!.duration.toString();
    final Duration? duration = parseDurationText(durationText);
    return <String>[
      formatDistanceText(item.payment!.distance.toString()),
      duration == null ? durationText : formatClock(duration),
    ];
  }

  void _openDetail(BuildContext context) {
    final List<String> figures = _figures();
    Get.toNamed(
      AppRoutes.mapHistoryDetail,
      arguments: MapHistoryDetailArgs(
        cost: formatRielAmount(item.payment!.amount.toString()),
        distand: figures[0],
        duration: figures[1],
        typeVehicleId: item.driver!.vehicle!.typeVehicleId!,
        latEnd: double.parse(item.endLatitude.toString()),
        latStart: double.parse(item.startLatitude.toString()),
        lngEnd: double.parse(item.endLongitude.toString()),
        lngStart: double.parse(item.startLongitude.toString()),
        // DD-42: the rest of the trip.
        invoiceId: item.payment!.invoiceId?.toString(),
        passengerName: item.passenger?.name,
        passengerImage: item.passenger?.profileImage,
        passengerPhone: item.passenger?.phone,
        startAddress: item.startAddress?.toString(),
        endAddress: item.endAddress?.toString(),
        paymentMethod: item.payment!.paymentMethod,
        tripTime: historyDate(item),
        endedAt: historyEndedAt(item),
      ),
    );
  }

  /// One route line: a marker and the place name (the part of the address
  /// before the area), on one line. The full address is what is spoken.
  Widget _routeLine(
    BuildContext context, {
    required bool isPickup,
    required String label,
    required String address,
  }) {
    final TaarraaColors c = context.colors;
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isPickup ? c.brandIdentity : c.textPrimary,
            borderRadius: BorderRadius.circular(isPickup ? Radii.full : 2.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            splitAddress(address).$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            semanticsLabel: '$label: $address',
            style: context.texts.body
                .withWeight(FontWeight.w600)
                .copyWith(color: c.textPrimary),
          ),
        ),
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
              TSkeleton(width: 56, height: 18),
              SizedBox(width: Insets.s8),
              TSkeleton(width: 52, height: 22, radius: Radii.full),
              Spacer(),
              TSkeleton(width: 72, height: 18),
            ],
          ),
          SizedBox(height: Insets.s16),
          TSkeleton(width: 220, height: 14),
          SizedBox(height: Insets.s12),
          TSkeleton(width: 180, height: 14),
          SizedBox(height: Insets.s16),
          Row(
            children: <Widget>[
              TSkeleton(width: 24, height: 24, radius: Radii.full),
              SizedBox(width: Insets.s8),
              TSkeleton(width: 120, height: 12),
              Spacer(),
              TSkeleton(width: 80, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}
