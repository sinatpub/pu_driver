import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds_icons.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_motion.dart';

/// UX-redesign F2 — buttons (`docs/ux-redesign/02-design-system.md §7`).
///
/// Replaces the ad-hoc `FBTNWidget` / `XButton` / bare `MaterialButton` mix as
/// screens migrate. Behaviour is the caller's: this widget only renders and
/// reports taps.
enum TButtonVariant {
  /// Accept, I've arrived, Drop off, Next, Submit.
  primary,

  /// Start ride, Payment done.
  success,

  /// Retry, Contact support, the neutral half of a dialog.
  secondary,

  /// The risky half of a dialog ("Yes, cancel"). **Outlined, never filled** —
  /// a filled crimson button beside a filled brand button is the hue collision
  /// `02 §0` exists to avoid.
  destructiveOutline,

  /// Inline text action (Resend code).
  tertiary,

  /// Inline text action that destroys something (Cancel request).
  tertiaryDanger,
}

enum TButtonSize {
  /// 56 — the primary CTA. Larger than the platform default on purpose: it is
  /// pressed one-handed, in a vehicle, often in motion.
  regular(Sizes.primaryButton),

  /// 48 — secondary actions. Never smaller; that is the touch-target floor.
  small(Sizes.touchTarget);

  const TButtonSize(this.height);

  final double height;
}

class TButton extends StatefulWidget {
  const TButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TButtonVariant.primary,
    this.size = TButtonSize.regular,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  final TButtonVariant variant;
  final TButtonSize size;

  /// Swaps the label for a spinner **without changing the button's width** —
  /// a button that resizes mid-press causes mis-taps.
  final bool loading;

  /// Optional leading icon, from [DsIcons].
  final String? icon;

  final bool expand;

  bool get _enabled => onPressed != null && !loading;

  @override
  State<TButton> createState() => _TButtonState();
}

class _TButtonState extends State<TButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool enabled = widget._enabled;
    final _ButtonStyle style = _styleFor(widget.variant, c, _pressed);

    final Color labelColor = enabled ? style.label : c.textDisabled;
    final TextStyle labelStyle = context.texts.bodyStrong.copyWith(
      color: labelColor,
      fontSize: widget.size == TButtonSize.small ? 14 : null,
    );

    final Widget content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.icon != null) ...<Widget>[
          TIcon(widget.icon!, size: TIconSize.sm, color: labelColor),
          const SizedBox(width: Insets.s8),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: labelStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed && !reduceMotion(context) ? 0.97 : 1,
          duration: Motion.press,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: Motion.press,
            width: widget.expand ? double.infinity : null,
            constraints: BoxConstraints(minHeight: widget.size.height),
            padding: const EdgeInsets.symmetric(horizontal: Insets.s16),
            decoration: BoxDecoration(
              color: enabled ? style.fill : c.bgSunken,
              gradient: enabled ? style.gradient : null,
              borderRadius: Radii.controlRadius,
              border: enabled && style.border != null
                  ? Border.all(color: style.border!, width: 1.5)
                  : null,
            ),
            child: Center(
              child: widget.loading
                  // The label stays in the tree at zero opacity so the button
                  // keeps its exact width while the spinner runs.
                  ? Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Opacity(opacity: 0, child: content),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(labelColor),
                          ),
                        ),
                      ],
                    )
                  : content,
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.label,
    this.fill,
    this.gradient,
    this.border,
  });

  final Color label;
  final Color? fill;
  final Gradient? gradient;
  final Color? border;
}

_ButtonStyle _styleFor(
  TButtonVariant variant,
  TaarraaColors c,
  bool pressed,
) {
  switch (variant) {
    case TButtonVariant.primary:
      return _ButtonStyle(
        label: c.textOnAction,
        fill: pressed ? c.actionPressed : null,
        gradient: pressed
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[c.actionHighlight, c.actionPrimary],
              ),
      );
    case TButtonVariant.success:
      return _ButtonStyle(label: c.textOnAction, fill: c.success);
    case TButtonVariant.secondary:
      return _ButtonStyle(
        label: c.textPrimary,
        fill: pressed ? c.bgRaised : c.bgSurface,
        border: c.borderControl,
      );
    case TButtonVariant.destructiveOutline:
      return _ButtonStyle(
        label: c.danger,
        fill: c.bgSurface,
        border: c.danger,
      );
    case TButtonVariant.tertiary:
      return _ButtonStyle(label: c.brandText);
    case TButtonVariant.tertiaryDanger:
      return _ButtonStyle(label: c.danger);
  }
}

/// Icon-only action: menu, back, bell, refresh, call.
///
/// The glyph is 22 px but the target is always 48 — the padding makes the
/// target, per `ui-layout-system.md §4`.
class TIconButton extends StatefulWidget {
  const TIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tone = TIconButtonTone.neutral,
    this.filled = true,
    this.showDot = false,
  });

  final String icon;
  final VoidCallback? onPressed;

  /// Required: an icon-only control is invisible to a screen reader without it.
  final String semanticLabel;

  final TIconButtonTone tone;

  /// The prototype's chip treatment (fill + border). Set false for a bare
  /// glyph, e.g. on a surface that already reads as a control strip.
  final bool filled;

  /// Unread marker, e.g. on the announcements bell.
  final bool showDot;

  @override
  State<TIconButton> createState() => _TIconButtonState();
}

enum TIconButtonTone {
  neutral,

  /// Call the passenger — green outline and glyph.
  success,
}

class _TIconButtonState extends State<TIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool enabled = widget.onPressed != null;
    final Color content = switch (widget.tone) {
      TIconButtonTone.neutral => enabled ? c.textPrimary : c.textDisabled,
      TIconButtonTone.success => enabled ? c.success : c.textDisabled,
    };
    final Color border = switch (widget.tone) {
      TIconButtonTone.neutral => c.borderControl,
      TIconButtonTone.success => c.success,
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed && !reduceMotion(context) ? 0.97 : 1,
          duration: Motion.press,
          child: SizedBox.square(
            dimension: Sizes.touchTarget,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: widget.filled ? c.bgRaised : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: widget.filled ? Border.all(color: border) : null,
                  ),
                ),
                TIcon(widget.icon, color: content),
                if (widget.showDot)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: c.brandIdentity,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.bgSurface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
