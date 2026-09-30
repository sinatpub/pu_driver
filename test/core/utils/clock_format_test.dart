import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/utils/clock_format.dart';

void main() {
  test('minutes and seconds under an hour', () {
    expect(formatClock(const Duration(seconds: 7)), '0:07');
    expect(formatClock(const Duration(minutes: 12, seconds: 40)), '12:40');
  });

  test('hours, then zero-padded minutes, past an hour', () {
    expect(formatClock(const Duration(hours: 1, minutes: 2, seconds: 10)),
        '1:02:10');
  });

  test('a negative duration reads as zero', () {
    expect(formatClock(const Duration(seconds: -5)), '0:00');
  });
}
