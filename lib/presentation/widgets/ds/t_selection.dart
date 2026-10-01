import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_motion.dart';

/// UX-redesign F2 — the three selection controls (`02 §13`, `04 § A`).
///
/// They share one visual idea: a recessed track with the selected option
/// lifted onto a white surface. Kept in one file because changing one without
/// the others is almost always a mistake.

/// Two-to-three option exclusive switch — language (EN / ខ្មែរ).
class TSegmented extends StatelessWidget {
  const TSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    // The track has no padding of its own: each segment carries its share of
    // the 4 px inset, so the pill sits 4 px from the track on every side (and
    // 4 px from its neighbour), while the tappable area still spans the full
    // 48 px height.
    const double gap = 4;
    return Container(
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(Radii.full),
        border: Border.all(color: c.borderDivider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < options.length; i++)
            _SelectableSegment(
              label: options[i],
              isSelected: i == selected,
              onTap: () => onChanged(i),
              radius: Radii.full,
              sizeToLabels: options,
              inset: EdgeInsets.fromLTRB(
                i == 0 ? gap : gap / 2,
                gap,
                i == options.length - 1 ? gap : gap / 2,
                gap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Content filter tabs — history's Completed / Cancelled.
///
/// DD-41: one thumb slides between equal segments, like an iOS segmented
/// control. With [position] (a page position, e.g. from a `PageController`)
/// the thumb follows a swipe as it happens; without it, the thumb animates to
/// [index] when that changes.
class TTabs extends StatelessWidget {
  const TTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.position,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// 0 … `labels.length - 1`, fractional while a page swipe is in flight.
  final ValueListenable<double>? position;

  Alignment _alignment(double at) => labels.length < 2
      ? Alignment.center
      : Alignment(
          -1 + 2 * at.clamp(0, labels.length - 1) / (labels.length - 1), 0);

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    final Widget thumb = FractionallySizedBox(
      widthFactor: 1 / labels.length,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bgSurface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: Elevations.selected,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: Radii.controlRadius,
        border: Border.all(color: c.borderDivider),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: position == null
                ? AnimatedAlign(
                    alignment: _alignment(index.toDouble()),
                    duration: reduceMotion(context)
                        ? Duration.zero
                        : Motion.colorChange,
                    curve: Curves.easeOut,
                    child: thumb,
                  )
                : ValueListenableBuilder<double>(
                    valueListenable: position!,
                    builder: (BuildContext context, double at, Widget? child) =>
                        Align(alignment: _alignment(at), child: child),
                    child: thumb,
                  ),
          ),
          Row(
            children: <Widget>[
              for (int i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: labels[i],
                    child: GestureDetector(
                      onTap: () => onChanged(i),
                      behavior: HitTestBehavior.opaque,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: Sizes.touchTarget,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Insets.s8,
                            ),
                            child: ExcludeSemantics(
                              child: Text(
                                labels[i],
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.label.copyWith(
                                  color: i == index
                                      ? c.textPrimary
                                      : c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Filter chip — the wallet's transaction-type filters.
class TChip extends StatelessWidget {
  const TChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
          child: Center(
            child: AnimatedContainer(
              duration: Motion.colorChange,
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.s16,
                vertical: Insets.s8,
              ),
              decoration: BoxDecoration(
                color: selected ? c.brandTint : c.bgSurface,
                borderRadius: BorderRadius.circular(Radii.full),
                border: Border.all(
                  color: selected ? c.brandText : c.borderControl,
                ),
              ),
              child: Text(
                label,
                style: context.texts.label.copyWith(
                  color: selected ? c.brandText : c.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One option inside [TSegmented] or [TTabs].
///
/// The visible pill is shorter than 48 px, so the tap target is expanded by a
/// [ConstrainedBox] around it rather than by padding the pill itself.
class _SelectableSegment extends StatelessWidget {
  const _SelectableSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.radius,
    this.sizeToLabels,
    this.inset,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double radius;

  /// When set, the segment is as wide as the widest of these labels, so every
  /// segment in a hug-width control has the same width — "English" and
  /// "ខ្មែរ" would otherwise get pills of very different sizes. Controls that
  /// already split the width evenly ([TTabs]) leave this null.
  final List<String>? sizeToLabels;

  /// When set, the pill fills the segment minus this inset instead of hugging
  /// its label, so the space around it is even on all four sides.
  final EdgeInsets? inset;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
          child: Padding(
            padding: inset ?? EdgeInsets.zero,
            child: Center(
              child: AnimatedContainer(
                duration: Motion.colorChange,
                height:
                    inset == null ? null : Sizes.touchTarget - inset!.vertical,
                alignment: inset == null ? null : Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: inset == null ? 14 : 16,
                  vertical: inset == null ? 10 : 0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? c.bgSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: isSelected ? Elevations.selected : Elevations.flat,
                ),
                child: _sized(
                  context,
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.texts.label.copyWith(
                      color: isSelected ? c.textPrimary : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Gives [text] the width of the widest of [sizeToLabels], measured with
  /// the same style and text scale, so every segment is equally wide.
  Widget _sized(BuildContext context, Widget text) {
    final List<String>? labels = sizeToLabels;
    if (labels == null) return text;
    final TextStyle style = context.texts.label;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    double widest = 0;
    for (final String l in labels) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: l, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widest.ceilToDouble()),
      child: text,
    );
  }
}
