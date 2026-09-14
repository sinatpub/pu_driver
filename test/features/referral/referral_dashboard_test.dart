import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/features/referral/domain/referral_dashboard.dart';
import 'package:tara_driver_application/features/referral/domain/reward_status.dart';

/// N-04 (docs/12) — the referral dashboard's figures and empty states.
/// The driver's money, so mandatory territory per `.agent/RULES.md`.
void main() {
  RewardRecord r(
    num amount,
    RewardStatus status, {
    RewardSource source = RewardSource.invitedDriver,
    String currency = 'USD',
    DateTime? availableAt,
    String? name,
  }) =>
      RewardRecord(
        amount: amount,
        currency: currency,
        status: status,
        source: source,
        availableAt: availableAt,
        inviteeName: name,
      );

  ReferralDashboard summarize(List<RewardRecord> rewards,
          {SplitBasis basis = SplitBasis.totalEarned}) =>
      summarizeReferralRewards(rewards, splitBasis: basis);

  group('the three figures', () {
    final rewards = [
      r(10, RewardStatus.available),
      r(4, RewardStatus.pending),
      r(20, RewardStatus.transferred),
      r(30, RewardStatus.withdrawn),
      r(5, RewardStatus.reversed),
    ];

    test('available is only what is usable now', () {
      expect(summarize(rewards).available, 10);
    });

    test('pending is its own figure', () {
      expect(summarize(rewards).pending, 4);
    });

    test('total earned counts what cleared, even if it has since left', () {
      // Transferred and withdrawn were earned; pending is not yet.
      expect(summarize(rewards).totalEarned, 60);
    });

    test('a reversed reward counts toward nothing', () {
      final s = summarize([r(5, RewardStatus.reversed)]);
      expect(s.available, 0);
      expect(s.pending, 0);
      expect(s.totalEarned, 0);
    });

    test('a not-eligible reward counts toward nothing', () {
      final s = summarize([r(5, RewardStatus.notEligible)]);
      expect(s.available, 0);
      expect(s.pending, 0);
      expect(s.totalEarned, 0);
      expect(s.fromDrivers, 0);
    });

    test('no rewards is a known zero everywhere', () {
      final s = summarize(const []);
      expect(s.available, 0);
      expect(s.pending, 0);
      expect(s.totalEarned, 0);
      expect(s.fromDrivers, 0);
      expect(s.currency, isNull);
      expect(s.mixedCurrencies, isFalse);
    });

    test('the currency is carried through', () {
      expect(summarize([r(1, RewardStatus.available)]).currency, 'USD');
    });

    test('mixed currencies make every figure unknown, never a sum', () {
      final s = summarize([
        r(1, RewardStatus.available),
        r(4000, RewardStatus.available, currency: 'KHR'),
      ]);
      expect(s.mixedCurrencies, isTrue);
      expect(s.currency, isNull);
      expect(s.available, isNull);
      expect(s.pending, isNull);
      expect(s.totalEarned, isNull);
      expect(s.fromDrivers, isNull);
      expect(s.fromPassengers, isNull);
      expect(s.adjustments, isNull);
    });
  });

  group('"Where it came from"', () {
    final rewards = [
      r(15, RewardStatus.available),
      r(3.5, RewardStatus.available, source: RewardSource.invitedPassenger),
      r(50, RewardStatus.withdrawn),
      r(3.8, RewardStatus.transferred, source: RewardSource.invitedPassenger),
      r(2, RewardStatus.available, source: RewardSource.adjustment),
      r(9, RewardStatus.pending),
      r(7, RewardStatus.reversed),
    ];

    test('split by total earned sums to total earned', () {
      final s = summarize(rewards, basis: SplitBasis.totalEarned);
      expect(s.fromDrivers, 65);
      expect(s.fromPassengers, closeTo(7.3, 1e-9));
      expect(s.adjustments, 2);
      expect(s.fromDrivers! + s.fromPassengers! + s.adjustments!,
          closeTo(s.totalEarned!, 1e-9));
    });

    test('split by available sums to available — the layout example', () {
      // ui-layout-system.md §9: $15.00 + $3.50 = $18.50 Available.
      final s = summarize(rewards, basis: SplitBasis.available);
      expect(s.fromDrivers, 15);
      expect(s.fromPassengers, 3.5);
      expect(s.fromDrivers! + s.fromPassengers! + s.adjustments!,
          closeTo(s.available!, 1e-9));
    });

    test('pending and reversed rewards are in neither split', () {
      final s = summarize([
        r(9, RewardStatus.pending),
        r(7, RewardStatus.reversed),
      ]);
      expect(s.fromDrivers, 0);
    });

    test('an adjustment is reported on its own, not hidden in a row', () {
      final s = summarize(
          [r(2, RewardStatus.available, source: RewardSource.adjustment)]);
      expect(s.fromDrivers, 0);
      expect(s.fromPassengers, 0);
      expect(s.adjustments, 2);
    });
  });

  group('the pending countdown', () {
    final now = DateTime(2026, 9, 11, 12);

    test('uses the earliest server-stated clearing time', () {
      final s = summarize([
        r(1, RewardStatus.pending, availableAt: DateTime(2026, 9, 16)),
        r(1, RewardStatus.pending, availableAt: DateTime(2026, 9, 14, 12)),
      ]);
      expect(s.nextAvailableAt, DateTime(2026, 9, 14, 12));
      expect(s.daysUntilNextAvailable(now), 3);
    });

    test('rounds up: never promises money early', () {
      final s = summarize([
        r(1, RewardStatus.pending,
            availableAt: now.add(const Duration(days: 2, hours: 3))),
      ]);
      expect(s.daysUntilNextAvailable(now), 3);
    });

    test('a clearing time already past reads as zero', () {
      final s = summarize([
        r(1, RewardStatus.pending,
            availableAt: now.subtract(const Duration(hours: 1))),
      ]);
      expect(s.daysUntilNextAvailable(now), 0);
    });

    test('is unknown when no pending reward carries a date', () {
      // Not computed from the placeholder pending period: §14 forbids
      // promising a reward before the backend confirms it.
      final s = summarize([r(1, RewardStatus.pending)]);
      expect(s.nextAvailableAt, isNull);
      expect(s.daysUntilNextAvailable(now), isNull);
    });

    test('ignores dates on rewards that are not pending', () {
      final s = summarize([
        r(1, RewardStatus.available, availableAt: DateTime(2026, 9, 12)),
      ]);
      expect(s.nextAvailableAt, isNull);
    });
  });

  group('passenger privacy', () {
    test('a driver reward names the driver', () {
      expect(activityRowName(r(3, RewardStatus.available, name: 'Sok Dara')),
          'Sok Dara');
    });

    test('a passenger reward never names the passenger', () {
      // Even if the payload carries the name.
      expect(
          activityRowName(r(0.08, RewardStatus.pending,
              source: RewardSource.invitedPassenger, name: 'A Passenger')),
          isNull);
    });

    test('an adjustment names nobody', () {
      expect(
          activityRowName(r(2, RewardStatus.available,
              source: RewardSource.adjustment, name: 'Someone')),
          isNull);
    });

    test('a reversed driver reward still names the driver', () {
      // `Reversed — Sok Dara's top-up was refunded`.
      expect(activityRowName(r(1, RewardStatus.reversed, name: 'Sok Dara')),
          'Sok Dara');
    });
  });

  group('empty states', () {
    ReferralEmptyState? state({
      bool shared = false,
      int signedUp = 0,
      List<RewardRecord> rewards = const [],
    }) =>
        referralEmptyState(
            hasSharedInvite: shared, signedUpCount: signedUp, rewards: rewards);

    test('nothing shared, nobody joined', () {
      expect(state(), ReferralEmptyState.noInvitesSent);
    });

    test('shared, nobody joined', () {
      expect(state(shared: true), ReferralEmptyState.nobodySignedUp);
    });

    test('one signup, no rewards: name the unlock condition', () {
      expect(state(shared: true, signedUp: 1),
          ReferralEmptyState.signedUpNoRewardsOne);
    });

    test('several signups, no rewards', () {
      expect(state(shared: true, signedUp: 3),
          ReferralEmptyState.signedUpNoRewardsMany);
    });

    test('a signup without a recorded share is still a signup', () {
      expect(state(signedUp: 1), ReferralEmptyState.signedUpNoRewardsOne);
    });

    test('only a reversed reward is back to no rewards', () {
      expect(state(signedUp: 1, rewards: [r(1, RewardStatus.reversed)]),
          ReferralEmptyState.signedUpNoRewardsOne);
    });

    test('only a not-eligible reward is back to no rewards', () {
      // Before N-06 this read as "real figures", showing an all-zero
      // dashboard instead of the unlock-condition copy.
      expect(state(signedUp: 1, rewards: [r(1, RewardStatus.notEligible)]),
          ReferralEmptyState.signedUpNoRewardsOne);
    });

    test('every reward pending gets its own state', () {
      expect(
          state(signedUp: 1, rewards: [
            r(4.2, RewardStatus.pending),
            r(1, RewardStatus.reversed),
          ]),
          ReferralEmptyState.allPending);
    });

    test('anything cleared means real figures, no empty state', () {
      expect(
          state(signedUp: 1, rewards: [
            r(4.2, RewardStatus.pending),
            r(1, RewardStatus.available),
          ]),
          isNull);
      expect(
          state(signedUp: 1, rewards: [r(1, RewardStatus.withdrawn)]), isNull);
    });
  });
}
