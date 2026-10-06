// NumberFormat comes via easy_localization's re-export, as it does for the
// wallet (`intl` is not a declared dependency).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:pu_taxi_driver/core/config/app_config.dart';
import 'package:pu_taxi_driver/core/utils/money.dart';
import 'package:pu_taxi_driver/mock/mock_mode.dart';

/// DD-54 — showing a ride's money: the fare estimate, the amount to collect,
/// the cost of a past trip.
///
/// These screens were written for whole riel: an integer price per km, and
/// `formatRielAmount` with a fixed `៛` in front. The real backend prices
/// rides in decimals (`"0.30"` a km), so a fare of 0.86 was shown as `៛1`,
/// and a running fare as `៛0` — on the payment screen that is the amount a
/// driver asks a passenger for.

/// Set by a test that needs one currency; null everywhere else.
@visibleForTesting
String? debugFareCurrency;

/// The currency fares are shown in: [AppConfig.fareCurrency], except in QA
/// mock mode, whose rides are priced in riel.
String get fareCurrency =>
    debugFareCurrency ?? (MockMode.isActive ? 'KHR' : AppConfig.fareCurrency);

/// A fare with its symbol first, in [fareCurrency]: `$0.86`, `៛9,100`.
///
/// An amount that is missing or not a number is an em dash, not a zero:
/// "we do not know" must not read as "nothing to pay".
String formatFare(dynamic amount) {
  final num? value = parseMoney(amount);
  if (value == null) return '—';
  final String currency = fareCurrency;
  final String figure =
      NumberFormat(isWholeUnitCurrency(currency) ? '#,##0' : '#,##0.00')
          .format(value.abs());
  return '${value < 0 ? '−' : ''}${currencySymbol(currency)}$figure';
}
