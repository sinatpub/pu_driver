import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/utils/fare_estimate.dart';
import 'package:pu_taxi_driver/core/utils/fare_money.dart';
import 'package:pu_taxi_driver/core/utils/json_field.dart';
import 'package:pu_taxi_driver/data/models/vehical_model.dart';

/// DD-54 — ride money. The backend prices rides in decimals ("0.30" a km,
/// "0.50" minimum); the app was written for whole riel and showed a running
/// fare as `៛0` and would have shown a fare of 0.86 as `៛1`.
void main() {
  tearDown(() => debugFareCurrency = null);

  group('formatFare', () {
    test('the default is dollars, with two decimals', () {
      expect(fareCurrency, 'USD');
      expect(formatFare(0.86), r'$0.86');
      expect(formatFare('0.50'), r'$0.50');
      expect(formatFare(0.5), r'$0.50');
      expect(formatFare(12), r'$12.00');
      expect(formatFare('1,234.5'), r'$1,234.50');
    });

    test('a fare is never rounded to a different amount', () {
      // The old riel format turned 0.86 into 1 and 0.36 into 0.
      expect(formatFare(0.36), r'$0.36');
      expect(formatFare(0.004), r'$0.00');
      expect(formatFare(0.995), isNot(r'$0.00'));
    });

    test('riel, where that is the currency, stays in whole units', () {
      debugFareCurrency = 'KHR';
      expect(formatFare(9100), '៛9,100');
      expect(formatFare('12000'), '៛12,000');
    });

    test('an unknown amount is a dash, not zero', () {
      expect(formatFare(null), '—');
      expect(formatFare(''), '—');
      expect(formatFare('abc'), '—');
    });
  });

  group('estimateFare with decimal prices', () {
    test('the first kilometre costs the minimum fare', () {
      expect(
        estimateFare(distanceKm: 0.4, pricePerKm: 0.3, minimumFare: 0.5),
        0.5,
      );
      expect(
        estimateFare(distanceKm: 1.0, pricePerKm: 0.3, minimumFare: 0.5),
        0.5,
      );
    });

    test('each kilometre after it adds the price per km', () {
      // The trip in the bug report: 1.2 km driven.
      expect(
        estimateFare(distanceKm: 1.2, pricePerKm: 0.3, minimumFare: 0.5),
        closeTo(0.56, 1e-9),
      );
      expect(
        formatFare(
          estimateFare(distanceKm: 1.2, pricePerKm: 0.3, minimumFare: 0.5),
        ),
        r'$0.56',
      );
      expect(
        estimateFare(distanceKm: 6, pricePerKm: 0.3, minimumFare: 0.5),
        closeTo(2.0, 1e-9),
      );
    });

    test('whole riel prices still work', () {
      expect(
        estimateFare(distanceKm: 3, pricePerKm: 1200, minimumFare: 4000),
        6400,
      );
    });
  });

  group('GET /taxi/get-type-vehicle, as the backend sent it 2026-10-06', () {
    final Map<String, dynamic> body = <String, dynamic>{
      'data': <dynamic>[
        <String, dynamic>{
          'id': 1,
          'name': 'Moto',
          'price': '0.30',
          'minimum_fare': '0.50',
          'commission': '10.00',
          'image': '',
          'created_at': '2026-08-31 14:41:13',
          'updated_at': '2026-08-31 14:41:13',
        },
      ],
      'color': <dynamic>[
        <String, dynamic>{
          'id': 1,
          'name': 'White',
          'created_at': '2026-08-31T07:41:12.000000Z',
          'updated_at': '2026-08-31T07:41:12.000000Z',
        },
      ],
      'message': 'success',
      'status': true,
    };

    test('parses, with the prices as the decimals they are', () {
      // This list used to fail whole: `type 'String' is not a subtype of
      // type 'int'`, which left the trip screen without a minimum fare.
      final VehicalTypeEntities model = VehicalTypeEntities.fromJson(body);

      expect(model.data, hasLength(1));
      expect(model.data.single.name, 'Moto');
      expect(model.data.single.price, 0.3);
      expect(model.data.single.minimumFare, 0.5);
      expect(model.color.single.name, 'White');
      expect(model.color.single.colorCode, isNull);
    });

    test('a price that is not a number still refuses, by name', () {
      final Map<String, dynamic> broken = <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{'id': 1, 'name': 'Moto', 'price': 'free'},
        ],
      };
      expect(
        () => VehicalTypeEntities.fromJson(broken),
        throwsA(isA<MalformedPayloadException>()),
      );
    });
  });
}
