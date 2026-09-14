import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds_icons.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_motion.dart';

/// UX-redesign F3 — sheets, toasts and banners (`02 §10`, `§11`).

/// A modal bottom sheet in the design system's shape.
///
/// The existing `xShowModalBottomSheet` is left alone: registration's photo
/// picker uses it, and migrating that screen is S4's job, not F3's.
Future<T?> showTSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.colors.scrim,
    // P1 (`02 §15`): 300 ms on the spec curve; no slide under reduced motion.
    sheetAnimationStyle: reduceMotion(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Motion.sheet,
            reverseDuration: Motion.sheet,
            curve: Motion.sheetCurve,
          ),
    builder: (BuildContext sheetContext) => TSheet(title: title, child: child),
  );
}

/// The sheet body: grabber, optional title, content.
class TSheet extends StatelessWidget {
  const TSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.84,
      ),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: Radii.sheetRadius,
        boxShadow: Elevations.sheet,
      ),
      padding: const EdgeInsets.fromLTRB(
        Insets.s20,
        Insets.s12,
        Insets.s20,
        26,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: c.borderDivider,
                  borderRadius: BorderRadius.circular(Radii.full),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (title != null) ...<Widget>[
              Text(
                title!,
                style: context.texts.subtitle.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: Insets.s12),
            ],
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Transient feedback.
///
/// Only for feedback the app does not already give another way (`DD-27`).
/// Trip transitions already post local notifications, and duplicating those
/// as toasts is noise while driving.
void showTToast(
  BuildContext context,
  String message, {
  String? icon,
  Duration duration = const Duration(milliseconds: 2400),
}) {
  final TaarraaColors c = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.toastBackground,
        elevation: 0,
        margin: const EdgeInsets.all(Insets.s20),
        shape: RoundedRectangleBorder(borderRadius: Radii.controlRadius),
        content: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              TIcon(icon, size: TIconSize.sm, color: c.toastText),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: context.texts.bodySecondary.copyWith(
                  color: c.toastText,
                  fontWeight: FontWeights.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

enum TBannerTone { warning, danger, info }

/// A persistent inline notice — the offline bar is the one that matters
/// (`DD-26`). Amber, not red: losing connectivity is a condition to state, not
/// a crash to alarm about.
class TBanner extends StatelessWidget {
  const TBanner({
    super.key,
    required this.message,
    this.tone = TBannerTone.warning,
    this.icon = DsIcons.warn,
  });

  final String message;
  final TBannerTone tone;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final (Color fill, Color content) = switch (tone) {
      TBannerTone.warning => (c.warningTint, c.warning),
      TBannerTone.danger => (c.bgSurface, c.danger),
      TBannerTone.info => (c.bgSurface, c.info),
    };

    return Container(
      width: double.infinity,
      color: fill,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s16,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            TIcon(icon!, size: TIconSize.sm, color: content),
            const SizedBox(width: Insets.s8),
          ],
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.texts.micro.copyWith(color: content),
            ),
          ),
        ],
      ),
    );
  }
}
