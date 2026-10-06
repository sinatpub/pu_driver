import 'dart:convert';

import 'package:pu_taxi_driver/core/utils/money.dart';
import 'package:pu_taxi_driver/routes/route_arguments.dart';

/// D-05 (docs/12) — parses the payload for a new ride request. The driver
/// socket's `newRide` event and the `service_booking` FCM push carry the
/// same fields, just shaped slightly differently: the socket sends
/// `passenger`/`location`/`destination` as nested objects already; FCM
/// sends them JSON-encoded as strings inside `data`. Both call sites used
/// to inline unguarded `int.parse`/direct map access straight into the
/// `BookingScreenArgs(...)` constructor call — a malformed or partial
/// payload threw, was caught by a bare `catch`, logged, and the ride
/// request was silently dropped: the driver never learned it arrived
/// (docs/08 L-10, docs/02 §3 "the socket layer builds UI").
///
/// [bookingId]/[bookingCode]/[passengerId] are the only fields that can't
/// be defaulted — without a real booking id there's nothing to accept,
/// arrive at, start, or complete, so a missing/unparseable one fails the
/// whole parse via [NewRideParseException]. Everything else (price,
/// vehicle type, passenger name/phone/photo, timeout, positions) degrades
/// to a safe default instead of losing the entire request over one
/// missing nice-to-have field — matching `home_screen.dart`'s own
/// `navigateToBookingScreen`, which already falls back to `timeOut: 30`
/// for the same "we don't actually know" case via a different path in.
class NewRideParseException implements Exception {
  const NewRideParseException(this.reason);

  final String reason;

  @override
  String toString() => 'NewRideParseException: $reason';
}

/// The ride request carried by a `newRide` socket event.
///
/// A socket handler gets the event's arguments as one value: the argument
/// itself when the server sends one, a list of them when it sends more. This
/// backend sends two — the request, then a short string — so what arrives is
/// `[{booking_code: …, booking_id: …, …}, "Q4GfXZP"]` (seen 2026-10-06). The
/// handler cast that straight to a map, the cast threw, and the request
/// sounded its alert but never opened: the driver heard a ride and saw
/// nothing.
///
/// The request is the first object among the arguments. What the string
/// after it is for is not known, and it is not needed to show the request.
BookingScreenArgs parseNewRideEvent(dynamic event) {
  final Map<String, dynamic>? request = _firstObject(event);
  if (request == null) {
    throw NewRideParseException('no ride request in the event: $event');
  }
  return parseNewRideArgs(request);
}

/// [value] itself when it is an object (or the JSON text of one), else the
/// first such thing in it when it is a list.
Map<String, dynamic>? _firstObject(dynamic value) {
  if (value is List) {
    for (final dynamic item in value) {
      final Map<String, dynamic>? found = _firstObject(item);
      if (found != null) return found;
    }
    return null;
  }
  return _asMap(value);
}

BookingScreenArgs parseNewRideArgs(Map<String, dynamic> data) {
  final passenger = _asMap(data['passenger']) ?? const {};
  final location = _asMap(data['location']) ?? const {};
  final destination = _asMap(data['destination']);

  return BookingScreenArgs(
    startTime: '',
    latStart: 0.0,
    lngStart: 0.0,
    refreshApp: false,
    processStepBook: 1,
    bookingId: _requireInt(data['booking_id'], 'booking_id'),
    bookingCode: _requireInt(data['booking_code'], 'booking_code'),
    passengerId: _requireInt(data['passengerId'], 'passengerId'),
    typeVehicleId: _intOr(data['vehicleType'], 0),
    pricrVehicle: parseMoney(data['vehiclePrice']) ?? 0,
    timeOut: _intOr(data['timeout'], 30),
    namePassanger: passenger['name']?.toString() ?? '',
    phonePassanger: passenger['phone']?.toString() ?? '',
    imagePassanger: passenger['profile']?.toString() ?? '',
    latPassenger: _doubleOr(location['latitude'], 0.0),
    lngPassenger: _doubleOr(location['longitude'], 0.0),
    desLatPassenger:
        destination == null ? null : _doubleOrNull(destination['latitude']),
    desLngPassenger:
        destination == null ? null : _doubleOrNull(destination['longitude']),
  );
}

/// Accepts an already-decoded map (the socket shape) or a JSON-encoded
/// string (the FCM shape) for the same field.
Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } on FormatException {
      return null;
    }
  }
  return null;
}

int _requireInt(dynamic value, String field) {
  final parsed = _intOrNull(value);
  if (parsed == null) {
    throw NewRideParseException('missing or invalid "$field": $value');
  }
  return parsed;
}

int _intOr(dynamic value, int fallback) => _intOrNull(value) ?? fallback;

int? _intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double _doubleOr(dynamic value, double fallback) =>
    _doubleOrNull(value) ?? fallback;

double? _doubleOrNull(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
