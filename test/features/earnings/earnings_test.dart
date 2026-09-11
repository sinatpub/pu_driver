import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/contracts/booking_status.dart';
import 'package:tara_driver_application/features/earnings/domain/earnings.dart';
import 'package:tara_driver_application/features/earnings/earnings_from_history.dart';
import 'package:tara_driver_application/features/history/data/models/history_driver_info_model.dart';

/// N-09 (docs/12) — the earnings dashboard's rules. Money, so mandatory
/// territory per `.agent/RULES.md`.
void main() {
  // Friday 11 September 2026, mid-afternoon, local time.
  final now = DateTime(2026, 9, 11, 15, 30);

  TripRecord completed(DateTime? at, num? amount) => TripRecord(
        status: BookingStatus.completed,
        completedAt: at,
        amountCharged: amount,
      );

  EarningsSummary summarize(
    List<TripRecord> trips, {
    EarningsPeriod period = EarningsPeriod.allTime,
    TripEarningBasis basis = TripEarningBasis.fullFare,
    String? currency = 'KHR',
    ReferralEarnings? referrals,
  }) =>
      summarizeEarnings(
        trips: trips,
        period: period,
        now: now,
        basis: basis,
        tripCurrency: currency,
        referrals: referrals,
      );

  group('period windows', () {
    test('today is the local calendar day, end exclusive', () {
      final w = windowFor(EarningsPeriod.today, now)!;
      expect(w.start, DateTime(2026, 9, 11));
      expect(w.end, DateTime(2026, 9, 12));
      expect(w.contains(DateTime(2026, 9, 11)), isTrue);
      expect(w.contains(DateTime(2026, 9, 12)), isFalse,
          reason: 'midnight belongs to the next day');
    });

    test('a UTC timestamp is placed by instant, not by its digits', () {
      // The backend may send UTC; the window is local. Same moment, same
      // answer, whatever timezone the test runs in.
      final w = windowFor(EarningsPeriod.today, now)!;
      expect(w.contains(DateTime(2026, 9, 11).toUtc()), isTrue);
      expect(w.contains(DateTime(2026, 9, 12).toUtc()), isFalse);
    });

    test('this week starts on the placeholder day (Monday)', () {
      expect(kWeekStartDayPlaceholder, DateTime.monday);
      final w = windowFor(EarningsPeriod.thisWeek, now)!;
      expect(w.start, DateTime(2026, 9, 7));
      expect(w.end, DateTime(2026, 9, 14));
    });

    test('on the first day of the week, the week starts today', () {
      final monday = DateTime(2026, 9, 7, 0, 1);
      expect(windowFor(EarningsPeriod.thisWeek, monday)!.start,
          DateTime(2026, 9, 7));
    });

    test('on the last day of the week, it still belongs to that week', () {
      final sunday = DateTime(2026, 9, 13, 23, 59);
      expect(windowFor(EarningsPeriod.thisWeek, sunday)!.start,
          DateTime(2026, 9, 7));
    });

    test('a week can span two months', () {
      final w = windowFor(EarningsPeriod.thisWeek, DateTime(2026, 10, 1))!;
      expect(w.start, DateTime(2026, 9, 28));
      expect(w.end, DateTime(2026, 10, 5));
    });

    test('this month runs to the first of the next, across a year end', () {
      final w = windowFor(EarningsPeriod.thisMonth, DateTime(2026, 12, 31))!;
      expect(w.start, DateTime(2026, 12));
      expect(w.end, DateTime(2027, 1));
    });

    test('all time is unbounded', () {
      expect(windowFor(EarningsPeriod.allTime, now), isNull);
    });
  });

  group('which trips count', () {
    test('only completed trips', () {
      final s = summarize([
        completed(now, 10000),
        TripRecord(
            status: BookingStatus.cancel, completedAt: now, amountCharged: 5000),
        TripRecord(
            status: BookingStatus.startRide,
            completedAt: now,
            amountCharged: 5000),
        TripRecord(
            status: BookingStatus.pendingPayment,
            completedAt: now,
            amountCharged: 5000),
      ]);
      expect(s.trips.count, 1);
      expect(s.trips.total, 10000);
    });

    test('status 7 is excluded while Q-1 is open', () {
      // Given as "completed" too, unexplained. Counting it if it means
      // something else would overstate a driver's earnings.
      final s = summarize([
        TripRecord(
            status: BookingStatus.completedAlt,
            completedAt: now,
            amountCharged: 5000),
      ]);
      expect(s.trips.count, 0);
      expect(s.trips.total, 0);
    });

    test('a null status does not count', () {
      final s = summarize(
          [TripRecord(status: null, completedAt: now, amountCharged: 5000)]);
      expect(s.trips.count, 0);
    });

    test('trips outside the period are left out', () {
      final s = summarize([
        completed(DateTime(2026, 9, 11, 9), 10000),
        completed(DateTime(2026, 9, 10, 23, 59), 7000),
        completed(DateTime(2026, 8, 31), 3000),
      ], period: EarningsPeriod.today);
      expect(s.trips.count, 1);
      expect(s.trips.total, 10000);
    });

    test('each period sums its own trips', () {
      final trips = [
        completed(DateTime(2026, 9, 11, 9), 1),
        completed(DateTime(2026, 9, 8), 10),
        completed(DateTime(2026, 9, 2), 100),
        completed(DateTime(2025, 1, 1), 1000),
      ];
      expect(summarize(trips, period: EarningsPeriod.today).trips.total, 1);
      expect(summarize(trips, period: EarningsPeriod.thisWeek).trips.total, 11);
      expect(
          summarize(trips, period: EarningsPeriod.thisMonth).trips.total, 111);
      expect(
          summarize(trips, period: EarningsPeriod.allTime).trips.total, 1111);
    });
  });

  group('trip totals', () {
    test('no trips is a known zero, not unknown', () {
      final s = summarize(const []);
      expect(s.trips.count, 0);
      expect(s.trips.total, 0);
      expect(s.trips.total, isNotNull);
    });

    test('one unknown amount makes the total unknown, not partial', () {
      // A partial sum would understate while looking complete.
      final s = summarize([completed(now, 10000), completed(now, null)]);
      expect(s.trips.total, isNull);
      expect(s.trips.count, 2, reason: 'the count is still known');
      expect(s.trips.unknownCount, 1);
    });

    test('a zero-amount trip is a real zero', () {
      final s = summarize([completed(now, 0), completed(now, 5000)]);
      expect(s.trips.total, 5000);
      expect(s.trips.unknownCount, 0);
    });

    test('fractional amounts are summed exactly as given', () {
      final s = summarize([completed(now, 12.5), completed(now, 0.25)]);
      expect(s.trips.total, 12.75);
    });

    test('the currency is carried through', () {
      expect(summarize(const []).trips.currency, 'KHR');
    });
  });

  group('the trip-earning basis (open business question)', () {
    test('full fare: the amount charged is the earning', () {
      final trip = completed(now, 10000);
      expect(tripEarning(trip, TripEarningBasis.fullFare), 10000);
    });

    test('net of commission: unknown, because no payload carries it', () {
      final trip = completed(now, 10000);
      expect(tripEarning(trip, TripEarningBasis.netOfPlatformCommission),
          isNull);
    });

    test('net of commission: trips are counted, money is not guessed', () {
      final s = summarize(
        [completed(now, 10000), completed(now, 8000)],
        basis: TripEarningBasis.netOfPlatformCommission,
      );
      expect(s.trips.count, 2);
      expect(s.trips.unknownCount, 2);
      expect(s.trips.total, isNull);
    });
  });

  group('undated trips', () {
    test('count toward all time', () {
      final s = summarize([completed(null, 5000)]);
      expect(s.trips.count, 1);
      expect(s.trips.total, 5000);
      expect(s.trips.undatedCount, 0);
    });

    test('are left out of a bounded period and reported, not hidden', () {
      final s = summarize(
        [completed(now, 10000), completed(null, 5000)],
        period: EarningsPeriod.today,
      );
      expect(s.trips.count, 1);
      expect(s.trips.total, 10000);
      expect(s.trips.undatedCount, 1);
    });

    test('an undated cancelled trip is not reported as undated', () {
      final s = summarize([
        TripRecord(
            status: BookingStatus.cancel, completedAt: null, amountCharged: 1),
      ], period: EarningsPeriod.today);
      expect(s.trips.undatedCount, 0);
    });
  });

  group('total earnings', () {
    const usdReferrals = ReferralEarnings(
        fromDrivers: 3.00, fromPassengers: 0.20, currency: 'USD');

    test('unknown while there is no referral data — which is today', () {
      // The label promises trips plus referrals; trips alone is not it.
      final s = summarize([completed(now, 10000)]);
      expect(s.referrals, isNull);
      expect(s.total, isNull);
    });

    test('the sum when both halves are known and share a currency', () {
      final s = summarize(
        [completed(now, 44.00)],
        currency: 'USD',
        referrals: usdReferrals,
      );
      // The layout system's worked example: $44.00 + $3.20 = $47.20.
      expect(s.total, closeTo(47.20, 1e-9));
    });

    test('unknown when the currencies differ', () {
      // Riel trips plus dollar rewards is a number that means nothing.
      final s = summarize([completed(now, 44000)], referrals: usdReferrals);
      expect(s.total, isNull);
    });

    test('unknown when the trip currency is not known', () {
      final s = summarize([completed(now, 44)],
          currency: null,
          referrals: const ReferralEarnings(
              fromDrivers: 1, fromPassengers: 1, currency: null));
      expect(s.total, isNull);
    });

    test('unknown when the trip half is unknown', () {
      final s = summarize(
        [completed(now, null)],
        currency: 'USD',
        referrals: usdReferrals,
      );
      expect(s.total, isNull);
    });

    test('unknown when either referral part is unknown', () {
      const partial = ReferralEarnings(
          fromDrivers: 3.00, fromPassengers: null, currency: 'USD');
      expect(partial.total, isNull);
      final s =
          summarize([completed(now, 44)], currency: 'USD', referrals: partial);
      expect(s.total, isNull);
    });

    test('zero referrals is a real zero', () {
      const none =
          ReferralEarnings(fromDrivers: 0, fromPassengers: 0, currency: 'USD');
      expect(none.total, 0);
      final s =
          summarize([completed(now, 44)], currency: 'USD', referrals: none);
      expect(s.total, 44);
    });
  });

  group('the product position', () {
    test('trips come before referrals in the breakdown, always', () {
      expect(kEarningsBreakdownOrder,
          [EarningsSource.trips, EarningsSource.referrals]);
    });

    test('the period selector has the copy deck\'s four periods, in order', () {
      expect(EarningsPeriod.values, [
        EarningsPeriod.today,
        EarningsPeriod.thisWeek,
        EarningsPeriod.thisMonth,
        EarningsPeriod.allTime,
      ]);
    });
  });

  group('adapting a history row', () {
    DataHistory row(Map<String, dynamic> overrides) => DataHistory.fromJson({
          'id': 1,
          'status': BookingStatus.completed,
          ...overrides,
        });

    test('reads the charged amount from payment, parsing its string', () {
      final r = tripRecordFromHistory(row({
        'fare': '9999',
        'payment': {'amount': '12,000', 'created_at': '2026-09-11 09:00:00'},
      }));
      expect(r.amountCharged, 12000, reason: 'payment.amount, not fare');
      expect(r.status, BookingStatus.completed);
    });

    test('no payment means an unknown amount, not zero', () {
      final r = tripRecordFromHistory(row({'fare': '9999'}));
      expect(r.amountCharged, isNull);
    });

    test('dates the trip by end_time first', () {
      final r = tripRecordFromHistory(row({
        'end_time': '2026-09-11 09:00:00',
        'payment': {'amount': '1', 'created_at': '2026-09-11 10:00:00'},
      }));
      expect(r.completedAt, DateTime(2026, 9, 11, 9));
    });

    test('falls back to the payment time when end_time is missing', () {
      final r = tripRecordFromHistory(row({
        'payment': {'amount': '1', 'created_at': '2026-09-11 10:00:00'},
      }));
      expect(r.completedAt, DateTime(2026, 9, 11, 10));
    });

    test('never falls back to updated_at', () {
      // A row can be updated long after the trip.
      final r = tripRecordFromHistory(row({'updated_at': '2026-09-11 11:00:00'}));
      expect(r.completedAt, isNull);
    });

    test('an unparseable end_time falls through rather than throwing', () {
      final r = tripRecordFromHistory(row({
        'end_time': 'not a date',
        'payment': {'amount': '1', 'created_at': '2026-09-11 10:00:00'},
      }));
      expect(r.completedAt, DateTime(2026, 9, 11, 10));
    });

    test('trip amounts are in riel, matching the history screen', () {
      expect(kHistoryTripCurrency, 'KHR');
    });
  });
}
