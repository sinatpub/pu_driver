import 'package:pu_taxi_driver/core/utils/money.dart';

/// DD-51 — a trip paid partly with the passenger's ride credit.
///
/// The passenger's invite rewards are ride credit. On a cash trip the driver
/// collects only the fare less the credit; the credited part is paid into the
/// driver's wallet. Commission is on the full fare. On a wallet or card trip
/// the platform holds the whole fare anyway, so the credit changes nothing
/// the driver does and is not shown.
///
/// Pure, like the wallet's money rules: the screen and the trip detail read
/// the same answer from here.
class PaymentSplit {
  const PaymentSplit({
    required this.fare,
    required this.credit,
    required this.cash,
  });

  /// The full fare, or null when the server sent none that parses.
  final num? fare;

  /// Ride credit that counts for the driver: zero unless this is a cash trip
  /// with credit; never more than the fare.
  final num credit;

  /// Cash to take from the passenger. Equal to [fare] with no credit; null
  /// when the fare is unknown or the trip is not paid in cash.
  final num? cash;

  /// The driver collects less cash because of credit.
  bool get usesCredit => credit > 0;

  /// Credit covered the whole fare: there is no cash to collect.
  bool get fullyCredited => usesCredit && cash == 0;
}

/// Splits [amount] (the fare) by [rideCredit] for a trip paid with
/// [paidInCash]. Credit below zero counts as none; credit above the fare
/// counts as the fare.
PaymentSplit paymentSplit({
  required dynamic amount,
  required dynamic rideCredit,
  required bool paidInCash,
}) {
  final num? fare = parseMoney(amount);
  if (fare == null || !paidInCash) {
    return PaymentSplit(fare: fare, credit: 0, cash: paidInCash ? fare : null);
  }
  final num asked = parseMoney(rideCredit) ?? 0;
  final num credit = asked <= 0 ? 0 : (asked > fare ? fare : asked);
  return PaymentSplit(fare: fare, credit: credit, cash: fare - credit);
}
