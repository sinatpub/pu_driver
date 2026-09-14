import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds_icons.dart';

/// UX-redesign F2 — surfaces and status labels (`02 §9`, `§13`).

enum TCardVariant {
  /// White, hairline border, no shadow — the default for a card on the page.
  flat,

  /// A slightly recessed fill, for a card sitting on white.
  raised,

  /// Tinted fill with a matching border (the wallet's balance cards).
  tinted,
}

class TCard extends StatelessWidget {
  const TCard({
    super.key,
    required this.child,
    this.variant = TCardVariant.flat,
    this.padding = const EdgeInsets.all(Insets.s16),
    this.tintFill,
    this.tintBorder,
    this.onTap,
    this.floating = false,
  });

  final Widget child;
  final TCardVariant variant;
  final EdgeInsetsGeometry padding;

  /// Required when [variant] is [TCardVariant.tinted].
  final Color? tintFill;
  final Color? tintBorder;

  final VoidCallback? onTap;

  /// Adds [Elevations.float] — for cards that genuinely sit over the map.
  /// Everything else separates with a border, because shadow-heavy UI over a
  /// light map turns to mud.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    final Color fill = switch (variant) {
      TCardVariant.flat => floating ? c.bgFloating : c.bgSurface,
      TCardVariant.raised => c.bgRaised,
      TCardVariant.tinted => tintFill ?? c.bgSurface,
    };
    final Color border = switch (variant) {
      TCardVariant.flat => c.borderDivider,
      TCardVariant.raised => c.borderDivider,
      TCardVariant.tinted => tintBorder ?? c.borderDivider,
    };

    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: Radii.cardRadius,
        border: Border.all(color: border),
        boxShadow: floating ? Elevations.float : Elevations.flat,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardRadius,
        child: content,
      ),
    );
  }
}

/// Badge tones.
///
/// Tones whose tint pair was measured (`02 §1.2`) render as a tint; the rest
/// render as an outline on white, which is also measured. No tone invents an
/// unverified colour pair.
enum TBadgeTone { success, warning, brand, danger, info, neutral }

class TBadge extends StatelessWidget {
  const TBadge({
    super.key,
    required this.label,
    this.tone = TBadgeTone.neutral,
    this.icon,
  });

  final String label;
  final TBadgeTone tone;

  /// Status badges should carry a glyph as well as a colour — colour is never
  /// the only signal (`02 §1.4`).
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    final (Color fill, Color content, Color? border) = switch (tone) {
      TBadgeTone.success => (c.successTint, c.success, null),
      TBadgeTone.warning => (c.warningTint, c.warning, null),
      TBadgeTone.brand => (c.brandTint, c.brandText, null),
      TBadgeTone.danger => (c.bgSurface, c.danger, c.danger),
      TBadgeTone.info => (c.bgSurface, c.info, c.info),
      TBadgeTone.neutral => (c.bgSurface, c.textSecondary, c.borderControl),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.full),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            TIcon(icon!, size: TIconSize.sm, color: content),
            const SizedBox(width: 5),
          ],
          Text(label, style: context.texts.micro.copyWith(color: content)),
        ],
      ),
    );
  }
}
