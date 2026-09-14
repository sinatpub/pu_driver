import 'package:dotted_line/dotted_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/passenger_row.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C6 — the payment receipt and total (`04 § B`, `03 S08`).
///
/// `ReceiptCard`: passenger, the real payment method from the payload (or no
/// badge at all — the old hardcoded "Unknown Payment" is gone, `DD-18`), the
/// trip facts, and the two addresses.
///
/// `TotalBox`: `bg.raised`, the caption "Total to collect" left, and the
/// server amount right in `TAmount.hero`. Neutral and tabular (`DD-04`). The
/// server `payment.amount` only, formatted exactly as before — no estimate
/// line (`DD-18`).
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    required this.passengerName,
    required this.distance,
    required this.duration,
    required this.dateTime,
    required this.startAddress,
    required this.endAddress,
    this.passengerImageUrl,
    this.method,
  });

  final String passengerName;
  final String? passengerImageUrl;

  /// `payment.paymentMethod` — shown only when present (`DD-18`).
  final String? method;

  /// Pre-formatted values (existing formatters), e.g. "3.50 km", "14:20".
  final String distance;
  final String duration;
  final String dateTime;
  final String startAddress;
  final String endAddress;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool hasMethod = method != null && method!.isNotEmpty;

    return TCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PassengerRow(
            name: passengerName,
            imageUrl: passengerImageUrl,
            trailing: hasMethod ? TBadge(label: method!) : null,
          ),
          _dashed(c),
          TKeyValueRow(label: 'DISTANCE'.tr(), value: distance),
          TKeyValueRow(label: 'DURATION'.tr(), value: duration),
          TKeyValueRow(label: 'DATE_TIME'.tr(), value: dateTime),
          _dashed(c),
          TAddressRow(
            kind: TAddressKind.pickup,
            overline: 'PICKUP'.tr(),
            primary: startAddress,
          ),
          TAddressRow(
            kind: TAddressKind.destination,
            overline: 'DESTINATION'.tr(),
            primary: endAddress,
          ),
        ],
      ),
    );
  }

  Widget _dashed(TaarraaColors c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.s12),
        child: DottedLine(
          direction: Axis.horizontal,
          lineThickness: 1,
          dashColor: c.borderDivider,
        ),
      );
}

/// "Total to collect" with the one figure that matters.
class TotalBox extends StatelessWidget {
  const TotalBox({super.key, required this.amount});

  /// Pre-formatted, e.g. "៛7,600" via `formatRielAmount`.
  final String amount;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      variant: TCardVariant.raised,
      padding: const EdgeInsets.all(Insets.s16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'TOTAL_TO_COLLECT'.tr(),
              style: context.texts.caption.copyWith(color: c.textSecondary),
            ),
          ),
          TAmount(text: amount, style: TAmountStyle.hero),
        ],
      ),
    );
  }
}
