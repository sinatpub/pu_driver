import 'package:flutter/material.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/wallet_presentation.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

/// The wallet's pieces (`03 S11`, `DD-04`), reworked by DD-43 around the
/// agreed model: one balance, the platform's commission rate as a note, a
/// warning when the driver owes commission (in the balance card since
/// DD-62), and transactions that say which way the money moved.
///
/// All presentational, and they **format nothing**: text arrives already
/// formatted by `wallet_presentation.dart`, where the money rules are tested.

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// The driver's balance, with the commission rate under it.
///
/// DD-62: when the driver owes commission, this one card says so — the
/// balance net of the debt ("−៛52") in warning amber on the warning tint,
/// why, and the way to pay. Amber, never red: owing commission after cash
/// trips is the normal state for these drivers, not an error (DD-04, DD-43).
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.label,
    required this.amount,
    this.note,
    this.owing = false,
    this.message,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  /// "Balance".
  final String label;

  /// Pre-formatted, e.g. "៛85,400", "$125.50", or "−៛52" when [owing].
  final String amount;

  /// "Platform commission: 10% of each trip" — omitted when the rate is not
  /// reported.
  final String? note;

  /// The driver owes the platform: the card turns amber and shows [message],
  /// [hint] and the action.
  final bool owing;

  /// "Unpaid commission from cash trips." Shown only when [owing].
  final String? message;

  /// What to do about it — DD-48's reward transfer, or DD-61's "Contact
  /// support to pay it." — shown with [actionLabel]. Only when [owing].
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final Color tone = owing ? c.warning : c.textPrimary;

    return TCard(
      variant: owing ? TCardVariant.tinted : TCardVariant.flat,
      tintFill: owing ? c.warningTint : null,
      tintBorder: owing ? c.warningGraphic : null,
      padding: const EdgeInsets.all(Insets.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // DD-61: one stop for a screen reader — "Balance, ៛85,400, Platform
          // commission…" — rather than three. The action stays out of it, so
          // it is still a button of its own.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        style: context.texts.caption
                            .copyWith(color: c.textSecondary),
                      ),
                    ),
                    // The glyph, not only the colour, says something is owed.
                    owing
                        ? TIcon(DsIcons.warn,
                            size: TIconSize.sm, color: c.warning)
                        : TIcon(DsIcons.wallet,
                            size: TIconSize.sm, color: c.textSecondary),
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
                      color: tone,
                      fontFeatures: _tabular,
                    ),
                  ),
                ),
                if (note != null && note!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Insets.s4),
                  Text(
                    note!,
                    style:
                        context.texts.caption.copyWith(color: c.textSecondary),
                  ),
                ],
                if (owing &&
                    message != null &&
                    message!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Insets.s12),
                  Text(
                    message!,
                    style: context.texts.caption.copyWith(color: c.warning),
                  ),
                ],
                if (owing && hint != null && hint!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Insets.s4),
                  Text(
                    hint!,
                    style: context.texts.caption.copyWith(
                      color: c.warning,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (owing && actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: Insets.s12),
            TButton(
              label: actionLabel!,
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

/// One wallet transaction: what it was, when, and the amount with its sign.
///
/// Money in is the success green with a "+"; money out is neutral with a
/// "−" — never red, which this app keeps for errors. The sign carries the
/// meaning, the colour only helps (`02 §1.4`). An unknown direction is
/// neutral and unsigned.
///
/// DD-61: a status that is not the routine one is a badge with a glyph, and
/// a pending amount is muted — it has not moved yet, so it must not look
/// like settled money.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.title,
    required this.amount,
    this.kind = WalletTxKind.unknown,
    this.direction = WalletTxDirection.unknown,
    this.time,
    this.status,
    this.statusKind = WalletTxStatus.other,
    this.semanticLabel,
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

  /// What [status] is, for the badge's tone and glyph.
  final WalletTxStatus statusKind;

  /// The whole row as one sentence for a screen reader — "Payment, money
  /// out ៛5, 20:15, Pending" — so the sign is spoken as a direction. Without
  /// it the row's texts are merged as they are.
  final String? semanticLabel;

  String get _icon => switch (kind) {
        WalletTxKind.tripEarning => DsIcons.car,
        WalletTxKind.commission => DsIcons.doc,
        WalletTxKind.referralReward ||
        WalletTxKind.rewardTransfer ||
        WalletTxKind.rideCredit =>
          DsIcons.gift,
        _ => DsIcons.wallet,
      };

  (TBadgeTone, String?) get _badge => switch (statusKind) {
        WalletTxStatus.pending => (TBadgeTone.warning, DsIcons.clock),
        WalletTxStatus.failed => (TBadgeTone.danger, DsIcons.warn),
        WalletTxStatus.cancelled => (TBadgeTone.neutral, DsIcons.close),
        WalletTxStatus.routine || WalletTxStatus.other => (
            TBadgeTone.neutral,
            null
          ),
      };

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool isIn = direction == WalletTxDirection.moneyIn;
    final bool pending = statusKind == WalletTxStatus.pending;
    final bool hasTime = time != null && time!.isNotEmpty;
    final bool hasStatus = status != null && status!.isNotEmpty;
    final (TBadgeTone tone, String? glyph) = _badge;

    final Widget card = TCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          TIcon(_icon, color: isIn ? c.success : c.textSecondary),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // The amount shares the title's line, so the line under it
                // has the row's full width for the time and the badge.
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySecondaryStrong
                            .copyWith(color: c.textPrimary),
                      ),
                    ),
                    const SizedBox(width: Insets.s12),
                    Text(
                      amount,
                      style: context.texts.bodySecondaryStrong.copyWith(
                        color: pending
                            ? c.textSecondary
                            : (isIn ? c.success : c.textPrimary),
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
                if (hasTime || hasStatus) ...<Widget>[
                  const SizedBox(height: 2),
                  // A badge that does not fit beside the time goes under it
                  // rather than clipping (narrow phones, large text).
                  Wrap(
                    spacing: Insets.s8,
                    runSpacing: Insets.s4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (hasTime)
                        Text(
                          time!,
                          maxLines: 1,
                          style: context.texts.caption.copyWith(
                            color: c.textSecondary,
                            fontFeatures: _tabular,
                          ),
                        ),
                      if (hasStatus)
                        TBadge(label: status!, tone: tone, icon: glyph),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return semanticLabel == null
        ? MergeSemantics(child: card)
        : Semantics(
            container: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: card,
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
