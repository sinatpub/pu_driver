/// N-08 (docs/12) — when referral notices may reach a driver, and how the
/// passenger-reward digest is built.
///
/// Spec: `ux_ui_design/referral-ux-copy-deck.md` §10 (notifications), §11
/// (contextual prompts) and §1 Risk 3 (aggregation). There is no referral
/// backend and no referral FCM type, so this is the policy both ends must
/// honour, not a handler: the server is the natural home for the digest job,
/// and the client is the only place that knows the driver is mid-trip.
///
/// Pure: no copy, no Flutter, no FCM. Strings and translations belong with
/// the view, as with every other state model here.
library;

import 'package:tara_driver_application/features/referral/domain/reward_status.dart';
import 'package:tara_driver_application/features/trip/domain/trip_state_machine.dart';

/// The pushes §10 specifies. Deliberately nothing else: its "Do not send"
/// list (`You have a new referral!`, `Your network is growing`, `Invite more
/// drivers to earn more`) has no kind here, so it cannot be sent by accident.
enum ReferralNoticeKind {
  /// `You earned $1.00 from Sok Dara's top-up.`
  driverReward,

  /// One passenger-referral reward. **Never pushed on its own** — see
  /// [deliveryFor].
  passengerReward,

  /// `You earned $0.34 from passengers you invited today.`
  passengerDigest,

  /// `Sok Dara signed up with your invite. You'll earn when they top up.`
  inviteeSignedUp,

  /// `Sok Dara made their first top-up. You earned $3.00.`
  inviteeFirstTopUp,

  /// `A passenger you invited took their first trip. You earned $0.05.`
  passengerFirstTrip,

  /// `$4.50 in referral rewards is now available.`
  rewardAvailable,

  /// `A $1.00 reward was reversed because the top-up was refunded.`
  rewardReversed,
}

enum NoticeDelivery {
  deliverNow,

  /// Keep it until the trip ends, then decide again.
  holdUntilTripEnds,

  /// Fold it into the day's [PassengerDigest] instead of pushing it.
  batchIntoDailyDigest,
}

/// Whether a referral notice would interrupt driving.
///
/// Every stage but [TripStage.idle]. That includes `requestReceived`, where a
/// referral push would compete with a ride request on a countdown, and
/// `completing`, where the driver is collecting payment. §10: "any referral
/// push while the driver is on a trip" is on the do-not-send list.
bool interruptsDriving(TripStage stage) => stage != TripStage.idle;

/// How a notice of [kind] should be delivered while the driver is at
/// [tripStage].
///
/// Passenger rewards are batched **regardless of trip stage**. §10 calls the
/// frequency rule "a safety issue, not just an annoyance": a driver who gets
/// eleven `+$0.02` pushes in a day turns off notifications for the whole app,
/// ride requests included.
NoticeDelivery deliveryFor(ReferralNoticeKind kind, TripStage tripStage) {
  if (kind == ReferralNoticeKind.passengerReward) {
    return NoticeDelivery.batchIntoDailyDigest;
  }
  return interruptsDriving(tripStage)
      ? NoticeDelivery.holdUntilTripEnds
      : NoticeDelivery.deliverNow;
}

// ---- The daily passenger-reward digest ----------------------------------

/// One passenger-referral reward, as much as the digest needs.
///
/// [amount] and [currency] are non-nullable on purpose. There is no wire
/// format yet; when there is, the adapter must read them with `requireMoney`
/// (`.agent/RULES.md` §Payload policy), because a digest that silently
/// dropped an unreadable reward would understate the driver's money while
/// looking complete.
class PassengerRewardRecord {
  const PassengerRewardRecord({
    required this.amount,
    required this.currency,
    required this.earnedAt,
    required this.status,
  });

  final num amount;
  final String currency;

  /// Null when the payload does not say — never a sentinel.
  final DateTime? earnedAt;

  final RewardStatus status;
}

/// One digest push: a day's passenger rewards in one currency.
class PassengerDigest {
  const PassengerDigest({
    required this.day,
    required this.currency,
    required this.total,
    required this.rewardCount,
  });

  /// Local midnight of the day the rewards were earned.
  final DateTime day;
  final String currency;

  /// The exact sum. Display it through [floorForDisplay].
  final num total;
  final int rewardCount;

  num get displayTotal => floorForDisplay(total, currency);
}

class DailyDigestResult {
  const DailyDigestResult({required this.digests, required this.undatedCount});

  /// One per currency, sorted by currency code. Empty means send nothing.
  final List<PassengerDigest> digests;

  /// Rewards with no timestamp, which cannot be placed in a day. Reported
  /// rather than silently dropped.
  final int undatedCount;
}

