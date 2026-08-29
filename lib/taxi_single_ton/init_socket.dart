import 'package:tara_driver_application/app/alert_widget.dart';
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/routing/route_arguments.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
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
          .setReconnectionAttempts(10)
          .setReconnectionDelay(60000)
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

  // Add a flag to track whether listeners were already set up
  bool _listenersSetup = false;

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

    if (!_listenersSetup) {
      newRide();
      cancelDrive(context);
      _listenersSetup = true;
    }
  }

  // * Listener
  void newRide() {
    _socket?.on(SocketEvent.newRide.name, (data) async {
      tlog("New ride data: $data");

      try {
        Get.toNamed(
          AppRoutes.booking,
          arguments: BookingScreenArgs(
            latStart: 0.0,
            lngStart: 0.0,
            startTime: "",
            refreshApp: false,
            typeVehicleId: data["vehicleType"],
            pricrVehicle: data["vehiclePrice"],
            namePassanger: data["passenger"]["name"],
            phonePassanger: data["passenger"]["phone"],
            imagePassanger: data["passenger"]["profile"],
            timeOut: data["timeout"],
            processStepBook: 1,
            bookingCode: int.parse(data["booking_code"]),
            bookingId: int.parse(data["booking_id"]),
            latPassenger: data["location"]['latitude'],
            lngPassenger: data["location"]['longitude'],
            desLatPassenger:
                double.tryParse("${data["destination"]['latitude']}"),
            desLngPassenger:
                double.tryParse("${data["destination"]['longitude']}"),
            passengerId: int.parse(data["passengerId"]),
          ),
        );
        Taxi.shared.notifyBooking(
            title: "NEWREQUEST".tr(),
            description: "DESREQUEST".tr(),
            isSound: true);
      } catch (e) {
        tlog("Navigation failed: $e");
      }
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
