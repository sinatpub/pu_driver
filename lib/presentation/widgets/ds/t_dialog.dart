import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds_icons.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_motion.dart';

/// UX-redesign F3 — the shape every dialog in the app takes (`02 §11`).
///
/// **This widget renders; it never decides.** Dismissal, barrier behaviour and
/// navigation stay in the `show…Dialog` functions that wrap it, because those
/// semantics are load-bearing and documented:
///
/// - `showErrorCustomDialog(..., comfirmBook: true)` pops **twice** — the
///   dialog *and* the route beneath it (`DD-33`).
/// - `showYesNoCustomDialog`'s YES calls `onYes` and does **not** pop; the
///   caller tears the route down.
/// - `showCancelBookingDialog` navigates home on a 10 s timer of its own
///   (`DD-25`).
///
/// Changing any of those is a behaviour change, not a restyle.
class TDialog extends StatelessWidget {
  const TDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.iconColor,
    this.top,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? message;

  /// Optional status glyph, from [DsIcons].
  final String? icon;
  final Color? iconColor;

  /// Sits between the icon and the title — the auto-dismiss progress bar, or a
  /// spinner for a progress dialog.
  final Widget? top;

  /// Rendered as an equal-width row. The **safe** choice is the primary
  /// button and the risky one is outlined (`02 §11`).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    // P1: scale in from .9 over 250 ms on top of the route's fade. Only the
    // entrance animates; dismissal and navigation are the caller's, untouched.
    return TScaleIn(
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: Radii.dialogRadius,
            boxShadow: Elevations.modal,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: (iconColor ?? c.textSecondary).withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: TIcon(
                        icon!,
                        size: TIconSize.lg,
                        color: iconColor ?? c.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Insets.s16),
              ],
              if (top != null) ...<Widget>[
                top!,
                const SizedBox(height: Insets.s16),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.texts.title.copyWith(color: c.textPrimary),
              ),
              if (message != null && message!.isNotEmpty) ...<Widget>[
                const SizedBox(height: Insets.s8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.texts.bodySecondary.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...<Widget>[
                const SizedBox(height: Insets.s16),
                Row(
                  children: <Widget>[
                    for (int i = 0; i < actions.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The draining bar on an auto-dismissing dialog (`DD-25`).
///
/// **Decoration only.** It owns an [AnimationController] and nothing else: it
/// never navigates and never calls back. The navigation timer stays where it
/// already is, in `showCancelBookingDialog`.
///
/// It is a [StatefulWidget] in its own right on purpose. The dialog it sits in
/// is built inside a `StatefulBuilder` whose builder *schedules a
/// `Future.delayed` navigation every time it runs* — so animating this bar
/// through the parent's `setState` would schedule a second, third, fourth
/// trip home. Keeping the animation local means the parent never rebuilds.
class TAutoDismissBar extends StatefulWidget {
  const TAutoDismissBar({super.key, required this.duration});

  final Duration duration;

  @override
  State<TAutoDismissBar> createState() => _TAutoDismissBarState();
}

class _TAutoDismissBarState extends State<TAutoDismissBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    // P1: it depicts a real 10 s timer, so reduced motion must not drain it
    // in half a second while the dialog stays up.
    animationBehavior: AnimationBehavior.preserve,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.full),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return LinearProgressIndicator(
            value: 1 - _controller.value,
            minHeight: 6,
            backgroundColor: c.bgSunken,
            valueColor: AlwaysStoppedAnimation<Color>(c.brandIdentity),
          );
        },
      ),
    );
  }
}
