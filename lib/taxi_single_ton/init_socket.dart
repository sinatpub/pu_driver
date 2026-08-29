import 'package:tara_driver_application/app/alert_widget.dart';
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:tara_driver_application/features/trip/data/new_ride_payload_parser.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';

// Enum for socket events
enum SocketEvent {
  registerDriver,
  newRide,
  acceptRide,
  rideArrival,
  startDrive,
  dropDrive,
  acceptPayment,
  driverCancelDrive,
  passangerCancelDrive,
}

// Base socket service
abstract class BaseSocketService {
  io.Socket? _socket;

  void connectToSocket(String url, String id, String role,
      {required BuildContext context}) {
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          // F-03 (docs/12) — the old config (10 attempts, flat 60s delay)
          // gave up for good after ~10 minutes of no connectivity and never
          // tried again, silently going deaf mid-trip. No attempts cap
          // means the client default (infinite retries) applies; delay
          // backs off from 2s toward a 30s ceiling instead of a flat wait.
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(30000)
          .build(),
    );

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

  void emitEvent(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket?.emit(event, data);
      tlog('Event emitted: $event, data: $data');
    } else {
      tlog('Failed to emit event: $event, socket is not connected.');
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
      'onPassengerCancelDrive',
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
    _socket?.emit(
      'rideArrival',
      {
        "booking_code": bookingCode,
        "passengerId": passengerId,
        "location": {"latitude": lat, "longitude": lng},
      },
    );
    tlog('Start ride with booking code:');
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
    _socket?.emit(
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
