import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';

/// UX-redesign F2 — the content primitives every screen composes from
/// (`02 §9`, `04 § A`): an avatar, the two row types, and a money value.

/// Circular avatar with an initials fallback.
///
/// Deliberately not built on `TImageWidget`: that falls back to a generic
/// "no image" SVG, and the redesign wants the person's initials, which read
/// better in a list and never look like a broken image.
class TAvatar extends StatelessWidget {
  const TAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// First letters of the first two words, e.g. "Sok Dara" → "SD".
  String get _initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final Widget fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: c.avatarFallbackBackground,
      child: Text(
        _initials,
        style: context.texts.bodyStrong.copyWith(
          color: c.avatarFallbackText,
          fontSize: size * 0.35,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl == null || imageUrl!.isEmpty
            ? fallback
            : Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? progress,
                ) {
                  if (progress == null) return child;
                  return fallback;
                },
              ),
      ),
    );
  }
}

/// Label on the left, value on the right — receipts, trip details, history.
class TKeyValueRow extends StatelessWidget {
  const TKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;

  /// Null renders an em dash: unknown is shown as unknown, never as zero.
  final String? value;

  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool known = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: context.texts.bodySecondary.copyWith(color: c.textSecondary),
          ),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Text(
              known ? value! : '—',
              textAlign: TextAlign.right,
              // Values wrap rather than truncate: a clipped amount or address
              // is worse than a taller row.
              style: context.texts.bodyStrong.copyWith(
                fontSize: 14,
                color: known ? (valueColor ?? c.textPrimary) : c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum TAddressKind { pickup, destination }

/// A pickup or destination line with its dot marker.
class TAddressRow extends StatelessWidget {
  const TAddressRow({
    super.key,
    required this.kind,
    required this.overline,
    required this.primary,
    this.secondary,
    this.focused = false,
    this.loading = false,
  });

  final TAddressKind kind;

  /// "Pickup" / "Destination".
  final String overline;

  /// The place name or address.
  final String primary;

  final String? secondary;

  /// The stage's focus gets the larger `title` style.
  final bool focused;

  /// True while the address is still being reverse-geocoded. Renders a
  /// placeholder bar; swaps to `TSkeleton` when F3 lands.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final Color dotColor =
        kind == TAddressKind.pickup ? c.brandIdentity : c.textSecondary;
    final Color haloColor =
        kind == TAddressKind.pickup ? c.brandTint : c.bgRaised;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: haloColor, width: 4),
            ),
          ),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  overline,
                  style: context.texts.micro.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 2),
                if (loading)
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: c.bgSunken,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  )
                else
                  Text(
                    primary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: (focused
                            ? context.texts.title
                            : context.texts.bodyStrong)
                        .copyWith(color: c.textPrimary),
                  ),
                if (secondary != null && secondary!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    secondary!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        context.texts.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum TAmountStyle {
  /// A row in a ledger or receipt.
  row,

  /// The one big figure on the screen — the amount to collect.
  hero,
}

/// A money figure.
///
/// **Formats nothing.** It takes an already-formatted string from the existing
/// helpers (`formatRielAmount`, `formatWalletAmountWithSymbol`), so there is
/// exactly one money-formatting implementation in the app and this widget
/// cannot quietly disagree with it.
class TAmount extends StatelessWidget {
  const TAmount({
    super.key,
    required this.text,
    this.style = TAmountStyle.row,
    this.isEstimate = false,
  });

  /// Null or empty renders an em dash — unknown, not zero.
  final String? text;

  final TAmountStyle style;

  /// Prefixes "≈". Client-side estimates must never be presented as the final
  /// fare (`DD-14`).
  final bool isEstimate;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool known = text != null && text!.isNotEmpty;
    final TextStyle base = switch (style) {
      TAmountStyle.row => context.texts.bodyStrong,
      TAmountStyle.hero => context.texts.display,
    };

    return Text(
      known ? (isEstimate ? '≈ ${text!}' : text!) : '—',
      // Money wraps, never ellipsises.
      softWrap: true,
      style: base.copyWith(color: known ? c.textPrimary : c.textSecondary),
    );
  }
}
