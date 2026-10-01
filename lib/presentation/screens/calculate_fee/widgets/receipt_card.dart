import 'package:dotted_line/dotted_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/helper/address_parts.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/passenger_row.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/trip_timeline.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C6, reworked by DD-39 — the payment screen's pieces.
///
/// The screen reads top to bottom as the driver acts: the trip is complete
/// ([PaymentHeader]), here is what to collect and how ([PaymentHero]), and
/// the trip it was for ([PaymentRoute]). Every figure is the server's
/// `payment` — the amount only, no estimate line (`DD-18`).

/// How the passenger pays, from `payment.paymentMethod` (`DD-39`). Matched
/// loosely — the server's exact strings are unconfirmed; mock mode sends
/// "Cash", "Wallet" and "Card". Anything else is [unknown], which keeps the
/// wording the screen had before.
enum PaymentKind {
  cash,
  wallet,
  card,
  unknown;

  static PaymentKind of(String? method) {
    final String m = method?.trim().toLowerCase() ?? '';
    if (m.contains('cash')) return PaymentKind.cash;
    if (m.contains('wallet')) return PaymentKind.wallet;
    if (m.contains('card')) return PaymentKind.card;
    return PaymentKind.unknown;
  }

  /// Paid in the app already: there is nothing to take from the passenger.
  bool get paidInApp => this == PaymentKind.wallet || this == PaymentKind.card;

  /// Over the amount: "Collect in cash", "Paid by wallet".
  String get heroLabel => switch (this) {
        PaymentKind.cash => 'COLLECT_IN_CASH'.tr(),
        PaymentKind.wallet => 'PAID_BY_WALLET'.tr(),
        PaymentKind.card => 'PAID_BY_CARD'.tr(),
        PaymentKind.unknown => 'TOTAL_TO_COLLECT'.tr(),
      };

  /// The method badge, translated when known; the server's text otherwise.
  String badge(String method) => switch (this) {
        PaymentKind.cash => 'PAY_CASH'.tr(),
        PaymentKind.wallet => 'PAY_WALLET'.tr(),
        PaymentKind.card => 'PAY_CARD'.tr(),
        PaymentKind.unknown => method,
      };

  /// Above the button, e.g. "Take ៛9,100 in cash, then confirm."
  String hint(String amount) => switch (this) {
        PaymentKind.cash => 'COLLECT_CASH_HINT'.tr(args: <String>[amount]),
        PaymentKind.wallet || PaymentKind.card => 'PAID_IN_APP_HINT'.tr(),
        PaymentKind.unknown => 'COLLECT_HINT'.tr(),
      };

  /// The button: "Cash received", "Finish trip", or the old "Payment done".
  String get action => switch (this) {
        PaymentKind.cash => 'CASH_RECEIVED'.tr(),
        PaymentKind.wallet || PaymentKind.card => 'FINISH_TRIP'.tr(),
        PaymentKind.unknown => 'PAYMENT_DONE'.tr(),
      };
}

/// "✓ Trip complete · #code" over the four steps, all done — where the trip
/// sheet's header left off (`DD-36`–`DD-39`).
class PaymentHeader extends StatelessWidget {
  const PaymentHeader({super.key, required this.bookingCode});

  final String bookingCode;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Row(
            children: <Widget>[
              TIcon(DsIcons.check, size: TIconSize.sm, color: c.success),
              const SizedBox(width: Insets.s8),
              Expanded(
                child: Text(
                  'TRIP_COMPLETE'.tr(),
                  style: context.texts.bodyStrong.copyWith(color: c.success),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Insets.s8),
              Text(
                '#$bookingCode',
                style: context.texts.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.s8),
        TripProgressBar(processType: 6, currentColor: c.success),
      ],
    );
  }
}

/// What to collect and how: the method's wording, the server amount as the
/// one hero figure, and the trip's facts as three tiles.
class PaymentHero extends StatelessWidget {
  const PaymentHero({
    super.key,
    required this.method,
    required this.amount,
    required this.distance,
    required this.duration,
    required this.time,
    this.label,
  });

  /// Replaces the method's instruction ("Collect in cash") over the amount,
  /// and drops the "Nothing to collect" line — for the history detail
  /// (`DD-42`), where the trip is long paid and the amount is just a figure.
  final String? label;

