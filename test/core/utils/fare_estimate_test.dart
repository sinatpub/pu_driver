import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/utils/fare_estimate.dart';

void main() {
  group('estimateFare', () {
    test('returns the minimum fare for a trip under 1km', () {
      final fee = estimateFare(
        distanceKm: 0.4,
        pricePerKm: 2000,
        minimumFare: 5000,
      );
      expect(fee, 5000.0);
    });

    test('returns the minimum fare for a trip of exactly 1km', () {
      final fee = estimateFare(
        distanceKm: 1.0,
        pricePerKm: 2000,
        minimumFare: 5000,
      );
      expect(fee, 5000.0);
    });

    test('charges pricePerKm for each km past the first', () {
      final fee = estimateFare(
        distanceKm: 3.0,
        pricePerKm: 2000,
        minimumFare: 5000,
      );
      expect(fee, 9000.0);
    });

    test('handles a fractional distance past the first km', () {
      final fee = estimateFare(
        distanceKm: 2.5,
        pricePerKm: 2000,
        minimumFare: 5000,
      );
      expect(fee, 8000.0);
    });

    test('the meters-accumulated and km-computed paths agree on the same distance', () {
      const totalDistanceCountMeters = 4200.0; // GPS dead-reckoning path
      const totalDistanceKm = 4.2; // Google Directions path

      final feeFromMeters = estimateFare(
        distanceKm: totalDistanceCountMeters / 1000,
        pricePerKm: 1500,
        minimumFare: 4000,
      );
      final feeFromKm = estimateFare(
        distanceKm: totalDistanceKm,
        pricePerKm: 1500,
        minimumFare: 4000,
      );

      expect(feeFromMeters, feeFromKm);
    });

    test('zero distance still returns the minimum fare', () {
      final fee = estimateFare(
        distanceKm: 0.0,
        pricePerKm: 2000,
        minimumFare: 5000,
      );
      expect(fee, 5000.0);
    });
  });
}