/// The digests to send for the local calendar day containing [day].
///
/// - **Reversed rewards are left out.** A digest must not tell a driver they
///   earned money that has already come back out.
/// - Pending rewards count: §10's per-reward copy (`You earned $0.08…`) is
///   sent when a reward is generated, and the digest replaces exactly those.
/// - A passenger's first-trip reward is also in the digest. The milestone
///   push (`passengerFirstTrip`) announces the event; the digest is the day's
///   total, and leaving one reward out would make that total wrong.
/// - **Currencies are never added together.** One digest per currency.
/// - **No digest whose displayed total is zero.** `You earned $0.00` is the
///   crumb §1 Risk 3 warns about, minus even the crumb. The money is still in
///   the ledger; it simply does not earn a push.
DailyDigestResult buildDailyDigests(
  Iterable<PassengerRewardRecord> rewards, {
  required DateTime day,
}) {
  final start = _localMidnight(day);
  final end = DateTime(start.year, start.month, start.day + 1);

  final totals = <String, num>{};
  final counts = <String, int>{};
  var undated = 0;

  for (final r in rewards) {
    if (r.status == RewardStatus.reversed) continue;
    final at = r.earnedAt;
    if (at == null) {
      undated++;
      continue;
    }
    if (at.isBefore(start) || !at.isBefore(end)) continue;
    totals[r.currency] = (totals[r.currency] ?? 0) + r.amount;
    counts[r.currency] = (counts[r.currency] ?? 0) + 1;
  }

  final currencies = totals.keys.toList()..sort();
  return DailyDigestResult(
    digests: [
      for (final c in currencies)
        if (floorForDisplay(totals[c]!, c) > 0)
          PassengerDigest(
            day: start,
            currency: c,
            total: totals[c]!,
            rewardCount: counts[c]!,
          ),
    ],
    undatedCount: undated,
  );
}

/// Whether a digest's "today" wording is still true at [now].
///
/// A digest held until a trip ends can be released after midnight, and
/// `…passengers you invited today` would then name the wrong day.
bool digestIsForToday(PassengerDigest digest, DateTime now) =>
    _localMidnight(now) == digest.day;

/// [amount] cut to the currency's display unit, **never rounded up**.
///
/// §1: "Never round up." `$0.345` displays as `$0.34`, not `$0.35`. Riel is
/// shown in whole units and everything else in cents, matching the wallet's
/// `isWholeUnitCurrency`. That rule is repeated here rather than imported
/// because the wallet's presentation file pulls in Flutter. Truncates toward
/// zero, so a negative value is never overstated either. The nudge absorbs
/// binary float error: `0.29 * 100` is `28.999999999999996`, which would
/// otherwise display as `$0.28`.
num floorForDisplay(num amount, String currency) {
  final unitsPerMajor = currency == 'KHR' ? 1 : 100;
  final scaled = amount * unitsPerMajor;
  final nudged = scaled >= 0 ? scaled + 1e-9 : scaled - 1e-9;
  return nudged.truncate() / unitsPerMajor;
}

DateTime _localMidnight(DateTime t) {
  final local = t.toLocal();
  return DateTime(local.year, local.month, local.day);
}

// ---- Contextual prompts (§11) -------------------------------------------

/// The in-app invite prompts §11 allows. There is deliberately no post-trip
/// passenger prompt: §11 recommends against pitching the app to a passenger
/// just driven, "in order to earn a fraction of a cent".
enum ReferralPromptKind {
  /// `Enjoying driving with us? Invite another driver…`
  afterCompletedTrips,

  /// `You earned $3.00 from Sok Dara. Invite another driver?`
  afterFirstReward,
}

/// §11: the trip-count prompt appears "after 20 completed trips". This is
/// the spec's number, not a placeholder.
const int kInvitePromptTripThreshold = 20;

/// §11: "no more than one contextual referral prompt per week". Applied as a
/// rolling seven days, the strictest reading: it also guarantees at most one
/// in any calendar week, whichever day that week starts on.
const Duration kReferralPromptMinimumGap = Duration(days: 7);

/// Whether the trip-count prompt has been earned.
bool tripCountPromptEarned(int completedTrips) =>
    completedTrips >= kInvitePromptTripThreshold;

/// Whether a prompt of [kind] may be shown now.
///
/// All of these must hold:
/// - the driver is not on a trip;
/// - [kind] has not been dismissed ("Dismissal must be remembered", read as
///   never showing a dismissed prompt again);
/// - no prompt has been shown this session ("never two in the same
///   session");
/// - the last prompt was at least [kReferralPromptMinimumGap] ago. A
///   [lastShownAt] in the future means the clock moved, and is treated as
///   "just shown" rather than as permission.
bool canShowReferralPrompt({
  required ReferralPromptKind kind,
  required TripStage tripStage,
  required DateTime now,
  required DateTime? lastShownAt,
  required bool shownThisSession,
  required Set<ReferralPromptKind> dismissed,
}) {
  if (interruptsDriving(tripStage)) return false;
  if (dismissed.contains(kind)) return false;
  if (shownThisSession) return false;

  final last = lastShownAt;
  if (last == null) return true;
  if (now.isBefore(last)) return false;
  return now.difference(last) >= kReferralPromptMinimumGap;
}
