import 'package:tara_driver_application/core/utils/json_field.dart';
import 'package:tara_driver_application/data/models/vehical_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The policy: **fail loudly on money, degrade on display.**
///
/// The two failure modes have opposite costs. A money field that silently
/// defaults is a wrong number shown to a user as if it were right — the
/// screen gets believed. A display field that refuses to parse takes down a
/// whole list because one row lacked a name.
void main() {
  group('money fails loudly', () {
    test('a missing money field throws rather than defaulting to zero', () {
      expect(
        () => requireMoney(null, model: 'M', field: 'price'),
        throwsA(isA<MalformedPayloadException>()),
      );
    });

    test('the error names the model and the field, unlike the original', () {
      // The original was "type 'Null' is not a subtype of type 'int'", which
      // names neither. Failing loudly is only useful if it is actionable.
      try {
        requireMoney(null, model: 'SingleVehical', field: 'price');
        fail('should have thrown');
      } on MalformedPayloadException catch (e) {
        expect(e.toString(), contains('SingleVehical'));
        expect(e.toString(), contains('price'));
      }
    });

    test('numbers and numeric strings are both accepted', () {
      expect(requireMoney(3000, model: 'M', field: 'f'), 3000);
      expect(requireMoney('3000', model: 'M', field: 'f'), 3000);
      expect(requireMoney('3,000.50', model: 'M', field: 'f'), 3000.5);
    });

    test('a non-numeric string throws rather than becoming zero', () {
      expect(
        () => requireMoney('free', model: 'M', field: 'f'),
        throwsA(isA<MalformedPayloadException>()),
      );
    });

    test('requireMoneyInt truncates rather than rounding up', () {
      // Rounding money up by default is not a decision a parser should make.
      expect(requireMoneyInt(2999.9, model: 'M', field: 'f'), 2999);
    });

    test('zero is a legitimate amount and is not treated as missing', () {
      expect(requireMoney(0, model: 'M', field: 'f'), 0);
    });
  });

  group('display degrades', () {
    test('a missing string is blank, not an exception', () {
      expect(stringOrEmpty(null), '');
      expect(stringOrEmpty(42), '');
      expect(stringOrEmpty('Rickshaw'), 'Rickshaw');
    });

    test('a missing int falls back', () {
      expect(intOrDefault(null), 0);
      expect(intOrDefault('7'), 7);
      expect(intOrDefault(null, fallback: -1), -1);
    });

    test('a missing flag falls back', () {
      expect(boolOrDefault(null), isFalse);
      expect(boolOrDefault(true), isTrue);
      expect(boolOrDefault('yes'), isFalse);
    });

    test('an unusable date is null, never a sentinel', () {
      // A sentinel date is indistinguishable from a real one downstream.
      expect(dateOrNull(null), isNull);
      expect(dateOrNull('not-a-date'), isNull);
      expect(dateOrNull('2026-01-01T00:00:00Z'), isNotNull);
    });
  });

  group('the policy applied to SingleVehical', () {
    Map<String, dynamic> vehicle({Object? price = 3000}) => {
          'id': 1,
          'name': 'Rickshaw',
          'price': price,
          'minimum_fare': 2000,
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        };

    test('a missing price refuses to parse — it feeds estimateFare()', () {
      expect(
        () => SingleVehical.fromJson(vehicle(price: null)),
        throwsA(isA<MalformedPayloadException>()),
      );
    });

    test('a missing minimum fare also refuses — it is the fare floor, a '
        'documented business quirk in RULES.md', () {
      expect(
        () => SingleVehical.fromJson(vehicle()..remove('minimum_fare')),
        throwsA(isA<MalformedPayloadException>()),
      );
    });

    test('a missing name degrades to blank and the row still renders', () {
      final v = SingleVehical.fromJson(vehicle()..remove('name'));
      expect(v.name, '');
      expect(v.price, 3000);
    });

    test('missing timestamps degrade to null rather than killing the list',
        () {
      final json = vehicle()
        ..remove('created_at')
        ..remove('updated_at');
      final v = SingleVehical.fromJson(json);
      expect(v.createdAt, isNull);
      expect(v.updatedAt, isNull);
    });

    test('the wrapper degrades even when the payload omits everything', () {
      final m = VehicalTypeEntities.fromJson({});
      expect(m.data, isEmpty);
      expect(m.message, '');
      expect(m.status, isFalse);
    });
  });
}
