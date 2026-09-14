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
    return Container(
      padding: const EdgeInsets.all(3),
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
            ),
        ],
      ),
    );
  }
}

/// Content filter tabs — history's Completed / Cancelled.
class TTabs extends StatelessWidget {
  const TTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: Radii.controlRadius,
        border: Border.all(color: c.borderDivider),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: _SelectableSegment(
                label: labels[i],
                isSelected: i == index,
                onTap: () => onChanged(i),
                radius: 10,
              ),
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double radius;

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
          child: Center(
            child: AnimatedContainer(
              duration: Motion.colorChange,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? c.bgSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: isSelected ? Elevations.selected : Elevations.flat,
              ),
              child: Text(
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
    );
  }
}
