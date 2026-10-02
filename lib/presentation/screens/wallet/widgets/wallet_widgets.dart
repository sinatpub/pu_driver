import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/wallet/wallet_presentation.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// The wallet's pieces (`03 S11`, `DD-04`), reworked by DD-43 around the
/// agreed model: one balance, the platform's commission rate as a note, a
/// warning when the driver owes commission, and transactions that say which
/// way the money moved.
///
/// All presentational, and they **format nothing**: text arrives already
/// formatted by `wallet_presentation.dart`, where the money rules are tested.

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// The driver's balance, with the commission rate under it.
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.label,
    required this.amount,
    this.note,
  });

  /// "Balance".
  final String label;

  /// Pre-formatted, e.g. "៛85,400" or "$125.50".
  final String amount;

  /// "Platform commission: 10% of each trip" — omitted when the rate is not
  /// reported.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      padding: const EdgeInsets.all(Insets.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: context.texts.caption.copyWith(color: c.textSecondary),
                ),
              ),
              TIcon(DsIcons.wallet, size: TIconSize.sm, color: c.textSecondary),
            ],
          ),
          const SizedBox(height: Insets.s4),
          // A large balance scales down rather than breaking mid-number.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: context.texts.display.copyWith(
                color: c.textPrimary,
                fontFeatures: _tabular,
              ),
            ),
          ),
          if (note != null && note!.isNotEmpty) ...<Widget>[
            const SizedBox(height: Insets.s4),
            Text(
              note!,
              style: context.texts.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown only when the driver owes the platform: how much, and why.
class WalletDebtCard extends StatelessWidget {
  const WalletDebtCard({super.key, required this.title, required this.message});

  /// "You owe ៛5,000".
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      variant: TCardVariant.tinted,
      tintFill: c.warningTint,
      tintBorder: c.warningGraphic,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: TIcon(DsIcons.warn, size: TIconSize.sm, color: c.warning),
          ),
          const SizedBox(width: Insets.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: context.texts.bodyStrong.copyWith(
                    color: c.warning,
                    fontFeatures: _tabular,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: context.texts.caption.copyWith(color: c.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One wallet transaction: what it was, when, and the amount with its sign.
///
/// Money in is the success green with a "+"; money out is neutral with a
/// "−" — never red, which this app keeps for errors. The sign carries the
/// meaning, the colour only helps (`02 §1.4`). An unknown direction is
/// neutral and unsigned.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.title,
    required this.amount,
    this.kind = WalletTxKind.unknown,
    this.direction = WalletTxDirection.unknown,
    this.time,
    this.status,
  });

  /// The kind's translated name, or the backend's text for an unknown kind.
  /// Null renders an em dash.
  final String? title;

  /// Pre-formatted by `formatSignedWalletMoney`.
  final String amount;

  final WalletTxKind kind;
  final WalletTxDirection direction;

  /// "09:14"; omitted when null.
  final String? time;

  /// Shown only when it is not the routine one ("Pending", "Failed").
  final String? status;

  String get _icon => switch (kind) {
        WalletTxKind.tripEarning => DsIcons.car,
        WalletTxKind.commission => DsIcons.doc,
        WalletTxKind.referralReward => DsIcons.gift,
        _ => DsIcons.wallet,
      };

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool isIn = direction == WalletTxDirection.moneyIn;
    final String caption = <String>[
      if (time != null && time!.isNotEmpty) time!,
      if (status != null && status!.isNotEmpty) status!,
    ].join(' · ');

    return TCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          TIcon(_icon, color: isIn ? c.success : c.textSecondary),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyStrong
                      .copyWith(fontSize: 14, color: c.textPrimary),
                ),
                if (caption.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              color: isIn ? c.success : c.textPrimary,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder for the whole tab: the balance card and a few rows.
class WalletSkeleton extends StatelessWidget {
  const WalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TSkeleton.box(height: 112),
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
