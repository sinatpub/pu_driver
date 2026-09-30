import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Where a driver is along a fetched route (`DD-36`): what is left to drive,
/// how far that is, and how far the driver is from the route at all.
///
/// Worked out on the phone from the route already fetched, so following the
/// driver to the pickup costs no Directions requests.
class RouteProgress {
  const RouteProgress({
    required this.remaining,
    required this.remainingMeters,
    required this.offRouteMeters,
  });

  /// The route still to drive, starting at the driver's position.
  final List<LatLng> remaining;

  final double remainingMeters;

  /// Distance from the driver to the nearest point on the route. Large when
  /// the driver has left it — the caller fetches a new one.
  final double offRouteMeters;
}

const double _earthRadiusMeters = 6371000;

/// Projects [position] onto the nearest segment of [route] and returns what
/// is left after that point. An empty or one-point route leaves nothing.
RouteProgress routeProgress(List<LatLng> route, LatLng position) {
  if (route.length < 2) {
    return RouteProgress(
      remaining: <LatLng>[position],
      remainingMeters: 0,
      offRouteMeters: route.isEmpty ? 0 : distanceMeters(position, route[0]),
    );
  }

  // A flat projection around the driver — accurate to well under a metre
  // over a city trip, and cheap enough to run on every GPS tick.
  final double cosLat = math.cos(_rad(position.latitude));
  math.Point<double> local(LatLng p) => math.Point<double>(
        _rad(p.longitude - position.longitude) * cosLat * _earthRadiusMeters,
        _rad(p.latitude - position.latitude) * _earthRadiusMeters,
      );

  int nearest = 0;
  double nearestDistance = double.infinity;
  math.Point<double> a = local(route[0]);
  for (int i = 0; i < route.length - 1; i++) {
    final math.Point<double> b = local(route[i + 1]);
    final math.Point<double> ab = b - a;
    final double lengthSquared = ab.x * ab.x + ab.y * ab.y;
    // The driver sits at the origin, so the projection of the origin onto AB.
    final double t = lengthSquared == 0
        ? 0
        : (-(a.x * ab.x + a.y * ab.y) / lengthSquared).clamp(0.0, 1.0);
    final math.Point<double> closest = a + ab * t;
    final double distance = closest.magnitude;
    if (distance < nearestDistance) {
      nearestDistance = distance;
      nearest = i;
    }
    a = b;
  }

  final List<LatLng> remaining = <LatLng>[
    position,
    ...route.sublist(nearest + 1),
  ];
  return RouteProgress(
    remaining: remaining,
    remainingMeters: pathMeters(remaining),
    offRouteMeters: nearestDistance,
  );
}

/// Length of a polyline, in metres.
double pathMeters(List<LatLng> path) {
  double total = 0;
  for (int i = 0; i < path.length - 1; i++) {
    total += distanceMeters(path[i], path[i + 1]);
  }
  return total;
}

/// Great-circle distance between two points, in metres.
double distanceMeters(LatLng from, LatLng to) {
  final double dLat = _rad(to.latitude - from.latitude);
  final double dLng = _rad(to.longitude - from.longitude);
  final double h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(from.latitude)) *
          math.cos(_rad(to.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
}

double _rad(double degrees) => degrees * math.pi / 180;
