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
  int get doneCount => switch (processType) {
        1 => 0,
        2 => 1,
        3 => 2,
        4 => 3,
        _ => 4,
      };

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
