import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/booking/domain/trip_state_machine.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_motion.dart';

/// UX-redesign C3 — the stage banner floating over the trip map.
///
/// The prototype carries two elements here: a trip card and a separate status
/// pill that repeat each other. They are merged into one (`DD-10`) — over a
/// map, while driving, fewer things is the point.
///
/// Replaces the app-bar title the screen used to have, so the map can run
/// full-bleed.
class TripHeader extends StatelessWidget {
  const TripHeader({
    super.key,
    required this.stage,
    required this.title,
    required this.bookingCode,
  });

  final TripStage stage;

  /// The stage's name. Same four translation keys the app bar used.
  final String title;

  final int bookingCode;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final (Color tint, Color content) = switch (stage) {
      TripStage.requestReceived => (c.stageRequestTint, c.stageRequestText),
      TripStage.enRouteToPickup || TripStage.waitingAtPickup => (
          c.stagePickupTint,
          c.stagePickupText
        ),
      _ => (c.stageOnTripTint, c.stageOnTripText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: Radii.controlRadius,
        border: Border.all(color: content.withValues(alpha: 0.35)),
        boxShadow: Elevations.float,
      ),
      child: Row(
        children: <Widget>[
          // P1 (`02 §13`): 9 px dot pulsing at 1.2 s; static under reduced
          // motion.
          TPulseDot(color: content),
          const SizedBox(width: Insets.s8),
          Expanded(
            child: Text(
              title,
              style: context.texts.bodyStrong.copyWith(color: content),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Insets.s8),
          Text(
            '#$bookingCode',
            style: context.texts.caption.copyWith(color: content),
          ),
        ],
      ),
    );
  }
}
