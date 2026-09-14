import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C4 — the live in-trip meter that replaced the old
/// `ShowDistandWidget` at the head of the trip sheet.
///
/// Three read-outs — time, distance, estimated fare — separated by vertical
/// rules (`docs/ux-redesign/04-component-specification.md § B`). The fare is
/// prefixed "≈" and carries the [EST_NOTE] line, because only the server
/// confirms the final fare after drop-off (`DD-14`).
///
/// The strip is driven entirely by *already formatted strings*: the screen
/// computes them with the exact expressions the old top-of-map strip was
/// fed, so the meter cannot silently disagree with the fare-distance logic
/// (`DD-14`).
class TripMeterStrip extends StatelessWidget {
  const TripMeterStrip({
    super.key,
    required this.duration,
    required this.distance,
    required this.fare,
  });

  final String duration;
  final String distance;
  final String fare;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final TextStyle valueStyle = context.texts.numericLg.copyWith(fontSize: 19);
    final TextStyle labelStyle =
        context.texts.caption.copyWith(color: c.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s12,
        vertical: Insets.s8,
      ),
      decoration: BoxDecoration(
        color: c.stageOnTripTint,
        borderRadius: Radii.controlRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _MeterCell(
                  label: "DURATION".tr(),
                  value: duration,
                  valueStyle: valueStyle,
                  labelStyle: labelStyle,
                ),
                _MeterRule(color: c.borderDivider),
                _MeterCell(
                  label: "DISTANCE".tr(),
                  value: distance,
                  valueStyle: valueStyle,
                  labelStyle: labelStyle,
                ),
                _MeterRule(color: c.borderDivider),
                _MeterCell(
                  label: "EST_FARE".tr(),
                  value: '≈ ៛$fare',
                  valueStyle: valueStyle,
                  labelStyle: labelStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child:
                    TIcon(DsIcons.info, size: TIconSize.sm, color: c.warning),
              ),
              const SizedBox(width: Insets.s4),
              Flexible(
                child: Text(
                  "EST_NOTE".tr(),
                  textAlign: TextAlign.center,
                  style: context.texts.caption.copyWith(color: c.warning),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeterCell extends StatelessWidget {
  const _MeterCell({
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.labelStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        // Keeps a scaled-down figure off the vertical rules.
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // P2 (KM at text scale 1.3): a third-width cell broke "00:12:40" and
            // "≈ ៛7,600" mid-figure. The value scales down on one line instead —
            // never wrapped, never ellipsised, the string itself untouched.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: valueStyle,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _MeterRule extends StatelessWidget {
  const _MeterRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: color,
      indent: 4,
      endIndent: 4,
    );
  }
}
