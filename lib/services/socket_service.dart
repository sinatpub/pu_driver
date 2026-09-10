import 'package:tara_driver_application/app/alert_widget.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:tara_driver_application/features/trip/data/new_ride_payload_parser.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';

// F-01 (docs/12) — socket event names. `passangerCancelDrive` (typo'd,
// docs/02 finding #15) never matched the wire event name and was dead;
// `onPassengerCancelDrive` is the event actually listened for below.
enum SocketEvent {
  registerDriver,
  newRide,
  acceptRide,
  rideArrival,
  startDrive,
  dropDrive,
  acceptPayment,
  driverCancelDrive,
  onPassengerCancelDrive,
}

/// F-03 (docs/12) — the old config (10 attempts, flat 60s delay) gave up for
/// good after ~10 minutes of no connectivity and never tried again, silently
/// going deaf mid-trip. Omitting the attempts cap is what makes the client
/// default (infinite retries) apply, so its *absence* from this map is
/// load-bearing, not an oversight; the delay backs off from 2s toward a 30s
/// ceiling instead of a flat wait.
///
/// Extracted so the reconnection policy can be asserted without opening a
/// socket — see `test/taxi_single_ton/socket_event_contract_test.dart`.
@visibleForTesting
Map<String, dynamic> buildSocketOptions() => io.OptionBuilder()
    .setTransports(['websocket'])
    .enableAutoConnect()
    .enableReconnection()
    .setReconnectionDelay(2000)
    .setReconnectionDelayMax(30000)
    .build();

// Base socket service
abstract class BaseSocketService {
  io.Socket? _socket;

  void connectToSocket(String url, String id, String role,
      {required BuildContext context}) {
    _socket = io.io(url, buildSocketOptions());

    _socket?.onConnect((_) {
      tlog('$role connected to socket');
      register(id);
    });

    _socket?.onConnectError((err) {
      tlog('Connection Error: $err');
    });

    _socket?.onDisconnect((_) {
      tlog('$role socket disconnected');
    });
  }

  void register(String id);

  /// Emits [event], letting Socket.IO buffer it when the connection is
  /// temporarily down.
  ///
  /// The old body refused to emit unless `connected` was already true and
  /// logged "socket is not connected" instead. That **permanently dropped**
  /// the event: `Socket.emit` on a disconnected-but-live socket appends to
  /// `sendBuffer` and `emitBuffered()` flushes it on reconnect, so the guard
  /// was throwing away a packet the client would otherwise have delivered a
  /// few seconds later. It cost `startDrive`, `acceptPayment`,
  /// `driverCancelDrive` and `acceptRide` — every trip-state and money event
  /// the driver sends — on any brief loss of signal, which is routine on a
  /// phone in a moving car. `arrivedSocket`/`dropDrive` never had the guard
  /// and were the only two emits that already survived a blip; this brings
  /// the rest in line with them rather than the other way round.
  ///
  /// A null socket is still unrecoverable — there is nothing to buffer into —
  /// so that case keeps its log line and stays the only real failure.
  void emitEvent(String event, dynamic data) {
    final socket = _socket;
    if (socket == null) {
      tlog('Failed to emit event: $event, socket was never created.');
      return;
    }

    socket.emit(event, data);
    if (socket.connected) {
      tlog('Event emitted: $event, data: $data');
    } else {
      tlog('Event buffered until reconnect: $event, data: $data');
    }
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }
}

class DriverSocketService extends BaseSocketService {
  static final DriverSocketService _instance = DriverSocketService._internal();

  factory DriverSocketService() {
    return _instance;
  }
  DriverSocketService._internal();

  /// The singleton's own constructor is private, so nothing outside this
  /// library can build an instance to assert against. This exists purely so
  /// tests can subclass and observe `emitEvent`; production code must keep
  /// going through the `DriverSocketService()` factory.
  @visibleForTesting
  DriverSocketService.forTesting();

  @override
  void register(String driverId) {
    emitEvent(SocketEvent.registerDriver.name, driverId);
  }

  @override
  void connectToSocket(String url, String id, String role,
      {required BuildContext context}) {
    if (_socket != null && _socket!.connected) {
      tlog("Socket already connected, skipping new connection.");
      return;
    }

    super.connectToSocket(url, id, role, context: context);
    tlog("Socket connecting to $url, userId=$id, role=$role");

    // F-03 (docs/12) — this branch only runs when `_socket` was just
    // replaced with a fresh instance above (the guard at the top of this
    // method returns early otherwise), so it's always safe — and, unlike
    // the old one-shot `_listenersSetup` flag, always necessary — to
    // attach these to the new socket. The flag left every socket created
    // after the app's first one (e.g. after the built-in reconnection
    // exhausted its attempts and the driver reopened a screen) with no
    // listener for new ride requests or passenger cancellations at all.
    newRide();
    cancelDrive(context);
  }

