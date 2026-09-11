import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/features/referral/domain/referral_notifications.dart';
import 'package:tara_driver_application/features/referral/domain/reward_status.dart';
import 'package:tara_driver_application/features/trip/domain/trip_state_machine.dart';

/// N-08 (docs/12) — referral notification policy and the passenger digest.
/// Money and driver safety, so mandatory territory per `.agent/RULES.md`.
void main() {
  group('never interrupt driving', () {
    test('only idle is safe to interrupt', () {
      for (final stage in TripStage.values) {
        expect(interruptsDriving(stage), stage != TripStage.idle,
            reason: '$stage');
      }
    });

    test('a ride request on its countdown counts as driving', () {
      expect(interruptsDriving(TripStage.requestReceived), isTrue);
    });

    test('every pushable notice is held while on a trip', () {
      for (final kind in ReferralNoticeKind.values) {
        if (kind == ReferralNoticeKind.passengerReward) continue;
        for (final stage in TripStage.values) {
          if (stage == TripStage.idle) continue;
          expect(deliveryFor(kind, stage), NoticeDelivery.holdUntilTripEnds,
              reason: '$kind at $stage');
        }
      }
    });

    test('and delivered straight away when idle', () {
      expect(deliveryFor(ReferralNoticeKind.driverReward, TripStage.idle),
          NoticeDelivery.deliverNow);
      expect(deliveryFor(ReferralNoticeKind.rewardReversed, TripStage.idle),
          NoticeDelivery.deliverNow);
    });

    test('the digest itself is held while on a trip', () {
      expect(
          deliveryFor(ReferralNoticeKind.passengerDigest, TripStage.inProgress),
          NoticeDelivery.holdUntilTripEnds);
    });
  });

  group('passenger rewards are never pushed one by one', () {
    test('batched when idle as well as when driving', () {
      for (final stage in TripStage.values) {
        expect(deliveryFor(ReferralNoticeKind.passengerReward, stage),
            NoticeDelivery.batchIntoDailyDigest,
            reason: '$stage');
      }
    });

    test('the do-not-send notices do not exist as kinds', () {
      // §10's "Do not send" list: no vague or nagging notice can be sent,
      // because there is no kind to send it under.
      expect(ReferralNoticeKind.values, hasLength(8));
    });
  });

  group('the daily digest', () {
    final day = DateTime(2026, 9, 11, 20);

    PassengerRewardRecord reward(num amount,
            {String currency = 'USD',
            DateTime? at,
            RewardStatus status = RewardStatus.pending,
            bool undated = false}) =>
        PassengerRewardRecord(
          amount: amount,
          currency: currency,
          earnedAt: undated ? null : (at ?? DateTime(2026, 9, 11, 9)),
          status: status,
        );

    test('sums the day into one digest', () {
      final r = buildDailyDigests(
          [reward(0.02), reward(0.08), reward(0.24)],
          day: day);
      expect(r.digests, hasLength(1));
      final d = r.digests.single;
      expect(d.total, closeTo(0.34, 1e-9));
      expect(d.displayTotal, 0.34);
      expect(d.rewardCount, 3);
      expect(d.day, DateTime(2026, 9, 11));
    });

    test('leaves out other days, by the local calendar', () {
      final r = buildDailyDigests([
        reward(0.10, at: DateTime(2026, 9, 11)),
        reward(0.20, at: DateTime(2026, 9, 11, 23, 59)),
        reward(0.40, at: DateTime(2026, 9, 12)),
        reward(0.80, at: DateTime(2026, 9, 10, 23, 59)),
      ], day: day);
      expect(r.digests.single.total, closeTo(0.30, 1e-9));
    });

    test('places a UTC timestamp by instant', () {
      final r = buildDailyDigests(
          [reward(0.10, at: DateTime(2026, 9, 11).toUtc())],
          day: day);
      expect(r.digests.single.rewardCount, 1);
    });

    test('leaves out reversed rewards', () {
      final r = buildDailyDigests([
        reward(0.10),
        reward(0.50, status: RewardStatus.reversed),
      ], day: day);
      expect(r.digests.single.total, closeTo(0.10, 1e-9));
      expect(r.digests.single.rewardCount, 1);
    });

    test('leaves out not-eligible rewards', () {
      // "You earned $0.50 today" for a reward that was never confirmed would
      // announce money the driver does not have.
      final r = buildDailyDigests([
        reward(0.10),
        reward(0.50, status: RewardStatus.notEligible),
      ], day: day);
      expect(r.digests.single.total, closeTo(0.10, 1e-9));
    });

    test('counts pending and available rewards alike', () {
      final r = buildDailyDigests([
        reward(0.10, status: RewardStatus.pending),
        reward(0.10, status: RewardStatus.available),
      ], day: day);
      expect(r.digests.single.rewardCount, 2);
    });

    test('never adds currencies together', () {
      final r = buildDailyDigests([
        reward(0.10, currency: 'USD'),
        reward(400, currency: 'KHR'),
        reward(0.20, currency: 'USD'),
      ], day: day);
      expect(r.digests.map((d) => d.currency), ['KHR', 'USD']);
      expect(r.digests[0].total, 400);
      expect(r.digests[1].total, closeTo(0.30, 1e-9));
    });

    test('sends nothing when there is nothing', () {
      final r = buildDailyDigests(const [], day: day);
      expect(r.digests, isEmpty);
      expect(r.undatedCount, 0);
    });

    test('sends no digest that would read as zero', () {
      // $0.004 floors to $0.00: a push saying so is worse than none.
      final r = buildDailyDigests([reward(0.004)], day: day);
      expect(r.digests, isEmpty);
    });

    test('sub-cent rewards still add up to a digest', () {
      final r = buildDailyDigests(
          [reward(0.004), reward(0.004), reward(0.004)],
          day: day);
      expect(r.digests.single.displayTotal, 0.01);
    });

    test('reports undated rewards rather than dropping them silently', () {
      final r =
          buildDailyDigests([reward(0.10), reward(0.10, undated: true)], day: day);
      expect(r.digests.single.rewardCount, 1);
      expect(r.undatedCount, 1);
    });

    test('an undated reversed reward is not reported', () {
      final r = buildDailyDigests(
          [reward(0.10, undated: true, status: RewardStatus.reversed)],
          day: day);
      expect(r.undatedCount, 0);
    });

    test('"today" stops being true after midnight', () {
      // A digest held until a trip ends can be released the next day.
      final d = buildDailyDigests([reward(0.34)], day: day).digests.single;
      expect(digestIsForToday(d, DateTime(2026, 9, 11, 23, 59)), isTrue);
      expect(digestIsForToday(d, DateTime(2026, 9, 12, 0, 5)), isFalse);
    });
  });

  group('never round up', () {
    test('cents are cut, not rounded', () {
      expect(floorForDisplay(0.345, 'USD'), 0.34);
      expect(floorForDisplay(0.349999, 'USD'), 0.34);
      expect(floorForDisplay(1.999, 'USD'), 1.99);
    });

    test('binary float error does not cost the driver a cent', () {
      // 0.29 * 100 == 28.999999999999996 in IEEE doubles.
      expect(floorForDisplay(0.29, 'USD'), 0.29);
      expect(floorForDisplay(0.1 + 0.2, 'USD'), 0.30);
      expect(floorForDisplay(4.35, 'USD'), 4.35);
    });

    test('riel is cut to whole units', () {
      expect(floorForDisplay(4199.9, 'KHR'), 4199);
      expect(floorForDisplay(4200, 'KHR'), 4200);
    });

    test('zero stays zero', () {
      expect(floorForDisplay(0, 'USD'), 0);
    });

    test('a negative amount is never overstated', () {
      expect(floorForDisplay(-1.005, 'USD'), -1.0);
    });
  });

  group('contextual prompts', () {
    final now = DateTime(2026, 9, 11, 12);

    bool can({
      ReferralPromptKind kind = ReferralPromptKind.afterFirstReward,
      TripStage stage = TripStage.idle,
      DateTime? lastShownAt,
      bool shownThisSession = false,
      Set<ReferralPromptKind> dismissed = const {},
    }) =>
        canShowReferralPrompt(
          kind: kind,
          tripStage: stage,
          now: now,
          lastShownAt: lastShownAt,
          shownThisSession: shownThisSession,
          dismissed: dismissed,
        );

    test('a first prompt may be shown', () {
      expect(can(), isTrue);
    });

    test('never while driving', () {
      expect(can(stage: TripStage.enRouteToPickup), isFalse);
      expect(can(stage: TripStage.completing), isFalse);
    });

    test('never two in the same session', () {
      expect(can(shownThisSession: true), isFalse);
    });

    test('at most one per rolling seven days', () {
      expect(can(lastShownAt: now.subtract(const Duration(days: 6, hours: 23))),
          isFalse);
      expect(can(lastShownAt: now.subtract(const Duration(days: 7))), isTrue);
    });

    test('the weekly cap spans prompt kinds', () {
      // The cap is on referral prompts, not per kind.
      expect(
          can(
              kind: ReferralPromptKind.afterCompletedTrips,
              lastShownAt: now.subtract(const Duration(days: 1))),
          isFalse);
    });

    test('a dismissed prompt is not shown again', () {
      expect(
          can(
              dismissed: {ReferralPromptKind.afterFirstReward},
              lastShownAt: now.subtract(const Duration(days: 60))),
          isFalse);
      expect(
          can(
              kind: ReferralPromptKind.afterCompletedTrips,
              dismissed: {ReferralPromptKind.afterFirstReward}),
          isTrue);
    });

    test('a last-shown time in the future blocks rather than permits', () {
      expect(can(lastShownAt: now.add(const Duration(days: 30))), isFalse);
    });

    test('the trip-count prompt is earned at twenty completed trips', () {
      expect(kInvitePromptTripThreshold, 20);
      expect(tripCountPromptEarned(19), isFalse);
      expect(tripCountPromptEarned(20), isTrue);
    });

    test('there is no post-trip passenger prompt', () {
      expect(ReferralPromptKind.values, [
        ReferralPromptKind.afterCompletedTrips,
        ReferralPromptKind.afterFirstReward,
      ]);
    });
  });
}
