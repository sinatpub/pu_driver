import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/count_down_widget.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C3 — the trip screen's pinned action area.
///
/// One primary action per stage, always in the same place, never scrolling
/// away (`DD-10`).
///
/// On a ride request it also carries Cancel, and the arrangement is the point
/// (`DD-11`): Accept is full width, Cancel is a text action **below** it with
/// a deliberate gap. The two used to sit side by side as a 1:2 split of
/// similar-weight buttons, which is a mis-tap waiting to happen — and
/// declining a request cannot be undone.
///
/// The one action that reads differently is Start ride, which is the primary
/// in the success colour (`DD-12`) — the sheet passes it via [primaryVariant].
///
/// On a request the decision timer lives **inside** Accept (`DD-35`): the
/// elapsed share of the button darkens from the right, and the seconds left
/// sit in a pill at its end. It is the same [SmoothCircularCountdown] timer
/// that used to float over the map, so expiry still sends the driver home.
///
/// **Both actions are disabled while [isLoading].** That is not cosmetic:
/// Cancel emits `driverCancelDrive` before the controller's guard runs, so a
/// Cancel tapped during an in-flight Accept would tell the passenger the trip
/// was cancelled while the REST call never happened. Until C3 the full-screen
/// loading overlay prevented that tap.
class TripActionBar extends StatelessWidget {
  const TripActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.isLoading,
    this.primaryVariant = TButtonVariant.primary,
    this.showCancel = false,
    this.cancelLabel,
    this.onCancel,
    this.countdownSeconds,
    this.countdownExpiresToHome = true,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;

  /// True while any trip action is in flight.
  final bool isLoading;

  /// Defaults to the primary brand action; the sheet picks success for Start
  /// ride (`DD-12`).
  final TButtonVariant primaryVariant;

  /// Only the request stage can be cancelled — `TripStateMachine.canCancel`
  /// is true for exactly that stage.
  final bool showCancel;
  final String? cancelLabel;
  final VoidCallback? onCancel;

  /// The request's decision time. Set only on the request stage; null draws
  /// a plain primary button.
  final int? countdownSeconds;

  /// Passed through as [SmoothCircularCountdown.isPop]. Only tests turn it
  /// off, so a pumped bar does not navigate when the timer runs out.
  final bool countdownExpiresToHome;

  @override
  Widget build(BuildContext context) {
    // Keyed: when a request is accepted the timer and Cancel leave the
    // column together, and without keys Flutter would hand Cancel's element
    // (48 px, content width) to the primary (56 px, full width) — and
    // AnimatedContainer cannot tween a finite width to an infinite one.
    final Widget primary = TButton(
      key: const ValueKey<String>('trip-primary'),
      label: primaryLabel,
      loading: isLoading,
      onPressed: isLoading ? null : onPrimary,
      variant: primaryVariant,
    );

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (countdownSeconds == null)
            primary
          else
            SmoothCircularCountdown(
              countDuration: countdownSeconds!,
              isPop: countdownExpiresToHome,
              builder: (BuildContext context, double fractionLeft,
                      int secondsLeft, bool isUrgent) =>
                  _TimedPrimary(
                button: primary,
                fractionLeft: fractionLeft,
                secondsLeft: secondsLeft,
                isUrgent: isUrgent,
                showSeconds: !isLoading,
              ),
            ),
          if (showCancel && cancelLabel != null) ...<Widget>[
            const SizedBox(height: Insets.betweenAcceptAndCancel),
            TButton(
              key: const ValueKey<String>('trip-cancel'),
              label: cancelLabel!,
              variant: TButtonVariant.tertiaryDanger,
              size: TButtonSize.small,
              expand: false,
              onPressed: isLoading ? null : onCancel,
            ),
          ],
        ],
      ),
    );
  }
}

/// Accept with its decision timer drawn over it. Nothing here takes taps —
/// they all reach the button underneath.
class _TimedPrimary extends StatelessWidget {
  const _TimedPrimary({
    required this.button,
    required this.fractionLeft,
    required this.secondsLeft,
    required this.isUrgent,
    required this.showSeconds,
  });

  final Widget button;
  final double fractionLeft;
  final int secondsLeft;
  final bool isUrgent;

  /// False while Accept is in flight, so only its spinner shows.
  final bool showSeconds;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Stack(
      children: <Widget>[
        button,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: Radii.controlRadius,
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: (1 - fractionLeft).clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: const ColoredBox(color: Color(0x2E000000)),
                ),
              ),
            ),
          ),
        ),
        if (showSeconds)
          Positioned(
            top: 0,
            bottom: 0,
            right: Insets.s12,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.s8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.bgSurface,
                      borderRadius: BorderRadius.circular(Radii.full),
                    ),
                    child: Text(
                      'UNIT_SECONDS_SHORT'.tr(args: <String>['$secondsLeft']),
                      style: context.texts.caption.copyWith(
                        color: isUrgent ? c.warning : c.brandText,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
