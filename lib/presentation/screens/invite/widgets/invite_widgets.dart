import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

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
/// sheet. It opens the same screen as the wallet's [InviteEarnedCard].
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

/// What the invites have earned so far, on the wallet under the balance
/// (DD-47): big enough to read at a glance, and worded so it is not added to
/// the balance — the money is already in it.
class InviteEarnedCard extends StatelessWidget {
  const InviteEarnedCard({
    super.key,
    required this.label,
    required this.amount,
    required this.caption,
    required this.onTap,
  });

  /// "Invite rewards earned".
  final String label;

  /// "៛5,160".
  final String amount;

  /// "Already in your balance · 5 invited".
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Semantics(
      button: true,
      child: TCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(Insets.s16, 14, 10, 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      TIcon(DsIcons.gift,
                          size: TIconSize.sm, color: c.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          style: context.texts.caption
                              .copyWith(color: c.textSecondary),
                        ),
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
                  const SizedBox(height: 2),
                  Text(
                    caption,
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

/// Where the rewards came from: invited drivers, and invited passengers.
/// The total itself is on the wallet (DD-47).
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

  /// "Rewards are paid into your wallet balance."
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

/// One reward: who it came from, what they did, and the amount.
class RewardTile extends StatelessWidget {
  const RewardTile({
    super.key,
    required this.name,
    required this.caption,
    required this.amount,
    required this.fromDriver,
  });

  /// The invited person. Null renders an em dash.
  final String? name;

  /// "Top-up ៛100,000 · 09:14" or "Trip · 09:14".
  final String caption;

  /// "+៛1,000".
  final String amount;
  final bool fromDriver;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          TIcon(fromDriver ? DsIcons.car : DsIcons.users, color: c.success),
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
              color: c.success,
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
        TSkeleton.box(height: 96),
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
