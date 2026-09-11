import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/features/referral/domain/reward_review.dart';
import 'package:tara_driver_application/features/referral/domain/reward_status.dart';

/// N-06 (docs/12) — review and rejection as the driver sees them (copy deck
/// §14): verification without accusation, no promise before confirmation.
void main() {
  final now = DateTime(2026, 9, 11, 12);

  RewardDisplayState display(
    RewardStatus status, {
    bool flagged = false,
    DateTime? availableAt,
  }) =>
      rewardDisplayState(
        status: status,
        flaggedForReview: flagged,
        availableAt: availableAt,
        now: now,
      );

  group('pending versus being reviewed', () {
    test('pending before its stated clearing time', () {
      expect(
          display(RewardStatus.pending,
              availableAt: now.add(const Duration(days: 2))),
          RewardDisplayState.pending);
    });

    test('being reviewed once that time has passed and it has not cleared',
        () {
      expect(
          display(RewardStatus.pending,
              availableAt: now.subtract(const Duration(hours: 1))),
          RewardDisplayState.beingReviewed);
    });

    test('being reviewed at the stated moment itself', () {
      expect(display(RewardStatus.pending, availableAt: now),
          RewardDisplayState.beingReviewed);
    });

    test('being reviewed whenever the server flags it', () {
      expect(
          display(RewardStatus.pending,
              flagged: true, availableAt: now.add(const Duration(days: 2))),
          RewardDisplayState.beingReviewed);
    });

    test('no stated time is never overdue', () {
      expect(display(RewardStatus.pending), RewardDisplayState.pending);
    });

    test('a flag on a reward that already cleared changes nothing', () {
      expect(display(RewardStatus.available, flagged: true),
          RewardDisplayState.available);
    });
  });

  group('every status has one pill', () {
    test('the rest map directly', () {
      expect(display(RewardStatus.available), RewardDisplayState.available);
      expect(
          display(RewardStatus.transferred), RewardDisplayState.transferred);
      expect(display(RewardStatus.withdrawn), RewardDisplayState.withdrawn);
      expect(display(RewardStatus.reversed), RewardDisplayState.reversed);
      expect(
          display(RewardStatus.notEligible), RewardDisplayState.notEligible);
    });

    test('there is no "approved"', () {
      // §14: never say approved — Pending throughout, then Available.
      expect(RewardDisplayState.values.map((s) => s.name),
          isNot(contains('approved')));
    });
  });

  group('never accuse', () {
    test('both reasons render as the same pill', () {
      // The reason is not an input to the pill at all.
      expect(display(RewardStatus.notEligible), RewardDisplayState.notEligible);
    });

    test('an ineligible activity offers an explanation of the rules', () {
      expect(notEligibleAction(NotEligibleReason.ineligibleActivity),
          NotEligibleAction.explainWhy);
    });

    test('suspected abuse offers support, not an accusation', () {
      expect(notEligibleAction(NotEligibleReason.suspectedAbuse),
          NotEligibleAction.contactSupport);
    });

    test('an unknown reason offers support, not a guess at the rules', () {
      expect(notEligibleAction(null), NotEligibleAction.contactSupport);
    });
  });
}
