import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/app/funtion_convert.dart';

/// Renamed from `formatToTwoDecimalPlaces`, which claimed the opposite of what
/// it did. These pin the behaviour so the name and the function cannot drift
/// apart again — the old name is what led the wallet screen to use this for
/// USD, rendering $0.99 as "1".
void main() {
  group('formatRielAmount', () {
    test('renders whole riel with no decimal part', () {
      expect(formatRielAmount('125.50'), '126');
      expect(formatRielAmount('125.49'), '125');
      expect(formatRielAmount('0.99'), '1');
    });

    test('groups thousands', () {
      expect(formatRielAmount('20000'), '20,000');
      expect(formatRielAmount('1200.5'), '1,201');
    });

    test('zero renders as zero', () {
      expect(formatRielAmount('0'), '0');
    });

    test('a negative amount keeps its sign', () {
      expect(formatRielAmount('-4000'), '-4,000');
    });

    test('unparseable input yields 0 — original behaviour, preserved '
        'deliberately because nine screens display this', () {
      expect(formatRielAmount(''), '0');
      expect(formatRielAmount('not a number'), '0');
    });
  });
}
