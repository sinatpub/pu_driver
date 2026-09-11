/// N-04 (docs/12) — the referral dashboard's figures and empty states.
///
/// N-04 is "reward wallet + transfer". The **transfer** half is blocked: it
/// needs U3 (one balance or two, copy deck §15 "ship neither until product
/// decides") and a route that does not exist. The **dashboard** half is fully
/// specified and needs only the reward model N-03 already built. Spec:
/// `referral-ux-copy-deck.md` §9, §12; `ui-layout-system.md` §9.
///
/// Pure: no copy, no Flutter, no HTTP.
library;

import 'package:tara_driver_application/features/referral/domain/reward_status.dart';

/// What a reward was for.
enum RewardSource {
  /// `{Name} topped up {amount}` — a driver you invited topped up.
  invitedDriver,

  /// `Trip by a passenger you invited`.
  invitedPassenger,

  /// `Adjustment — {reason}` — a manual correction. It belongs to neither
  /// split row, so it is reported separately rather than folded into one.
  adjustment,
}

/// What the "Where it came from" rows break down. **An open spec question.**
///
/// The label reads as a lifetime breakdown. But the layout system's worked
/// example splits into `$15.00` + `$3.50` = `$18.50`, which is the
/// **Available** figure, not the `$72.30` Total earned. Required with no
/// default, so whoever builds the screen has to choose, and the rows always
/// sum to the figure they claim to explain.
enum SplitBasis { totalEarned, available }

/// One reward, as the dashboard needs it.
///
/// [amount] and [currency] are non-nullable. When a wire format exists, the
/// adapter must read them with `requireMoney` (`.agent/RULES.md` §Payload
/// policy). A dashboard that dropped an unreadable reward would understate
/// the driver's money while looking complete.
class RewardRecord {
  const RewardRecord({
    required this.amount,
    required this.currency,
    required this.status,
    required this.source,
    this.availableAt,
    this.inviteeName,
  });

  final num amount;
  final String currency;
  final RewardStatus status;
  final RewardSource source;

  /// When a pending reward becomes available, **as the server states it**.
  /// Never computed client-side from the placeholder pending period: §14
  /// forbids the UI to promise a reward before the backend confirms it.
  final DateTime? availableAt;

  /// The invited person's name. Only ever displayed for driver rewards —
  /// see [activityRowName].
  final String? inviteeName;
}

/// Everything the dashboard's figures show.
class ReferralDashboard {
  const ReferralDashboard({
    required this.currency,
    required this.mixedCurrencies,
    required this.available,
    required this.pending,
    required this.totalEarned,
    required this.fromDrivers,
    required this.fromPassengers,
    required this.adjustments,
    required this.nextAvailableAt,
  });

  /// Null when there are no rewards, or when [mixedCurrencies] is true.
  final String? currency;

  /// The rewards span more than one currency. Every total is then null
  /// rather than a sum of dollars and riel. Which currency displays by
  /// default is itself open (copy deck §18).
  final bool mixedCurrencies;

  /// `Available` — cleared and usable now.
  final num? available;

  /// `Pending` — earned, not yet confirmed. Not part of [totalEarned].
  final num? pending;

  /// `Total earned` — available, transferred and withdrawn. Reversed
  /// rewards are excluded, so a reversal lowers this figure.
  final num? totalEarned;

  /// `Drivers you invited` / `Passengers you invited`, under the chosen
  /// [SplitBasis]. With [adjustments], they sum exactly to that figure.
  final num? fromDrivers;
  final num? fromPassengers;
  final num? adjustments;

  /// The earliest server-stated time a pending reward clears. Null when
  /// nothing is pending or no pending reward carries a date.
  final DateTime? nextAvailableAt;

  /// Whole days until [nextAvailableAt], for the pending card's `3 days`.
  ///
  /// Rounded **up**: saying "2 days" when it is 2 days and 3 hours away
  /// promises money early. A clearing time already past but not yet
  /// reflected reads as 0 rather than a negative count.
  int? daysUntilNextAvailable(DateTime now) {
    final at = nextAvailableAt;
    if (at == null) return null;
    final minutes = at.difference(now).inMinutes;
    if (minutes <= 0) return 0;
    return (minutes / Duration.minutesPerDay).ceil();
  }
}

