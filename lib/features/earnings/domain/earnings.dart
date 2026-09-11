/// N-09 (docs/12) — the rules behind the driver's earnings dashboard.
///
/// Spec: `ux_ui_design/ui-layout-system.md` §9 (layout) and
/// `ux_ui_design/referral-ux-copy-deck.md` §9 (copy). Neither has a backend:
/// `docs/03` M5 records that the screen "needs an earnings aggregation
/// endpoint", and none exists. What can be built without one is the set of
/// rules that must hold whatever that endpoint eventually returns.
///
/// Pure: no Flutter, no HTTP, no data models. Callers adapt their payloads
/// into [TripRecord] — see `earnings_from_history.dart`.
library;

import 'package:tara_driver_application/core/contracts/booking_status.dart';

/// Which day "This week" starts on.
///
/// **Placeholder, not a decision.** Neither spec says. Monday matches ISO 8601
/// and `DateTime.weekday`'s numbering; a driver who expects Sunday will see a
/// different weekly total. A product/ops call.
const int kWeekStartDayPlaceholder = DateTime.monday;

/// The period selector: `Today` · `This week` · `This month` · `All time`
/// (copy deck §9).
enum EarningsPeriod { today, thisWeek, thisMonth, allTime }

/// What a completed trip earns the driver — **an open business question.**
///
/// The copy deck's glossary (§2) defines trip earnings as "money you earn from
/// completing trips" and explicitly forbids calling them fares: "fares are
/// what the passenger pays". The client only ever sees the amount the
/// passenger was charged. Nothing in either app knows the platform's cut.
///
/// Modelled as a required value with **no default**, the same way U2 is in
/// `referral/domain/reward_status.dart`: any code that shows a driver a trip
/// earning has to say which definition it assumes, so the question cannot be
/// answered silently by whoever builds the screen.
enum TripEarningBasis {
  /// The driver keeps the whole amount charged; the platform takes its cut
  /// some other way (for example, from the wallet).
  fullFare,

  /// The amount charged, minus the platform's commission.
  ///
  /// **Not computable today.** No payload carries a per-trip commission, so
  /// under this basis every trip's earning is unknown rather than guessed.
  netOfPlatformCommission,
}

/// The rows of the breakdown, in the order they must appear.
///
/// "Trip earnings appear above referral earnings, always, at every breakpoint
/// and in every period" (layout system §9). The layout system calls this the
/// product position rather than a visual preference, so the order is data
/// rather than something each screen decides.
enum EarningsSource { trips, referrals }

const List<EarningsSource> kEarningsBreakdownOrder = [
  EarningsSource.trips,
  EarningsSource.referrals,
];

/// A half-open time range: [start] inclusive, [end] exclusive.
class EarningsWindow {
  const EarningsWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;

  /// Compares instants, so a UTC timestamp from the backend is placed
  /// correctly against a window built in local time.
  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);
}

/// The window [period] covers, in the device's local time, or null for
/// [EarningsPeriod.allTime], which is unbounded.
///
/// "Today" means the driver's today, not UTC's: a driver in Phnom Penh
/// finishing a trip at 06:30 must see it under Today, not yesterday. Built
/// with calendar arithmetic rather than `Duration(days: 1)` so a day is
/// always a calendar day.
EarningsWindow? windowFor(EarningsPeriod period, DateTime now) {
  final local = now.toLocal();
  final y = local.year;
  final m = local.month;
  final d = local.day;

  switch (period) {
    case EarningsPeriod.today:
      return EarningsWindow(DateTime(y, m, d), DateTime(y, m, d + 1));
    case EarningsPeriod.thisWeek:
      // Dart's `%` is never negative for a positive divisor.
      final back = (local.weekday - kWeekStartDayPlaceholder) % 7;
      return EarningsWindow(
        DateTime(y, m, d - back),
        DateTime(y, m, d - back + 7),
      );
    case EarningsPeriod.thisMonth:
      return EarningsWindow(DateTime(y, m), DateTime(y, m + 1));
    case EarningsPeriod.allTime:
      return null;
  }
}

/// One trip, as much as the earnings rules need to know about it.
class TripRecord {
  const TripRecord({
    required this.status,
    required this.completedAt,
    required this.amountCharged,
  });

  /// The server's booking status integer — see [BookingStatus].
  final int? status;

  /// When the trip finished. Null when the payload does not say; never a
  /// sentinel (`.agent/RULES.md` §Payload policy).
  final DateTime? completedAt;

  /// What the passenger was charged. **Not** the driver's earning — see
  /// [TripEarningBasis]. Null when not reported, which is not zero.
  final num? amountCharged;
}

