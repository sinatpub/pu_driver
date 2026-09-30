import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C3 — the four driver actions, and which one is next.
///
/// Accept → Arrive → Start → Drop. These are exactly the transitions
/// `TripStateMachine` allows, so the timeline can never offer a step the app
/// cannot perform.
///
/// Driven by `processStepBook`, the legacy int the sheet already receives:
/// 1 = request, 2 = en route, 3 = at pickup, 4 = in progress, 6 = completing.
/// How many of the four steps are finished at [processType]. `completing`
/// (6) is the drop-off in flight, so every step is done.
int tripStepsDone(int processType) => switch (processType) {
      1 => 0,
      2 => 1,
      3 => 2,
      4 => 3,
      _ => 4,
    };

class TripTimeline extends StatelessWidget {
  const TripTimeline({
    super.key,
    required this.processType,
    required this.labels,
  });

  final int processType;

  /// Four short labels, in order.
  final List<String> labels;

  /// How many steps are finished. `completing` (6) is the drop-off in flight,
  /// so every step is done.
  int get doneCount => tripStepsDone(processType);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < labels.length; i++)
          Expanded(
            child: _Step(
              label: labels[i],
              index: i,
              done: i < doneCount,
              current: i == doneCount,
              connectorReached: i <= doneCount,
              showConnector: i > 0,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.index,
    required this.done,
    required this.current,
    required this.connectorReached,
    required this.showConnector,
  });

  final String label;
  final int index;
  final bool done;
  final bool current;

  /// Whether the line running back to the previous step is behind the driver.
  final bool connectorReached;

  /// The first step has nothing to its left.
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    final Color dotFill = done
        ? c.successTint
        : current
            ? c.actionPrimary
            : c.bgRaised;
    final Color dotBorder = done
        ? c.success
        : current
            ? c.actionPrimary
            : c.borderDivider;
    final Color dotContent = done
        ? c.success
        : current
            ? c.textOnAction
            : c.textSecondary;
    final Color labelColor = done
        ? c.success
        : current
            ? c.brandText
            : c.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 26,
          child: Row(
            children: <Widget>[
              // Left half: the connector back to the previous step.
              Expanded(
                child: showConnector
                    ? AnimatedContainer(
                        duration: Motion.timelineStep,
                        height: 2,
                        color: connectorReached ? c.success : c.borderDivider,
                      )
                    : const SizedBox.shrink(),
              ),
              // P1: the step fills over 200 ms (colour only — no movement).
              AnimatedContainer(
                duration: Motion.timelineStep,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: dotFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotBorder),
                ),
                child: Center(
                  child: done
                      ? TIcon(
                          DsIcons.check,
                          size: TIconSize.sm,
                          color: dotContent,
                        )
                      : Text(
                          '${index + 1}',
                          style:
                              context.texts.micro.copyWith(color: dotContent),
                        ),
                ),
              ),
              // Right half stays empty; the next step draws its own connector.
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.micro.copyWith(color: labelColor),
        ),
      ],
    );
  }
}

/// DD-36 — the four steps as one thin bar under the stage line, replacing
/// [TripTimeline]'s numbered circles on the stages that have moved to the
/// compact sheet. Finished steps are green, the current one is in the
/// stage's colour, the rest are neutral.
///
/// DD-38: on a trip with a destination, the current step fills as the trip
/// progresses ([currentFraction]); otherwise it is drawn solid.
class TripProgressBar extends StatelessWidget {
  const TripProgressBar({
    super.key,
    required this.processType,
    required this.currentColor,
    this.currentFraction,
  });

  final int processType;
  final Color currentColor;

  /// 0–1: how much of the current step is done. Null draws it solid.
  final double? currentFraction;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final int done = tripStepsDone(processType);

    return Semantics(
      label: 'STEP_OF'.tr(args: <String>['${(done + 1).clamp(1, 4)}', '4']),
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            for (int i = 0; i < 4; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 3,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: i < done
                        ? c.success
                        : i == done && currentFraction == null
                            ? currentColor
                            : c.borderDivider,
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                  alignment: Alignment.centerLeft,
                  child: i == done && currentFraction != null
                      ? FractionallySizedBox(
                          widthFactor: currentFraction!.clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: ColoredBox(color: currentColor),
                        )
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
