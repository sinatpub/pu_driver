import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/utils/money.dart';

/// N-01 (docs/12). Every monetary field on WalletModel is `dynamic` because
/// the backend is inconsistent about it. This is the single coercion point,
/// and .agent/RULES.md puts money in mandatory-test territory.
void main() {
  group('parseMoney', () {
    test('a JSON number comes through unchanged', () {
      expect(parseMoney(12.5), 12.5);
      expect(parseMoney(0), 0);
      expect(parseMoney(1200), 1200);
    });

    test('a quoted numeric string is read as a number', () {
      // The backend sends balance as a string on some responses.
      expect(parseMoney('12.50'), 12.5);
      expect(parseMoney('0'), 0);
    });

    test('thousands separators do not defeat it', () {
      expect(parseMoney('1,200.50'), 1200.5);
    });

    test('surrounding whitespace is tolerated', () {
      expect(parseMoney('  12.50  '), 12.5);
    });

    test('a negative balance is preserved — drivers can be in debt', () {
      // `debted` is a real field on this model; clamping here would hide it.
      expect(parseMoney(-40), -40);
      expect(parseMoney('-40.25'), -40.25);
    });

    test('missing means null, NOT zero', () {
      // Showing a driver $0.00 because a field failed to parse is worse than
      // showing them nothing at all.
      expect(parseMoney(null), isNull);
      expect(parseMoney(''), isNull);
      expect(parseMoney('   '), isNull);
    });

    test('unparseable input is null rather than an exception', () {
      expect(parseMoney('not money'), isNull);
      expect(parseMoney(true), isNull);
      expect(parseMoney({'amount': 1}), isNull);
      expect(parseMoney(['1']), isNull);
    });

    test('parseMoneyAsDouble keeps null null', () {
      expect(parseMoneyAsDouble(null), isNull);
      expect(parseMoneyAsDouble(12), 12.0);
      expect(parseMoneyAsDouble('12'), 12.0);
    });
  });
}
