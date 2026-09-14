import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds_icons.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_button.dart';

/// UX-redesign F3 — the loading, empty and error states every list owes its
/// reader (`02 §11`, `04 § A`).

/// A loading placeholder shaped like the content it replaces.
///
/// Uses the `shimmer` package the app already depends on. Never a spinner
/// where the shape is known: a spinner says "something is happening", a
/// skeleton says "a list of trips is coming".
class TSkeleton extends StatelessWidget {
  const TSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = Radii.sm,
  });

  /// A single text line.
  const TSkeleton.line({Key? key, double? width})
      : this(key: key, width: width, height: 16);

  /// A block — a card, an avatar, a thumbnail.
  const TSkeleton.box({
    Key? key,
    double? width,
    double height = 120,
    double radius = Radii.lg,
  }) : this(key: key, width: width, height: height, radius: radius);

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    return Shimmer.fromColors(
      baseColor: c.bgSunken,
      highlightColor: c.bgRaised,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: c.bgSunken,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Nothing to show, and that is not an error.
class TEmptyState extends StatelessWidget {
  const TEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _StateBody(
      icon: icon,
      iconColor: context.colors.textSecondary,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Something failed, and the reader needs a way out of it.
///
/// Always offers the retry, because the alternative the app shipped before was
/// a screen that loaded forever with no way back.
class TErrorState extends StatelessWidget {
  const TErrorState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _StateBody(
      icon: DsIcons.warn,
      iconColor: context.colors.danger,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _StateBody extends StatelessWidget {
  const _StateBody({
    required this.title,
    required this.iconColor,
    this.icon,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Color iconColor;
  final String? icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s24,
        vertical: Insets.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            TIcon(icon!, size: TIconSize.lg, color: iconColor),
            const SizedBox(height: Insets.s16),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.texts.subtitle.copyWith(color: c.textPrimary),
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
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: Insets.s24),
            TButton(
              label: actionLabel!,
              variant: TButtonVariant.secondary,
              size: TButtonSize.small,
              expand: false,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
