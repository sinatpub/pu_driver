import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pure geometry for the simulated GPS and the mock route polyline. No
/// plugins, no platform channels — unit-testable as-is.

const double _earthRadiusMeters = 6371000;

double _rad(double deg) => deg * math.pi / 180;

/// Great-circle distance in meters.
double distanceMeters(LatLng a, LatLng b) {
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
}

/// Initial compass bearing from [a] to [b], 0–360°.
double bearingDegrees(LatLng a, LatLng b) {
  final lat1 = _rad(a.latitude);
  final lat2 = _rad(b.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

double pathLengthMeters(List<LatLng> path) {
  var total = 0.0;
  for (var i = 1; i < path.length; i++) {
    total += distanceMeters(path[i - 1], path[i]);
  }
  return total;
}

/// The point [fraction] (clamped to 0–1) of the way along [path], and the
/// heading of the segment it lies on.
({LatLng point, double heading}) pointAlong(
    List<LatLng> path, double fraction) {
  if (path.isEmpty) {
    throw ArgumentError.value(path, 'path', 'must not be empty');
  }
  if (path.length == 1) return (point: path.first, heading: 0);
  final f = fraction.clamp(0.0, 1.0);
  final target = pathLengthMeters(path) * f;
  var walked = 0.0;
  for (var i = 1; i < path.length; i++) {
    final a = path[i - 1];
    final b = path[i];
    final segment = distanceMeters(a, b);
    if (segment == 0) continue;
    if (walked + segment >= target) {
      final t = (target - walked) / segment;
      return (
        point: LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        ),
        heading: bearingDegrees(a, b),
      );
    }
    walked += segment;
  }
  return (
    point: path.last,
    heading: bearingDegrees(path[path.length - 2], path.last),
  );
}

/// Inserts points so no segment is longer than [stepMeters] — a polyline
/// that looks drawn, not two straight strokes.
List<LatLng> densify(List<LatLng> waypoints, {double stepMeters = 40}) {
  if (waypoints.length < 2) return List.of(waypoints);
  final out = <LatLng>[waypoints.first];
  for (var i = 1; i < waypoints.length; i++) {
    final a = waypoints[i - 1];
    final b = waypoints[i];
    final steps = (distanceMeters(a, b) / stepMeters).ceil().clamp(1, 10000);
    for (var s = 1; s <= steps; s++) {
      final t = s / steps;
      out.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ));
    }
  }
  return out;
}