  /// `payment.paymentMethod` — the badge shows only when present (`DD-18`).
  final String? method;

  /// Pre-formatted, e.g. "៛9,100" via `formatRielAmount`.
  final String amount;

  /// Pre-formatted: "3.1 km", "8:24", "17:36".
  final String distance;
  final String duration;
  final String time;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final PaymentKind kind = PaymentKind.of(method);
    final bool hasMethod = method != null && method!.trim().isNotEmpty;

    return TCard(
      padding: const EdgeInsets.all(Insets.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label ?? kind.heroLabel,
                  style: context.texts.caption.copyWith(color: c.textSecondary),
                ),
              ),
              if (hasMethod) TBadge(label: kind.badge(method!)),
            ],
          ),
          const SizedBox(height: Insets.s4),
          Align(
            alignment: Alignment.centerLeft,
            child: TAmount(text: amount, style: TAmountStyle.hero),
          ),
          if (kind.paidInApp && label == null)
            Text(
              'NOTHING_TO_COLLECT'.tr(),
              style: context.texts.caption.copyWith(color: c.success),
            ),
          const SizedBox(height: Insets.s12),
          _TripFacts(
            facts: <(String, String)>[
              ('DISTANCE'.tr(), distance),
              ('DURATION'.tr(), duration),
              ('TIME'.tr(), time),
            ],
          ),
        ],
      ),
    );
  }
}

/// The trip the payment is for: both addresses split into place and area,
/// as on the trip sheet, then the passenger. No call button — the trip is
/// over.
class PaymentRoute extends StatelessWidget {
  const PaymentRoute({
    super.key,
    required this.passengerName,
    required this.startAddress,
    required this.endAddress,
    this.passengerImageUrl,
    this.passengerCaption,
  });

  final String passengerName;
  final String? passengerImageUrl;

  /// A line under the passenger's name — the history detail's invoice
  /// number (`DD-42`).
  final String? passengerCaption;
  final String startAddress;
  final String endAddress;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final (String startPlace, String? startArea) = splitAddress(startAddress);
    final (String endPlace, String? endArea) = splitAddress(endAddress);

    return TCard(
      padding: const EdgeInsets.fromLTRB(
          Insets.s16, Insets.s8, Insets.s16, Insets.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TAddressRow(
            kind: TAddressKind.pickup,
            overline: 'PICKUP'.tr(),
            primary: startPlace,
            secondary: startArea,
          ),
          if (endAddress.trim().isNotEmpty)
            TAddressRow(
              kind: TAddressKind.destination,
              overline: 'DESTINATION'.tr(),
              primary: endPlace,
              secondary: endArea,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.s8),
            child: DottedLine(
              direction: Axis.horizontal,
              lineThickness: 1,
              dashColor: c.borderDivider,
            ),
          ),
          PassengerRow(
            name: passengerName,
            phoneLabel: passengerCaption,
            imageUrl: passengerImageUrl,
            dense: true,
          ),
        ],
      ),
    );
  }
}

/// The trip's facts as three tiles side by side — or, when a tile would be
/// too narrow for its figure (a small phone, a large text setting), as
/// labelled rows, so no figure is ever cut to "…".
class _TripFacts extends StatelessWidget {
  const _TripFacts({required this.facts});

  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    // Roughly the width "1:08:24" or "13.1 km" needs, at this text size.
    final double minTile = MediaQuery.textScalerOf(context).scale(96);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tile =
            (constraints.maxWidth - Insets.s8 * (facts.length - 1)) /
                facts.length;
        if (tile < minTile) {
          return Column(
            children: <Widget>[
              for (final (String label, String value) in facts)
                TKeyValueRow(label: label, value: value),
            ],
          );
        }
        return Row(
          children: <Widget>[
            for (int i = 0; i < facts.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: Insets.s8),
              Expanded(
                child: _FactTile(label: facts[i].$1, value: facts[i].$2),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s8,
        vertical: Insets.s8,
      ),
      decoration: BoxDecoration(
        color: c.bgPage,
        borderRadius: Radii.controlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: context.texts.micro.copyWith(color: c.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.texts.bodyStrong.copyWith(color: c.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