/// Builds the dashboard figures from [rewards].
///
/// No rewards is a known zero on every figure. Mixed currencies make every
/// figure unknown.
ReferralDashboard summarizeReferralRewards(
  Iterable<RewardRecord> rewards, {
  required SplitBasis splitBasis,
}) {
  final list = rewards.toList();
  final currencies = {for (final r in list) r.currency};
  final mixed = currencies.length > 1;

  DateTime? nextAt;
  for (final r in list) {
    final at = r.availableAt;
    if (r.status != RewardStatus.pending || at == null) continue;
    if (nextAt == null || at.isBefore(nextAt)) nextAt = at;
  }

  if (mixed) {
    return ReferralDashboard(
      currency: null,
      mixedCurrencies: true,
      available: null,
      pending: null,
      totalEarned: null,
      fromDrivers: null,
      fromPassengers: null,
      adjustments: null,
      nextAvailableAt: nextAt,
    );
  }

  num available = 0, pending = 0, total = 0;
  num drivers = 0, passengers = 0, adjustments = 0;

  for (final r in list) {
    if (r.status.countsTowardAvailableBalance) available += r.amount;
    if (r.status == RewardStatus.pending) pending += r.amount;
    if (r.status.countsTowardTotalEarned) total += r.amount;

    final inSplit = switch (splitBasis) {
      SplitBasis.totalEarned => r.status.countsTowardTotalEarned,
      SplitBasis.available => r.status.countsTowardAvailableBalance,
    };
    if (!inSplit) continue;
    switch (r.source) {
      case RewardSource.invitedDriver:
        drivers += r.amount;
      case RewardSource.invitedPassenger:
        passengers += r.amount;
      case RewardSource.adjustment:
        adjustments += r.amount;
    }
  }

  return ReferralDashboard(
    currency: currencies.isEmpty ? null : currencies.single,
    mixedCurrencies: false,
    available: available,
    pending: pending,
    totalEarned: total,
    fromDrivers: drivers,
    fromPassengers: passengers,
    adjustments: adjustments,
    nextAvailableAt: nextAt,
  );
}

/// The name an activity row may show, or null for none.
///
/// §9: driver rewards name the driver, a colleague in a professional
/// relationship. Passenger rewards **never** name the passenger: "A driver
/// knowing the spending patterns of a named passenger is a privacy problem
/// and, given drivers can be assigned to those passengers, a safety one."
/// Enforced here, so a payload that happens to carry a passenger's name
/// still cannot put it on screen.
String? activityRowName(RewardRecord reward) =>
    reward.source == RewardSource.invitedDriver ? reward.inviteeName : null;

// ---- Empty states (§12) --------------------------------------------------

enum ReferralEmptyState {
  /// `You haven't invited anyone yet`
  noInvitesSent,

  /// `No one has signed up yet` / `Your invite code is {CODE}. Share it again?`
  nobodySignedUp,

  /// `No rewards yet` / `You'll earn when {name} tops up their wallet.`
  signedUpNoRewardsOne,

  /// `No rewards yet` / `You'll earn when the drivers you invited top up…`
  signedUpNoRewardsMany,

  /// `$4.20 pending` / `Your first rewards are being confirmed…`
  allPending,
}

/// Which §12 empty state applies, or null when the dashboard has real
/// figures to show.
///
/// §12 calls the signed-up-but-no-rewards rows "the most important empty
/// states in the product": a driver with three signups and nothing earned
/// "is at peak risk of concluding the system is fake", so the copy must state
/// the unlock condition. That is why one and many are distinct states.
///
/// Reversed rewards do not count as rewards existing: a driver whose only
/// reward was reversed has nothing earned and is back in the signed-up state.
/// All-pending gets its own state because a zero Available next to a
/// non-zero Pending is the confusion the strategy's §21 flags.
///
/// [hasSharedInvite] is whatever the app knows about the driver sharing a
/// code. Sharing happens in other apps, so the server cannot know it.
ReferralEmptyState? referralEmptyState({
  required bool hasSharedInvite,
  required int signedUpCount,
  required Iterable<RewardRecord> rewards,
}) {
  final live = [
    for (final r in rewards)
      if (r.status != RewardStatus.reversed) r,
  ];

  if (live.isEmpty) {
    if (signedUpCount <= 0) {
      return hasSharedInvite
          ? ReferralEmptyState.nobodySignedUp
          : ReferralEmptyState.noInvitesSent;
    }
    return signedUpCount == 1
        ? ReferralEmptyState.signedUpNoRewardsOne
        : ReferralEmptyState.signedUpNoRewardsMany;
  }

  final allPending = live.every((r) => r.status == RewardStatus.pending);
  return allPending ? ReferralEmptyState.allPending : null;
}
