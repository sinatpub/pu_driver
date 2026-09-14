import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign S2 — the wallet's balance card and transaction row
/// (`03 S11`, `04 § B`, `DD-21`, `DD-04`).
///
/// Both are presentational and **format nothing**: amounts arrive already
/// formatted by `formatWalletAmountWithSymbol`, so USD/riel rules stay in
/// `features/wallet/wallet_presentation.dart`, where they are tested.

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

enum WalletBalanceTone {
  /// The wallet balance — `success.tint`.
  wallet,

  /// The commission fare — `brand.tint`.
  commission,
}

/// One of the two balance tiles.
///
/// The label is the existing key only — the prototype's "Available to
/// withdraw" / "Owed to Taarraa" sub-labels assert meanings nobody has
/// confirmed, so there is no sub-label (`DD-21`).
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.label,
    required this.amount,
    required this.tone,
  });

  final String label;

  /// Pre-formatted, e.g. "125.50 $" or "7,600 ៛".
  final String amount;

  final WalletBalanceTone tone;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final (Color fill, Color accent) = switch (tone) {
      WalletBalanceTone.wallet => (c.successTint, c.success),
      WalletBalanceTone.commission => (c.brandTint, c.brandText),
    };

    return TCard(
      variant: TCardVariant.tinted,
      tintFill: fill,
      tintBorder: c.borderDivider,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: context.texts.label.copyWith(color: accent),
                ),
              ),
              const SizedBox(width: Insets.s8),
              TIcon(DsIcons.wallet, size: TIconSize.sm, color: accent),
            ],
          ),
          const SizedBox(height: Insets.s8),
          // A large balance in a half-width tile scales down rather than
          // breaking mid-number or ellipsising (seen at 320 px: "1,250,000.5"
          // / "0 \$").
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: context.texts.title.copyWith(
                color: c.textPrimary,
                fontFeatures: _tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One wallet transaction.
///
/// The icon and amount are neutral on purpose: whether a debit arrives as a
/// negative amount is unconfirmed, so no in/out colour or sign is derived
/// (`03 S11` implementation note, `DD-04`).
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.typeName,
    required this.amount,
    this.date,
    this.status,
  });

  /// Null renders an em dash, as before.
  final String? typeName;

  /// Pre-formatted by `formatWalletAmountWithSymbol`.
  final String amount;

  /// Pre-formatted by `formatTransactionDate`; omitted when null.
  final String? date;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final String caption = <String>[
      if (date != null && date!.isNotEmpty) date!,
      if (status != null && status!.isNotEmpty) status!,
    ].join(' · ');

    return TCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          TIcon(DsIcons.wallet, color: c.textSecondary),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  typeName ?? '—',
                  style: context.texts.bodyStrong
                      .copyWith(fontSize: 14, color: c.textPrimary),
                ),
                if (caption.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: context.texts.caption.copyWith(
                      color: c.textSecondary,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Insets.s12),
          Text(
            amount,
            style: context.texts.bodyStrong.copyWith(
              fontSize: 14,
              color: c.textPrimary,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder for the whole tab: two balance tiles and a few rows.
class WalletSkeleton extends StatelessWidget {
  const WalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: TSkeleton.box(height: 88)),
            SizedBox(width: 10),
            Expanded(child: TSkeleton.box(height: 88)),
          ],
        ),
        SizedBox(height: Insets.s24),
        TSkeleton.line(width: 96),
        SizedBox(height: Insets.s12),
        TSkeleton.box(height: 64, radius: 14),
        SizedBox(height: Insets.s8),
        TSkeleton.box(height: 64, radius: 14),
        SizedBox(height: Insets.s8),
        TSkeleton.box(height: 64, radius: 14),
      ],
    );
  }
}
