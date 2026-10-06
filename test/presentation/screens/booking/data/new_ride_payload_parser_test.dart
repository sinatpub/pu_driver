import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/data/new_ride_payload_parser.dart';

Map<String, dynamic> _socketShapedPayload({
  Object? bookingId = 501,
  Object? bookingCode = 9001,
  Object? passengerId = 42,
  Object? vehicleType = 2,
  Object? vehiclePrice = 1200,
  Object? timeout = 45,
  Map<String, dynamic>? passenger,
  Map<String, dynamic>? location,
  Map<String, dynamic>? destination,
}) {
  return {
    'booking_id': bookingId,
    'booking_code': bookingCode,
    'passengerId': passengerId,
    'vehicleType': vehicleType,
    'vehiclePrice': vehiclePrice,
    'timeout': timeout,
    'passenger': passenger ??
        {'name': 'Sinat', 'phone': '012345678', 'profile': 'https://x/p.png'},
    'location': location ?? {'latitude': 11.55, 'longitude': 104.9},
    'destination': destination ?? {'latitude': 11.6, 'longitude': 104.95},
  };
}

void main() {
  group('parseNewRideArgs', () {
    test('parses a fully-populated socket-shaped payload (nested maps)', () {
      final args = parseNewRideArgs(_socketShapedPayload());

      expect(args.bookingId, 501);
      expect(args.bookingCode, 9001);
      expect(args.passengerId, 42);
      expect(args.typeVehicleId, 2);
      expect(args.pricrVehicle, 1200);
      expect(args.timeOut, 45);
      expect(args.namePassanger, 'Sinat');
      expect(args.phonePassanger, '012345678');
      expect(args.imagePassanger, 'https://x/p.png');
      expect(args.latPassenger, 11.55);
      expect(args.lngPassenger, 104.9);
      expect(args.desLatPassenger, 11.6);
      expect(args.desLngPassenger, 104.95);
      // Not carried by the payload — always these fixed values, same as
      // both original call sites hardcoded.
      expect(args.processStepBook, 1);
      expect(args.refreshApp, isFalse);
      expect(args.startTime, '');
    });

    test('parses a fully-populated FCM-shaped payload (JSON-encoded strings)',
        () {
      final data = {
        'booking_id': '501',
        'booking_code': '9001',
        'passengerId': '42',
        'vehicleType': '2',
        'vehiclePrice': '1200',
        'timeout': '45',
        'passenger': jsonEncode({
          'name': 'Sinat',
          'phone': '012345678',
          'profile': 'https://x/p.png'
        }),
        'location': jsonEncode({'latitude': 11.55, 'longitude': 104.9}),
        'destination': jsonEncode({'latitude': 11.6, 'longitude': 104.95}),
      };

      final args = parseNewRideArgs(data);

      expect(args.bookingId, 501);
      expect(args.bookingCode, 9001);
      expect(args.passengerId, 42);
      expect(args.namePassanger, 'Sinat');
      expect(args.latPassenger, 11.55);
      expect(args.desLatPassenger, 11.6);
    });

    group(
        'booking identifiers are required — a missing or unparseable one fails the parse',
        () {
      for (final field in ['booking_id', 'booking_code', 'passengerId']) {
        test('throws when "$field" is missing', () {
          final data = _socketShapedPayload();
          data.remove(field);
          expect(() => parseNewRideArgs(data),
              throwsA(isA<NewRideParseException>()));
        });

        test('throws when "$field" is not a number', () {
          final data = _socketShapedPayload();
          data[field] = 'not-a-number';
          expect(() => parseNewRideArgs(data),
              throwsA(isA<NewRideParseException>()));
        });
      }

      test(
          'accepts identifiers sent as numeric strings, like the socket sometimes does',
          () {
        final data = _socketShapedPayload(
            bookingId: '501', bookingCode: '9001', passengerId: '42');
        final args = parseNewRideArgs(data);
        expect(args.bookingId, 501);
        expect(args.bookingCode, 9001);
        expect(args.passengerId, 42);
      });
    });

    group(
        'everything else degrades to a safe default instead of dropping the whole request',
        () {
      test('missing vehicleType/vehiclePrice default to 0', () {
        final data = _socketShapedPayload()
          ..remove('vehicleType')
          ..remove('vehiclePrice');
        final args = parseNewRideArgs(data);
        expect(args.typeVehicleId, 0);
        expect(args.pricrVehicle, 0);
      });

      test(
          'missing timeout defaults to 30, matching home_screen.dart\'s own fallback',
          () {
        final data = _socketShapedPayload()..remove('timeout');
        expect(parseNewRideArgs(data).timeOut, 30);
      });

      test('missing passenger map defaults every field to an empty string', () {
        final data = _socketShapedPayload()..remove('passenger');
        final args = parseNewRideArgs(data);
        expect(args.namePassanger, '');
        expect(args.phonePassanger, '');
        expect(args.imagePassanger, '');
      });

      test('missing location map defaults the pickup position to 0,0', () {
        final data = _socketShapedPayload()..remove('location');
        final args = parseNewRideArgs(data);
        expect(args.latPassenger, 0.0);
        expect(args.lngPassenger, 0.0);
      });

      test('missing destination map leaves desLat/desLngPassenger null, not 0',
          () {
        final data = _socketShapedPayload()..remove('destination');
        final args = parseNewRideArgs(data);
        expect(args.desLatPassenger, isNull);
        expect(args.desLngPassenger, isNull);
      });

      test(
          'an unparseable (non-JSON) FCM passenger string is treated as missing, not a crash',
          () {
        final data = _socketShapedPayload();
        data['passenger'] = 'not valid json {{{';
        final args = parseNewRideArgs(data);
        expect(args.namePassanger, '');
      });
    });
  });

  // What the `newRide` socket event really carried on 2026-10-06: the
  // request and a short string, so the handler was given a two-item list.
  group('parseNewRideEvent', () {
    Map<String, dynamic> realRequest() => <String, dynamic>{
          'booking_code': 1791280683,
          'booking_id': 1,
          'passengerId': 3,
          'location': <String, dynamic>{
            'latitude': 11.52590516098051,
            'longitude': 104.92335179820657,
          },
          'vehiclePrice': 0.3,
          'vehicleType': 1,
          'timeout': 15,
          'passenger': <String, dynamic>{
            'name': 'Dummy Passenger',
            'phone': '+855900000003',
            'profile': null,
          },
          'destination': <String, dynamic>{
            'latitude': null,
            'longitude': null,
          },
        };

    test('the real event: a list of the request and a string', () {
      final args = parseNewRideEvent(<dynamic>[realRequest(), 'Q4GfXZP']);

      expect(args.bookingId, 1);
      expect(args.bookingCode, 1791280683);
      expect(args.passengerId, 3);
      expect(args.timeOut, 15);
      expect(args.typeVehicleId, 1);
      expect(args.namePassanger, 'Dummy Passenger');
      expect(args.phonePassanger, '+855900000003');
      // `profile: null` is no photo, not the text "null".
      expect(args.imagePassanger, '');
      expect(args.latPassenger, 11.52590516098051);
      expect(args.lngPassenger, 104.92335179820657);
      // A destination of nulls is "not chosen yet".
      expect(args.desLatPassenger, isNull);
      expect(args.desLngPassenger, isNull);
    });

    test('a request sent on its own still parses', () {
      expect(parseNewRideEvent(realRequest()).bookingId, 1);
    });

    test('the request is found wherever it sits among the arguments', () {
      expect(
        parseNewRideEvent(<dynamic>['Q4GfXZP', realRequest()]).bookingId,
        1,
      );
      expect(
        parseNewRideEvent(<dynamic>[
          <dynamic>[realRequest()],
        ]).bookingId,
        1,
      );
    });

    test('a request sent as JSON text parses too', () {
      expect(
        parseNewRideEvent(<dynamic>[jsonEncode(realRequest())]).bookingId,
        1,
      );
    });

    test('an event with no request in it fails with a reason', () {
      for (final dynamic event in <dynamic>[
        null,
        'Q4GfXZP',
        <dynamic>[],
        <dynamic>['Q4GfXZP', 7],
      ]) {
        expect(
          () => parseNewRideEvent(event),
          throwsA(isA<NewRideParseException>()),
          reason: 'event: $event',
        );
      }
    });

    test('a request without a booking id still fails loudly', () {
      final Map<String, dynamic> request = realRequest()..remove('booking_id');
      expect(
        () => parseNewRideEvent(<dynamic>[request, 'Q4GfXZP']),
        throwsA(isA<NewRideParseException>()),
      );
    });

    test('the price per km keeps its decimals (DD-54)', () {
      expect(
        parseNewRideEvent(<dynamic>[realRequest(), 'Q4GfXZP']).pricrVehicle,
        0.3,
      );
    });

    test('a price sent as text reads the same; none at all is 0, not known',
        () {
      final Map<String, dynamic> asText = realRequest()
        ..['vehiclePrice'] = '0.30';
      expect(parseNewRideEvent(asText).pricrVehicle, 0.3);

      final Map<String, dynamic> missing = realRequest()
        ..remove('vehiclePrice');
      expect(parseNewRideEvent(missing).pricrVehicle, 0);
    });
  });
}
