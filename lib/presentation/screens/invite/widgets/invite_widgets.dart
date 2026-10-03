import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

/// The pieces of the invite and rewards screens (DD-45).
///
/// All presentational, and they **format nothing**: every string arrives
/// translated and every amount arrives formatted, so they can be pumped in a
/// test without GetX or a locale.

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

const String _logo = 'assets/launcher/launcher_driver_1024.png';

/// The round QR button that floats over the home map.
///
/// The brand fill, not the white of the status card under it: it is the one
/// thing on the map the driver is meant to press.
class InviteFab extends StatelessWidget {
  const InviteFab({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String semanticLabel;
  final VoidCallback onPressed;

  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.actionPrimary,
          shape: BoxShape.circle,
          boxShadow: Elevations.float,
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: TIcon(
                DsIcons.qr,
                size: TIconSize.lg,
                color: c.textOnAction,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The QR and the code under it.
///
/// The QR is always black on white, in both themes — a scanner needs the
/// contrast, and a tinted QR is one that sometimes does not scan.
class InviteQrCard extends StatelessWidget {
  const InviteQrCard({
    super.key,
    required this.data,
    required this.code,
    required this.codeLabel,
    required this.copyLabel,
    required this.qrLabel,
    required this.onCopy,
    this.qrSize = 184,
  });

  /// What the QR encodes (the invite link).
  final String data;

  /// "PU7K2M".
  final String code;

  /// "Invite code".
  final String codeLabel;

  /// "Copy code" — for the screen reader.
  final String copyLabel;

  /// "Invite QR code" — for the screen reader.
  final String qrLabel;
  final VoidCallback onCopy;
  final double qrSize;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      padding: const EdgeInsets.fromLTRB(Insets.s16, Insets.s20, Insets.s16, 6),
      child: Column(
        children: <Widget>[
          Semantics(
            image: true,
            label: qrLabel,
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.all(Insets.s8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  QrImageView(
                    data: data,
                    size: qrSize,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    // High: the mark in the middle covers some modules.
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        _logo,
                        width: 36,
                        height: 36,
                        cacheWidth: 108,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 36, height: 36),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.s12),
          Divider(height: 1, thickness: 1, color: c.borderDivider),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 6),
                    Text(
                      codeLabel,
                      style: context.texts.caption
                          .copyWith(color: c.textSecondary),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        code,
                        maxLines: 1,
                        style: context.texts.title.copyWith(
                          color: c.textPrimary,
                          letterSpacing: 3,
                          fontFeatures: _tabular,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              TIconButton(
                icon: DsIcons.copy,
                semanticLabel: copyLabel,
                filled: false,
                onPressed: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What an invite earns: one line per kind of invited person.
class InviteRules extends StatelessWidget {
  const InviteRules({
    super.key,
    required this.driverRule,
    required this.passengerRule,
  });

  /// "A driver joins: you get 1% of each top-up". Null hides the line.
  final String? driverRule;
  final String? passengerRule;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    Widget line(String icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: TIcon(icon, size: TIconSize.sm, color: c.brandText),
            ),
            const SizedBox(width: Insets.s8),
            Expanded(
              child: Text(
                text,
                style: context.texts.bodySecondary
                    .copyWith(color: c.textPrimary, fontFeatures: _tabular),
              ),
            ),
          ],
        );

    final List<Widget> lines = <Widget>[
      if (driverRule != null) line(DsIcons.car, driverRule!),
      if (passengerRule != null) line(DsIcons.users, passengerRule!),
    ];
    if (lines.isEmpty) return const SizedBox.shrink();

    return TCard(
      variant: TCardVariant.tinted,
      tintFill: c.brandTint,
      tintBorder: c.brandTint,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < lines.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: Insets.s8),
            lines[i],
          ],
        ],
      ),
    );
  }
}

/// What the invites have earned, in one tappable line at the foot of the QR
/// sheet. It opens the same screen as the wallet's [RewardBalanceCard].
class InviteSummaryCard extends StatelessWidget {
  const InviteSummaryCard({
    super.key,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  /// "Invite rewards".
  final String title;

  /// "៛5,160 earned · 5 invited".
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Semantics(
      button: true,
      child: TCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: <Widget>[
            TIcon(DsIcons.gift, color: c.brandText),
            const SizedBox(width: Insets.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: context.texts.bodyStrong
                        .copyWith(fontSize: 15, color: c.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    style: context.texts.caption.copyWith(
                      color: c.textSecondary,
                      fontFeatures: _tabular,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Insets.s8),
            TIcon(DsIcons.chevron, size: TIconSize.sm, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// The reward balance and the button that opens the transfer sheet (DD-48,
/// DD-49). On the wallet, under the balance, where the whole card also opens
/// the rewards screen; and at the top of the rewards screen, with the totals.
///
/// Rewards are a pot of their own: money here pays no commission until it is
/// transferred, and the caption says so.
class RewardBalanceCard extends StatelessWidget {
  const RewardBalanceCard({
    super.key,
    required this.label,
    required this.amount,
    required this.transferLabel,
    required this.onTransfer,
    this.caption,
    this.transferring = false,
    this.onTap,
    this.figures = const <(String, String)>[],
  });

  /// "Invite rewards" on the wallet, "Reward balance" on the rewards screen.
  final String label;

  /// "៛5,160".
  final String amount;

  /// "Not in your balance yet · 5 invited".
  final String? caption;

  /// "Transfer to balance".
  final String transferLabel;

  /// Null hides the button: there is nothing to transfer.
  final VoidCallback? onTransfer;

  /// A transfer is out: the button shows a spinner and takes no tap.
  final bool transferring;

  /// Opens the rewards screen. Null on the rewards screen itself.
  final VoidCallback? onTap;

  /// Label and value rows under the button — "Total earned", "Transferred".
  final List<(String, String)> figures;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Semantics(
      button: onTap != null,
      child: TCard(
        onTap: onTap,
        padding: const EdgeInsets.all(Insets.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                TIcon(DsIcons.gift, size: TIconSize.sm, color: c.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style:
                        context.texts.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                if (onTap != null)
                  TIcon(
                    DsIcons.chevron,
                    size: TIconSize.sm,
                    color: c.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                maxLines: 1,
                style: context.texts.headline.copyWith(
                  color: c.success,
                  fontFeatures: _tabular,
                ),
              ),
            ),
            if (caption != null && caption!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                caption!,
                style: context.texts.caption.copyWith(
                  color: c.textSecondary,
                  fontFeatures: _tabular,
                ),
              ),
            ],
            if (onTransfer != null) ...<Widget>[
              const SizedBox(height: Insets.s12),
              TButton(
                label: transferLabel,
                variant: TButtonVariant.secondary,
                size: TButtonSize.small,
                loading: transferring,
                onPressed: onTransfer,
              ),
            ],
            if (figures.isNotEmpty) ...<Widget>[
              const SizedBox(height: Insets.s12),
              Divider(height: 1, thickness: 1, color: c.borderDivider),
              const SizedBox(height: Insets.s4),
              for (final (String name, String value) in figures)
                Padding(
                  padding: const EdgeInsets.only(top: Insets.s8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          name,
                          style: context.texts.bodySecondary
                              .copyWith(color: c.textSecondary),
                        ),
                      ),
                      const SizedBox(width: Insets.s8),
                      Text(
                        value,
                        style: context.texts.bodyStrong.copyWith(
                          fontSize: 14,
                          color: c.textPrimary,
                          fontFeatures: _tabular,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The transfer sheet (DD-49): the driver types how much of the reward
/// balance to move, sees where it goes, and confirms.
///
/// The field starts empty — the amount is the driver's to give — with "All"
/// to fill in the whole balance. The button stays off until the amount is one
/// that can be moved, and names it: "Transfer ៛2,000".
///
/// Presentational: the caller parses, checks and words everything.
class TransferAmountBody extends StatefulWidget {
  const TransferAmountBody({
    super.key,
    required this.availableText,
    required this.amountLabel,
    required this.symbol,
    required this.allLabel,
    required this.allValue,
    required this.wholeUnits,
    required this.parse,
    required this.errorFor,
    required this.linesFor,
    required this.confirmLabelFor,
    required this.warning,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  /// "Reward balance: ៛5,160".
  final String availableText;

  /// "Amount".
  final String amountLabel;

  /// "៛", shown inside the field before the digits.
  final String symbol;

  /// "All".
  final String allLabel;

  /// What "All" puts in the field — "5160".
  final String allValue;

  /// Riel: digits only. Otherwise two decimals are allowed.
  final bool wholeUnits;

  /// The typed text as an amount, or null when it is not one.
  final num? Function(String text) parse;

  /// Why [amount] cannot be moved — "You have ៛5,160 to transfer." — or null.
  final String? Function(num amount) errorFor;

  /// "Balance after: ៛87,400", "Rewards left: ៛3,160", and the debt line.
  final List<String> Function(num amount) linesFor;

  /// "Transfer ៛2,000", or "Transfer" with no amount yet.
  final String Function(num? amount) confirmLabelFor;

  /// "This cannot be moved back."
  final String warning;
  final String cancelLabel;
  final ValueChanged<num> onConfirm;
  final VoidCallback onCancel;

  @override
  State<TransferAmountBody> createState() => _TransferAmountBodyState();
}

class _TransferAmountBodyState extends State<TransferAmountBody> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fillAll() {
    _controller.value = TextEditingValue(
      text: widget.allValue,
      selection: TextSelection.collapsed(offset: widget.allValue.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final num? amount = widget.parse(_controller.text);
    final String? error = amount == null ? null : widget.errorFor(amount);
    final bool valid = amount != null && error == null;

    return Padding(
      // The sheet does not move for the keyboard by itself.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.availableText,
              style: context.texts.bodySecondary.copyWith(
                color: c.textSecondary,
                fontFeatures: _tabular,
              ),
            ),
            const SizedBox(height: Insets.s12),
            TTextField(
              label: widget.amountLabel,
              controller: _controller,
              hint: '0',
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !widget.wholeUnits,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                if (widget.wholeUnits)
                  FilteringTextInputFormatter.digitsOnly
                else
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                LengthLimitingTextInputFormatter(12),
              ],
              errorText: error,
              prefix: Text(
                widget.symbol,
                style: context.texts.bodyStrong.copyWith(color: c.textPrimary),
              ),
              suffix: TButton(
                label: widget.allLabel,
                variant: TButtonVariant.tertiary,
                size: TButtonSize.small,
                expand: false,
                onPressed: _fillAll,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Insets.s12),
            if (valid)
              for (final String line in widget.linesFor(amount)) ...<Widget>[
                Text(
                  line,
                  style: context.texts.body.copyWith(
                    color: c.textPrimary,
                    fontFeatures: _tabular,
                  ),
                ),
                const SizedBox(height: Insets.s4),
              ],
            Text(
              widget.warning,
              style:
                  context.texts.bodySecondary.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: Insets.s20),
            TButton(
              label: widget.confirmLabelFor(valid ? amount : null),
              onPressed: valid ? () => widget.onConfirm(amount) : null,
            ),
            const SizedBox(height: Insets.s4),
            TButton(
              label: widget.cancelLabel,
              variant: TButtonVariant.tertiary,
              onPressed: widget.onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the rewards came from: invited drivers, and invited passengers.
class RewardSplitCard extends StatelessWidget {
  const RewardSplitCard({
    super.key,
    required this.driversLabel,
    required this.driversAmount,
    required this.passengersLabel,
    required this.passengersAmount,
    this.note,
  });

  final String driversLabel;
  final String driversAmount;
  final String passengersLabel;
  final String passengersAmount;

  /// "Transfer rewards to your balance to use them."
  final String? note;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    Widget part(String icon, String caption, String value) => Row(
          children: <Widget>[
            TIcon(icon, size: TIconSize.sm, color: c.textSecondary),
            const SizedBox(width: Insets.s8),
            Expanded(
              child: Text(
                caption,
                style: context.texts.bodySecondary
                    .copyWith(color: c.textSecondary),
              ),
            ),
            const SizedBox(width: Insets.s8),
            Text(
              value,
              style: context.texts.bodyStrong.copyWith(
                fontSize: 14,
                color: c.success,
                fontFeatures: _tabular,
              ),
            ),
          ],
        );

    return TCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          part(DsIcons.car, driversLabel, driversAmount),
          const SizedBox(height: Insets.s8),
          part(DsIcons.users, passengersLabel, passengersAmount),
          if (note != null && note!.isNotEmpty) ...<Widget>[
            const SizedBox(height: Insets.s12),
            Divider(height: 1, thickness: 1, color: c.borderDivider),
            const SizedBox(height: Insets.s8),
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

/// One line of the reward history: a reward (who it came from, what they
/// did) or a transfer out to the wallet balance.
class RewardTile extends StatelessWidget {
  const RewardTile({
    super.key,
    required this.name,
    required this.caption,
    required this.amount,
    required this.icon,
    this.moneyIn = true,
  });

  /// The invited person, or "Transferred to balance". Null renders an em
  /// dash.
  final String? name;

  /// "Top-up ៛100,000 · 09:14" or "Trip · 09:14".
  final String caption;

  /// "+៛1,000", or "−៛5,160" for a transfer.
  final String amount;
  final String icon;

  /// False for a transfer: neutral, as money out is everywhere (DD-43).
  final bool moneyIn;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          TIcon(icon, color: moneyIn ? c.success : c.textSecondary),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name == null || name!.isEmpty ? '—' : name!,
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
              color: moneyIn ? c.success : c.textPrimary,
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// One invited person: who, what they are, when they joined, what they have
/// earned the driver.
class InviteeTile extends StatelessWidget {
  const InviteeTile({
    super.key,
    required this.name,
    required this.caption,
    required this.earned,
    this.imageUrl,
    this.hasEarned = true,
  });

  final String name;
  final String? imageUrl;

  /// "Driver · Joined 12 Sep".
  final String caption;

  /// "+៛3,500", or "No rewards yet".
  final String earned;

  /// False greys [earned] out: nothing has come from this person yet.
  final bool hasEarned;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          TAvatar(name: name, imageUrl: imageUrl, size: 40),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name.isEmpty ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyStrong
                      .copyWith(fontSize: 14, color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.s12),
          Flexible(
            flex: 0,
            child: Text(
              earned,
              textAlign: TextAlign.end,
              style: hasEarned
                  ? context.texts.bodyStrong.copyWith(
                      fontSize: 14,
                      color: c.success,
                      fontFeatures: _tabular,
                    )
                  : context.texts.caption.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A day header in the reward list, as in the wallet and riding history.
class InviteDayHeader extends StatelessWidget {
  const InviteDayHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Insets.s4, Insets.s8, Insets.s4, Insets.s8),
        child: Text(
          label,
          style:
              context.texts.label.copyWith(color: context.colors.textPrimary),
        ),
      ),
    );
  }
}

/// Loading placeholder for the QR sheet.
class MyQrSkeleton extends StatelessWidget {
  const MyQrSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TSkeleton.box(height: 280),
        SizedBox(height: Insets.s12),
        TSkeleton.box(height: 56, radius: 14),
        SizedBox(height: Insets.s12),
        TSkeleton.box(height: 64),
      ],
    );
  }
}

/// Loading placeholder for the rewards and people screens.
class InviteListSkeleton extends StatelessWidget {
  const InviteListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TSkeleton.box(height: 180),
        SizedBox(height: Insets.s24),
        TSkeleton.box(height: 64, radius: 14),
        SizedBox(height: Insets.s8),
        TSkeleton.box(height: 64, radius: 14),
        SizedBox(height: Insets.s8),
        TSkeleton.box(height: 64, radius: 14),
      ],
    );
  }
}