  // * Listener
  void newRide() {
    _socket?.on(SocketEvent.newRide.name, (data) async {
      tlog("New ride data: $data");

      try {
        final args = parseNewRideArgs(Map<String, dynamic>.from(data as Map));
        Get.toNamed(AppRoutes.booking, arguments: args);
      } catch (e) {
        tlog("Failed to show new ride request: $e — raw data: $data");
      }

      // Fires unconditionally — a malformed/partial payload still means a
      // ride request arrived, and the driver silently never finding out
      // was the actual defect here (docs/08 L-10), not the parse failure
      // itself.
      Taxi.shared.notifyBooking(
          title: "NEWREQUEST".tr(),
          description: "DESREQUEST".tr(),
          isSound: true);
    });
  }

  void cancelDrive(BuildContext context) {
    _socket?.on(
      SocketEvent.onPassengerCancelDrive.name,
      (data) {
        tlog("On cancel: $data");
        try {
          AlertWidget().cancelBooking(context);
        } catch (e) {
          tlog("On cancel: $e");
        }
      },
    );
  }

  void arrivedSocket(
      {String? bookingCode,
      String? passengerId,
      required String lat,
      required String lng}) {
    emitEvent(
      SocketEvent.rideArrival.name,
      {
        "booking_code": bookingCode,
        "passengerId": passengerId,
        "location": {"latitude": lat, "longitude": lng},
      },
    );
  }

  void driverCancelDrive({
    required int bookingId,
    required int bookingCode,
    required int passengerId,
  }) {
    emitEvent(
      SocketEvent.driverCancelDrive.name,
      {
        "booking_code": bookingCode.toString(),
        "booking_id": bookingId.toString(),
        "passengerId": passengerId.toString(),
      },
    );
  }

  // * Listener
  void startDrive({
    required String bookingId,
    required String bookingCode,
    required String passengerId,
    required double currentLat,
    required double currentLng,
    double? destinationLat,
    double? destinationLng,
  }) {
    emitEvent(
      SocketEvent.startDrive.name,
      {
        "booking_code": bookingCode,
        "booking_id": bookingId,
        "passengerId": passengerId,
        "location": {
          "latitude": currentLat,
          "longitude": currentLng,
        },
      },
    );
  }

  void dropDrive({
    required String bookingId,
    required String bookingCode,
    required String passengerId,
    required double currentLat,
    required double currentLng,
    double? destinationLat,
    double? destinationLng,
  }) {
    emitEvent(
      SocketEvent.dropDrive.name,
      {
        "booking_code": bookingCode,
        "booking_id": bookingId,
        "passengerId": passengerId,
        "location": {
          "latitude": currentLat,
          "longitude": currentLng,
        },
      },
    );
  }

  void acceptPayment({
    required String passengerId,
    required String bookingCode,
    required String bookingId,
  }) {
    emitEvent(
      SocketEvent.acceptPayment.name,
      {
        "booking_code": bookingCode.toString(),
        "booking_id": bookingId,
        "passengerId": passengerId,
      },
    );
  }

  void acceptRide({
    required String driverId,
    required String bookingId,
    required String passengerId,
    required double currentLat,
    required double currentLng,
    double? destinationLat,
    double? destinationLng,
  }) {
    emitEvent(SocketEvent.acceptRide.name, {
      "driver_id": driverId,
      "booking_id": bookingId,
      "passengerId": passengerId,
      "location": {
        "latitude": "$currentLat",
        "longitude": "$currentLng",
      },
      "destination": {
        "latitude": "$destinationLat",
        "longitude": "$destinationLng",
      }
    });
  }

  // Future<void> notifyBooking(
  //     {required String title, String? description, bool isSound = true}) async {
  //   try {
  //     await NotificationLocal.notificationBooking(
  //         channel: NotificationLocal.channel,
  //         plugin: NotificationLocal.notifications,
  //         title: title,
  //         useCustomSound: isSound,
  //         description: description);
  //     tlog('Notification triggered', level: LogLevel.debug);
  //   } catch (e) {
  //     tlog('Error triggering notification: $e', level: LogLevel.error);
  //   }
  // }
}
