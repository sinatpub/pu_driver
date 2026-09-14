import 'package:tara_driver_application/core/utils/json_field.dart';
import 'package:tara_driver_application/core/utils/money.dart';
import 'package:tara_driver_application/features/earnings/domain/earnings.dart';
import 'package:tara_driver_application/features/history/data/models/history_driver_info_model.dart';

/// N-09 (docs/12) — adapting `/taxi-driver/history-drive-info` rows into the
/// earnings rules' input.
///
/// Kept out of `domain/` so the rules stay free of data models
/// (`.agent/skills/architecture.md`: domain code knows nothing about HTTP).

/// The currency trip amounts are in.
///
/// The history payload carries no currency. The history card and the
/// calculate-fee screen both hardcode `៛`, so this matches what the driver
/// already sees for the same trips. If the payload ever gains a currency,
/// read it instead.
const String kHistoryTripCurrency = 'KHR';

/// One history row as a [TripRecord].
///
/// **Amount: `payment.amount`, not `fare`.** The server recomputes the fare on
/// `complete-drive` (Q-2), and `payment.amount` is the figure the history card
/// and the calculate-fee screen display as what was charged. Whether the
/// booking's own `fare` is that final figure or the pre-trip estimate is not
/// verified, so it is not used. A completed trip with no payment reports its
/// amount as unknown, not as zero.
///
/// **Time: `end_time`, then `payment.created_at`.** A payment is created when
/// the trip completes, so it is a reasonable second witness. `updated_at` is
/// deliberately not used: a row can be updated long after the trip.
TripRecord tripRecordFromHistory(DataHistory row) => TripRecord(
      status: row.status,
      completedAt:
          dateOrNull(row.endTime) ?? dateOrNull(row.payment?.createdAt),
      amountCharged: parseMoney(row.payment?.amount),
    );
