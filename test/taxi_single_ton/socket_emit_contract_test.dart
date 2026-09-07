import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/taxi_single_ton/init_socket.dart';

/// Characterization tests for the *payloads* the driver puts on the wire, and
/// for the reconnection policy F-03 fixed (`.agent/TODO.md` Recommended #2).
///
/// Payload keys matter as much as event names: the server relays these through
/// **verbatim** to the passenger app (confirmed live 2026-09-07,
/// `.agent/PROGRESS.md`), so a renamed key here silently breaks the passenger
/// with nothing failing to compile on either side.
///
/// Per `.agent/skills/testing.md` these use a hand-written recording subclass,
/// not a mocking framework. `emitEvent` is the choke point every emit below
/// flows through, so overriding it captures the real call without a socket.
class _RecordingDriverSocketService extends DriverSocketService {
  _RecordingDriverSocketService() : super.forTesting();

  final List<({String event, dynamic data})> emitted = [];

  @override
  void emitEvent(String event, dynamic data) {
    emitted.add((event: event, data: data));
  }

  ({String event, dynamic data}) get only {
    expect(emitted, hasLength(1), reason: 'expected exactly one emit');
    return emitted.single;
  }
}

void main() {
  late _RecordingDriverSocketService socket;

  setUp(() => socket = _RecordingDriverSocketService());

  group('reconnection policy (F-03)', () {
    test('websocket-only transport, matching the server probe', () {
      expect(buildSocketOptions()['transports'], ['websocket']);
    });

    test('backs off 2s -> 30s instead of the old flat 60s wait', () {
      expect(buildSocketOptions()['reconnectionDelay'], 2000);
      expect(buildSocketOptions()['reconnectionDelayMax'], 30000);
    });

    test('no attempts cap — the absence of the key is the fix', () {
      // The regression F-03 fixed was `setReconnectionAttempts(10)`, which made
      // the client stop retrying for good after ~10 minutes offline. The client
      // only retries forever while this key is absent, so asserting absence is
      // the only way to catch someone "helpfully" adding a cap back.
      expect(buildSocketOptions().containsKey('reconnectionAttempts'), isFalse);
      expect(buildSocketOptions()['reconnection'], isNot(false));
    });
  });

  group('register', () {
    test('emits the raw driver id, not a wrapping object', () {
      socket.register('4242');
      expect(socket.only.event, 'registerDriver');
      expect(socket.only.data, '4242');
    });
  });

  group('trip-state emits', () {
    test('startDrive sends numeric lat/lng nested under location', () {
      socket.startDrive(
        bookingId: '10',
        bookingCode: '20',
        passengerId: '30',
        currentLat: 11.5564,
        currentLng: 104.9282,
      );

      expect(socket.only.event, 'startDrive');
      expect(socket.only.data, {
        'booking_code': '20',
        'booking_id': '10',
        'passengerId': '30',
        'location': {'latitude': 11.5564, 'longitude': 104.9282},
      });
    });

    test('driverCancelDrive stringifies its three int arguments', () {
      socket.driverCancelDrive(bookingId: 10, bookingCode: 20, passengerId: 30);

      expect(socket.only.event, 'driverCancelDrive');
      expect(socket.only.data, {
        'booking_code': '20',
        'booking_id': '10',
        'passengerId': '30',
      });
    });

    test('acceptPayment keeps booking_id unconverted while booking_code is not',
        () {
      // Characterizes an inconsistency rather than endorsing it: `bookingCode`
      // gets a redundant `.toString()` (it is already a String) while
      // `bookingId` is passed through raw. Both happen to be Strings today, so
      // the wire shape is uniform — but the asymmetry is what a future typed
      // refactor would trip over.
      socket.acceptPayment(
        passengerId: '30',
        bookingCode: '20',
        bookingId: '10',
      );

      expect(socket.only.event, 'acceptPayment');
      expect(socket.only.data, {
        'booking_code': '20',
        'booking_id': '10',
        'passengerId': '30',
      });
    });
  });

  group('acceptRide', () {
    test('stringifies coordinates, unlike startDrive', () {
      socket.acceptRide(
        driverId: '7',
        bookingId: '10',
        passengerId: '30',
        currentLat: 11.5564,
        currentLng: 104.9282,
        destinationLat: 11.5,
        destinationLng: 104.9,
      );

      expect(socket.only.event, 'acceptRide');
      expect(socket.only.data, {
        'driver_id': '7',
        'booking_id': '10',
        'passengerId': '30',
        'location': {'latitude': '11.5564', 'longitude': '104.9282'},
        'destination': {'latitude': '11.5', 'longitude': '104.9'},
      });
    });

    test('a missing destination becomes the literal string "null"', () {
      // Both destination fields are optional but interpolated with "$value",
      // so omitting them sends "null" rather than JSON null or an absent key.
      // Pinned as a known quirk: the server accepted this in the live probe,
      // and "fixing" it silently changes what the backend receives.
      socket.acceptRide(
        driverId: '7',
        bookingId: '10',
        passengerId: '30',
        currentLat: 11.5564,
        currentLng: 104.9282,
      );

      final destination =
          (socket.only.data as Map)['destination'] as Map<String, dynamic>;
      expect(destination['latitude'], 'null');
      expect(destination['longitude'], 'null');
    });
  });

  group('arrival and drop-off', () {
    // These two used to call `_socket?.emit(...)` directly, bypassing
    // `emitEvent` and therefore its logging. They now route through it like
    // every other emit, which is also what makes their payloads observable
    // here for the first time.
    test('arrivedSocket sends string lat/lng and no booking_id', () {
      socket.arrivedSocket(
        bookingCode: '20',
        passengerId: '30',
        lat: '11.5564',
        lng: '104.9282',
      );

      expect(socket.only.event, 'rideArrival');
      expect(socket.only.data, {
        'booking_code': '20',
        'passengerId': '30',
        'location': {'latitude': '11.5564', 'longitude': '104.9282'},
      });
      // Unlike every other trip-state emit, arrival identifies the ride by
      // booking_code alone — the server has no booking_id to match on here.
      expect((socket.only.data as Map).containsKey('booking_id'), isFalse);
    });

    test('dropDrive matches startDrive\'s shape exactly', () {
      socket.dropDrive(
        bookingId: '10',
        bookingCode: '20',
        passengerId: '30',
        currentLat: 11.5564,
        currentLng: 104.9282,
      );
      final drop = socket.only.data;

      socket.emitted.clear();
      socket.startDrive(
        bookingId: '10',
        bookingCode: '20',
        passengerId: '30',
        currentLat: 11.5564,
        currentLng: 104.9282,
      );

      // The two ends of a trip must be reported identically apart from the
      // event name, or the server is reconciling two different shapes.
      expect(drop, socket.only.data);
    });
  });

  group('emitEvent with no socket', () {
    test('is a no-op rather than a throw', () {
      // The one case that is still unrecoverable: with no socket there is
      // nothing to buffer into. It must not take the caller down with it.
      final real = DriverSocketService.forTesting();
      expect(
        () => real.startDrive(
          bookingId: '10',
          bookingCode: '20',
          passengerId: '30',
          currentLat: 11.5564,
          currentLng: 104.9282,
        ),
        returnsNormally,
      );
    });
  });
}
