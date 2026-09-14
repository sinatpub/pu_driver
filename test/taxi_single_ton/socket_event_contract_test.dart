import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/services/socket_service.dart';

/// Characterization tests for the driver half of the Socket.IO wire contract
/// (`.agent/TODO.md` Recommended #2; mandatory under `.agent/RULES.md` because
/// every event here moves trip state or money).
///
/// These pin *wire strings*, not Dart identifiers. `SocketEvent` is emitted via
/// `.name`, so renaming an enum constant silently renames the event the server
/// and the passenger app see — a rename that `dart analyze` cannot catch and
/// that no other test in either app would fail on.
///
/// The expected values are not guesses. They were confirmed against the live
/// server on 2026-09-07 by connecting two Socket.IO probe clients and observing
/// the relay (`.agent/PROGRESS.md`), which resolved the open question `docs/04`
/// §3.3 raised and `docs/13` carried.
void main() {
  group('driver wire event names', () {
    test('every SocketEvent maps to its confirmed wire string', () {
      expect(SocketEvent.registerDriver.name, 'registerDriver');
      expect(SocketEvent.newRide.name, 'newRide');
      expect(SocketEvent.acceptRide.name, 'acceptRide');
      expect(SocketEvent.rideArrival.name, 'rideArrival');
      expect(SocketEvent.startDrive.name, 'startDrive');
      expect(SocketEvent.dropDrive.name, 'dropDrive');
      expect(SocketEvent.acceptPayment.name, 'acceptPayment');
      expect(SocketEvent.driverCancelDrive.name, 'driverCancelDrive');
      expect(SocketEvent.onPassengerCancelDrive.name, 'onPassengerCancelDrive');
    });

    test('the enum has not grown or shrunk without this test being updated',
        () {
      // Guards the list above from going stale: a new event added to the enum
      // but not to this file would otherwise be silently untested.
      expect(SocketEvent.values, hasLength(9));
    });

    test('the passenger-cancel listener keeps its `on` prefix', () {
      // docs/02 finding #15: this constant was once misspelled
      // `passangerCancelDrive` and never matched the wire event, so the driver
      // never learned a passenger had cancelled. F-01 renamed it. The prefix
      // matters — `passengerCancelDrive` (no `on`) is the *passenger's outbound*
      // event, a different string the driver must not listen for.
      expect(SocketEvent.onPassengerCancelDrive.name, startsWith('on'));
      expect(SocketEvent.onPassengerCancelDrive.name,
          isNot('passengerCancelDrive'));
    });
  });
}
