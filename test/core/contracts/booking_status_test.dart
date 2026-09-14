import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/contracts/booking_status.dart';

void main() {
  test('the assumed mapping matches docs/05 §2 (Q-1, client-owner-supplied)',
      () {
    expect(BookingStatus.request, 1);
    expect(BookingStatus.accepted, 2);
    expect(BookingStatus.startRide, 3);
    expect(BookingStatus.completed, 4);
    expect(BookingStatus.cancel, 5);
    expect(BookingStatus.pendingPayment, 6);
    expect(BookingStatus.completedAlt, 7);
    expect(BookingStatus.arrived, 8);
  });

  test('completed and completedAlt are kept distinct, not merged', () {
    expect(BookingStatus.completed, isNot(BookingStatus.completedAlt));
  });
}
