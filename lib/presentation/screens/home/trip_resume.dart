import 'package:pu_taxi_driver/core/contracts/booking_status.dart';
import 'package:pu_taxi_driver/data/models/current_driver_info_model.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/domain/trip_state_machine.dart';
import 'package:pu_taxi_driver/routes/route_arguments.dart';

/// Audit D-7 — the stage a trip from `get-current-drive-info` reopens at, or
/// null when there is no trip to reopen.
///
/// This was `getProcessStepBook`, which sent every status it did not list
/// to "on the way to the pickup": a cancelled (5) or completed (4, 7) trip,
/// or a request (1) the driver never accepted, reopened as a live one. Only
/// a trip the driver has accepted and not finished reopens now; pending
/// payment (6) goes to the fee page, which the caller handles.
TripStage? resumeStage(int? status) => switch (status) {
      BookingStatus.accepted => TripStage.enRouteToPickup,
      BookingStatus.arrived => TripStage.waitingAtPickup,
      BookingStatus.startRide => TripStage.inProgress,
      _ => null,
    };

/// Audit D-6 — the trip screen's arguments for a trip reopened at [stage],
/// or null when [trip] lacks what the screen cannot do without.
///
/// The old builder force-unwrapped and `double.parse`d about fifteen fields
/// inside a delayed callback: one missing value threw there, with the
/// "Resuming trip" dialog already up and nothing left to take it down. The
/// booking id, its code, the passenger and a pickup point are required —
/// there is no trip to drive without them. Everything else falls back to
/// what the new-ride parser uses for the same "not known" case.
BookingScreenArgs? resumeBookingArgs(DataDriverInfo trip, TripStage stage) {
  final int? bookingId = trip.id;
  final int? bookingCode = int.tryParse('${trip.bookingCode}');
  final Passenger? passenger = trip.passenger;
  final int? passengerId = passenger?.id;

  final double? startLat = _toDouble(trip.startLatitude);
  final double? startLng = _toDouble(trip.startLongitude);
  // The passenger's last known position, else the booking's own pickup.
  final double? pickupLat =
      _toDouble(passenger?.lastLocation?.latitude) ?? startLat;
  final double? pickupLng =
      _toDouble(passenger?.lastLocation?.longitude) ?? startLng;

  if (bookingId == null ||
      bookingCode == null ||
      passengerId == null ||
      pickupLat == null ||
      pickupLng == null) {
    return null;
  }

  final Driver? driver = trip.driver;
  return BookingScreenArgs(
    startTime: trip.startTime?.toString() ?? '',
    latStart: startLat ?? pickupLat,
    lngStart: startLng ?? pickupLng,
    refreshApp: true,
    typeVehicleId: driver?.vehicle?.typeVehicleId ?? 0,
    // 0 is "not known" and shows no estimate. This used to fall back to
    // 1200 — a riel price that would be read as dollars now.
    pricrVehicle: driver?.vehicle?.pricrVehicle ?? 0,
    namePassanger: passenger?.name ?? '',
    phonePassanger: passenger?.phone ?? '',
    imagePassanger: passenger?.profileImage ?? '',
    timeOut: 30,
    processStepBook: stage.toProcessStep(),
    bookingCode: bookingCode,
    bookingId: bookingId,
    latPassenger: pickupLat,
    lngPassenger: pickupLng,
    latDriver: _toDouble(driver?.lastLocation?.latitude),
    lngDriver: _toDouble(driver?.lastLocation?.longitude),
    passengerId: passengerId,
    desLatPassenger: _toDouble(trip.endLatitude),
    desLngPassenger: _toDouble(trip.endLongitude),
  );
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
