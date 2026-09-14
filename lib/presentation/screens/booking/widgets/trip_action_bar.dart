import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TButton(
            label: primaryLabel,
            loading: isLoading,
            onPressed: isLoading ? null : onPrimary,
            variant: primaryVariant,
          ),
          if (showCancel && cancelLabel != null) ...<Widget>[
            const SizedBox(height: Insets.betweenAcceptAndCancel),
            TButton(
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
