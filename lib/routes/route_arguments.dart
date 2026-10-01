import 'package:tara_driver_application/data/models/complete_driver_model.dart';
import 'package:tara_driver_application/data/models/current_driver_info_model.dart';
import 'package:tara_driver_application/presentation/screens/login/data/models/phone_model.dart';

/// Typed `Get.arguments` payloads (F-06, docs/12) — every screen that takes
/// constructor parameters gets one of these instead of an untyped map, so a
/// route call site and its screen agree on shape at compile time.

class OtpPageArgs {
  const OtpPageArgs(
      {this.phoneNumberModel, this.phoneNumber, required this.onResend});

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
    this.invoiceId,
    this.passengerName,
    this.passengerImage,
    this.passengerPhone,
    this.startAddress,
    this.endAddress,
    this.paymentMethod,
    this.tripTime,
    this.endedAt,
  });

  final int typeVehicleId;
  final String cost;
  final String distand;
  final String duration;
  final double latStart;
  final double lngStart;
  final double latEnd;
  final double lngEnd;

  /// DD-42: the rest of the trip, so the detail screen shows what the list
  /// card did and more. All optional — a caller that only has the figures
  /// still gets the old, figures-only screen.
  final String? invoiceId;
  final String? passengerName;
  final String? passengerImage;

  /// Never printed: only dialled, and only within 24 h of [endedAt].
  final String? passengerPhone;
  final String? startAddress;
  final String? endAddress;
  final String? paymentMethod;

  /// When the trip started, for the "Time" figure.
  final DateTime? tripTime;

  /// When the trip ended, for the passenger-call window.
  final DateTime? endedAt;
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
