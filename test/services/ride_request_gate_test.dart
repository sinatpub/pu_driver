import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/services/socket_service.dart';

/// Audit D-3 — a `newRide` reaches the driver unless the app has read their
/// status and has them offline.
void main() {
  test('an online driver gets the request', () {
    expect(acceptsRideRequests(statusChecked: true, isOnline: true), isTrue);
  });

  test('an offline driver does not', () {
    expect(acceptsRideRequests(statusChecked: true, isOnline: false), isFalse);
  });

  test('before the status is read, the request is shown as before', () {
    expect(acceptsRideRequests(statusChecked: false, isOnline: false), isTrue);
  });
}
