import 'package:tara_driver_application/data/models/complete_driver_model.dart';
import 'package:tara_driver_application/data/models/current_driver_info_model.dart';
import 'package:tara_driver_application/features/auth/data/models/phone_model.dart';

/// Typed `Get.arguments` payloads (F-06, docs/12) — every screen that takes
/// constructor parameters gets one of these instead of an untyped map, so a
/// route call site and its screen agree on shape at compile time.

class OtpPageArgs {
  const OtpPageArgs({this.phoneNumberModel, this.phoneNumber, required this.onResend});

  final PhoneNumberModel? phoneNumberModel;
  final String? phoneNumber;

  /// Re-triggers the same phone-submit flow that got here — bound to the
  /// PhoneLoginController LoginPage already created, not a fresh one, so
  /// this doesn't duplicate in-flight state or re-navigate on success.
  final void Function() onResend;
}

class NotificationDetailArgs {
  const NotificationDetailArgs({
    required this.notificationId,
    required this.appOpened,
  });

  final String notificationId;
  final bool appOpened;
}

class MapHistoryDetailArgs {
  const MapHistoryDetailArgs({
    required this.typeVehicleId,
    required this.cost,
    required this.distand,
    required this.duration,
    required this.latStart,
    required this.lngStart,
    required this.latEnd,
    required this.lngEnd,
  });

  final int typeVehicleId;
  final String cost;
  final String distand;
  final String duration;
  final double latStart;
  final double lngStart;
  final double latEnd;
  final double lngEnd;
}

class CalculateFeeScreenArgs {
  const CalculateFeeScreenArgs({
    required this.routFrom,
    this.dataDriverInfo,
    this.dataComplete,
    required this.startAddress,
    required this.endAddress,
  });

  final String routFrom;
  final DataDriverInfo? dataDriverInfo;
  final CompleteDriverModel? dataComplete;
  final String startAddress;
  final String endAddress;
}

class BookingScreenArgs {
  const BookingScreenArgs({
    required this.startTime,
    required this.lngStart,
    required this.latStart,
    required this.typeVehicleId,
    required this.pricrVehicle,
    required this.bookingId,
    required this.bookingCode,
    required this.latPassenger,
    required this.lngPassenger,
    required this.processStepBook,
    required this.desLatPassenger,
    required this.desLngPassenger,
    this.latDriver,
    this.lngDriver,
    required this.timeOut,
    required this.passengerId,
    required this.namePassanger,
    required this.phonePassanger,
    required this.imagePassanger,
    required this.refreshApp,
  });

  final int bookingId;
  final int bookingCode;
  final int passengerId;
  final double latPassenger;
  final double lngPassenger;
  final double? desLatPassenger;
  final double? desLngPassenger;
  final double? latDriver;
  final double? lngDriver;
  final int processStepBook;
  final int timeOut;
  final String namePassanger;
  final String imagePassanger;
  final String phonePassanger;
  final int typeVehicleId;
  final int pricrVehicle;
  final bool refreshApp;
  final double latStart;
  final double lngStart;
  final String startTime;
}
