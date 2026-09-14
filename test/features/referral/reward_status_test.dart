import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/features/referral/domain/reward_status.dart';

/// N-03 (docs/12) — the model U1 blocks, built to survive either answer.
void main() {
  group('U1: the two candidate lifecycles', () {
    test('the two-state model cannot produce transferred or withdrawn', () {
      const m = RewardLifecycle.twoState;
      expect(m.permits(RewardStatus.pending), isTrue);
      expect(m.permits(RewardStatus.available), isTrue);
      expect(m.permits(RewardStatus.transferred), isFalse);
      expect(m.permits(RewardStatus.withdrawn), isFalse);
    });

    test('the four-state model permits all of them', () {
      const m = RewardLifecycle.fourState;
      for (final s in RewardStatus.values) {
        expect(m.permits(s), isTrue, reason: '$s');
      }
    });

    test('the two-state statuses are a strict subset of the four-state ones',
        () {
      // This is why one enum can serve both answers: choosing the smaller
      // model now would mean a migration if the flowchart turns out to be
      // authoritative.
      expect(
        RewardLifecycle.fourState.validStatuses
            .containsAll(RewardLifecycle.twoState.validStatuses),
        isTrue,
      );
    });

    test('reversal exists under both models', () {
      // docs/03 N5 specifies it separately from either U1 candidate.
      expect(RewardLifecycle.twoState.permits(RewardStatus.reversed), isTrue);
      expect(RewardLifecycle.fourState.permits(RewardStatus.reversed), isTrue);
    });
  });

  group('transitions', () {
    test('a reward clears from pending to available', () {
      expect(
        RewardLifecycle.twoState
            .allowsTransition(RewardStatus.pending, RewardStatus.available),
        isTrue,
      );
    });

    test('a reward cannot be withdrawn before it clears', () {
      // Skipping `available` would pay out money that has not been confirmed.
      expect(
        RewardLifecycle.fourState
            .allowsTransition(RewardStatus.pending, RewardStatus.withdrawn),
        isFalse,
      );
      expect(
        RewardLifecycle.fourState
            .allowsTransition(RewardStatus.available, RewardStatus.withdrawn),
        isFalse,
      );
    });

    test('the four-state path runs in order', () {
      const m = RewardLifecycle.fourState;
      expect(
          m.allowsTransition(RewardStatus.available, RewardStatus.transferred),
          isTrue);
      expect(
          m.allowsTransition(RewardStatus.transferred, RewardStatus.withdrawn),
          isTrue);
    });

    test('the two-state model refuses the transfer step entirely', () {
      expect(
        RewardLifecycle.twoState
            .allowsTransition(RewardStatus.available, RewardStatus.transferred),
        isFalse,
      );
    });

    test('a reward can be reversed from any non-terminal status', () {
      // The refund that triggers reversal can land at any time.
      const m = RewardLifecycle.fourState;
      expect(m.allowsTransition(RewardStatus.pending, RewardStatus.reversed),
          isTrue);
      expect(m.allowsTransition(RewardStatus.available, RewardStatus.reversed),
          isTrue);
      expect(
          m.allowsTransition(RewardStatus.transferred, RewardStatus.reversed),
          isTrue);
    });

    test('money that has left cannot un-leave', () {
      const m = RewardLifecycle.fourState;
      for (final to in RewardStatus.values) {
        expect(m.allowsTransition(RewardStatus.withdrawn, to), isFalse,
            reason: 'withdrawn -> $to');
        expect(m.allowsTransition(RewardStatus.reversed, to), isFalse,
            reason: 'reversed -> $to');
        expect(m.allowsTransition(RewardStatus.notEligible, to), isFalse,
            reason: 'notEligible -> $to');
      }
    });

    test('nothing transitions to itself', () {
      for (final s in RewardStatus.values) {
        expect(RewardLifecycle.fourState.allowsTransition(s, s), isFalse);
      }
    });

    test('transitions never run backwards', () {
      const m = RewardLifecycle.fourState;
      expect(m.allowsTransition(RewardStatus.available, RewardStatus.pending),
          isFalse);
      expect(
          m.allowsTransition(RewardStatus.transferred, RewardStatus.available),
          isFalse);
    });
  });

  group('balance and totals', () {
    test('pending money is not spendable', () {
      // The copy deck is emphatic that the UI must never promise a reward
      // before the backend confirms it.
      expect(RewardStatus.pending.countsTowardAvailableBalance, isFalse);
      expect(RewardStatus.available.countsTowardAvailableBalance, isTrue);
    });

    test('transferred money has left the reward balance', () {
      expect(RewardStatus.transferred.countsTowardAvailableBalance, isFalse);
      expect(RewardStatus.withdrawn.countsTowardAvailableBalance, isFalse);
    });

    test('a reversed reward counts toward nothing', () {
      expect(RewardStatus.reversed.countsTowardAvailableBalance, isFalse);
      expect(RewardStatus.reversed.countsTowardTotalEarned, isFalse);
    });

    test('transferred and withdrawn rewards still count as earned', () {
      // They were earned; moving them must not erase them from the total.
      expect(RewardStatus.transferred.countsTowardTotalEarned, isTrue);
      expect(RewardStatus.withdrawn.countsTowardTotalEarned, isTrue);
    });

    test('pending is not yet earned', () {
      expect(RewardStatus.pending.countsTowardTotalEarned, isFalse);
    });
  });

  group('not eligible (N-06, copy deck §14)', () {
    test('exists under both lifecycles', () {
      expect(
          RewardLifecycle.twoState.permits(RewardStatus.notEligible), isTrue);
      expect(
          RewardLifecycle.fourState.permits(RewardStatus.notEligible), isTrue);
    });

    test('only a pending reward can be found not eligible', () {
      // Rejection happens at confirmation. A reward that cleared and later
      // proves bad is reversed instead.
      for (final m in RewardLifecycle.values) {
        for (final from in RewardStatus.values) {
          expect(m.allowsTransition(from, RewardStatus.notEligible),
              from == RewardStatus.pending,
              reason: '$m: $from -> notEligible');
        }
      }
    });

    test('is final, and cannot later be reversed', () {
      expect(RewardStatus.notEligible.isTerminal, isTrue);
      expect(
          RewardLifecycle.fourState.allowsTransition(
              RewardStatus.notEligible, RewardStatus.reversed),
          isFalse);
    });

    test('counts toward nothing', () {
      expect(RewardStatus.notEligible.countsTowardAvailableBalance, isFalse);
      expect(RewardStatus.notEligible.countsTowardTotalEarned, isFalse);
    });

    test('void means reversed or not eligible, and nothing else', () {
      for (final s in RewardStatus.values) {
        expect(s.isVoid,
            s == RewardStatus.reversed || s == RewardStatus.notEligible,
            reason: '$s');
      }
    });

    test('reversal is still possible from every non-terminal status', () {
      const m = RewardLifecycle.fourState;
      for (final from in RewardStatus.values) {
        if (from.isTerminal) continue;
        expect(m.allowsTransition(from, RewardStatus.reversed), isTrue,
            reason: '$from -> reversed');
      }
    });
  });

  group('U2: funding source', () {
    test('both models exist and neither is a default', () {
      // RewardFunding has no default value anywhere in this library, so a
      // calculation cannot silently assume platform-funded. U2 is recorded in
      // DECISIONS.md as the highest-priority blocking question in the project.
      expect(RewardFunding.values, hasLength(2));
      expect(RewardFunding.values, contains(RewardFunding.platformFunded));
      expect(RewardFunding.values, contains(RewardFunding.deductedFromInvitee));
    });
  });
}