/// Whether a trip counts toward earnings.
///
/// Only [BookingStatus.completed]. [BookingStatus.completedAlt] (`7`) is
/// excluded while Q-1 is open: the client owner gave both `4` and `7` as
/// "completed" without explanation, and the history screen likewise treats
/// only `4` as completed. Counting `7` if it turns out to mean something else
/// would overstate a driver's earnings, and overstating money is the worse
/// error.
bool countsTowardEarnings(TripRecord trip) =>
    trip.status == BookingStatus.completed;

/// The driver's earning from one trip under [basis], or null when it cannot
/// be known.
num? tripEarning(TripRecord trip, TripEarningBasis basis) => switch (basis) {
      TripEarningBasis.fullFare => trip.amountCharged,
      TripEarningBasis.netOfPlatformCommission => null,
    };

/// The `From trips` row.
class TripEarnings {
  const TripEarnings({
    required this.count,
    required this.unknownCount,
    required this.undatedCount,
    required this.total,
    required this.currency,
  });

  /// Completed trips in the period — the `9 trips` caption. Always known,
  /// even when the money is not.
  final int count;

  /// How many of [count] have no known earning.
  final int unknownCount;

  /// Completed trips with no timestamp, which cannot be placed in a bounded
  /// period and are therefore **not** in [count]. Always zero for
  /// [EarningsPeriod.allTime]. Reported so the screen can say so rather than
  /// quietly under-count.
  final int undatedCount;

  /// The sum, or null when any trip in the period has an unknown earning.
  ///
  /// A partial sum would understate the driver's earnings while looking
  /// complete. Zero trips is a known total of `0`, not null.
  final num? total;

  final String? currency;
}

/// The `From referrals` row: `Drivers you invited` / `Passengers you invited`.
///
/// There is no referral backend (Q-4, probe-confirmed), so today every caller
/// passes null for the whole row. The type exists so the total and ordering
/// rules are written once, against both halves.
class ReferralEarnings {
  const ReferralEarnings({
    required this.fromDrivers,
    required this.fromPassengers,
    required this.currency,
  });

  final num? fromDrivers;
  final num? fromPassengers;
  final String? currency;

  /// Null when either part is unknown.
  num? get total => fromDrivers != null && fromPassengers != null
      ? fromDrivers! + fromPassengers!
      : null;
}

/// Everything the Earnings screen shows for one period.
class EarningsSummary {
  const EarningsSummary({
    required this.period,
    required this.trips,
    required this.referrals,
  });

  final EarningsPeriod period;
  final TripEarnings trips;

  /// Null when there is no referral data to report — which today is always.
  final ReferralEarnings? referrals;

  /// `Total earnings`: trip earnings plus referral rewards (copy deck §2).
  ///
  /// Null unless both halves are known **and in the same currency**. The trip
  /// half cannot stand in for the total while the referral half is missing:
  /// the label promises both. And the history screen shows trips in riel
  /// while the copy deck writes rewards in dollars — adding ៛44,000 to $3.20
  /// produces a number that means nothing.
  num? get total {
    final r = referrals;
    final tripTotal = trips.total;
    final referralTotal = r?.total;
    if (r == null || tripTotal == null || referralTotal == null) return null;
    if (trips.currency == null || trips.currency != r.currency) return null;
    return tripTotal + referralTotal;
  }
}

/// Builds the summary for [period] as of [now].
///
/// [basis] and [tripCurrency] are required with no defaults, for the reasons
/// on [TripEarningBasis]. [referrals] should already be scoped to [period] by
/// whoever supplies it.
EarningsSummary summarizeEarnings({
  required Iterable<TripRecord> trips,
  required EarningsPeriod period,
  required DateTime now,
  required TripEarningBasis basis,
  required String? tripCurrency,
  required ReferralEarnings? referrals,
}) {
  final window = windowFor(period, now);

  var count = 0;
  var unknown = 0;
  var undated = 0;
  num sum = 0;

  for (final trip in trips) {
    if (!countsTowardEarnings(trip)) continue;

    if (window != null) {
      final at = trip.completedAt;
      if (at == null) {
        undated++;
        continue;
      }
      if (!window.contains(at)) continue;
    }

    count++;
    final earning = tripEarning(trip, basis);
    if (earning == null) {
      unknown++;
    } else {
      sum += earning;
    }
  }

  return EarningsSummary(
    period: period,
    trips: TripEarnings(
      count: count,
      unknownCount: unknown,
      undatedCount: undated,
      total: unknown == 0 ? sum : null,
      currency: tripCurrency,
    ),
    referrals: referrals,
  );
}
