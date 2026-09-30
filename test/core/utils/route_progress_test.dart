import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/core/utils/route_progress.dart';

/// DD-36 — following the driver along the pickup route on the phone.
void main() {
  // An L-shaped route in Phnom Penh: ~1.1 km north-south, then ~1.1 km east.
  const LatLng a = LatLng(11.560, 104.920);
  const LatLng b = LatLng(11.570, 104.920);
  const LatLng c = LatLng(11.570, 104.930);
  const List<LatLng> route = <LatLng>[a, b, c];

  test('distanceMeters matches a known distance', () {
    // 0.01° of latitude is ~1,112 m anywhere.
    expect(distanceMeters(a, b), closeTo(1112, 2));
  });

  test('at the start, everything is left', () {
    final RouteProgress p = routeProgress(route, a);
    expect(p.remainingMeters, closeTo(pathMeters(route), 1));
    expect(p.offRouteMeters, closeTo(0, 0.5));
    expect(p.remaining.first, a);
    expect(p.remaining.last, c);
  });

  test('halfway up the first leg, the driven part is dropped', () {
    const LatLng mid = LatLng(11.565, 104.920);
    final RouteProgress p = routeProgress(route, mid);

    expect(p.remaining, <LatLng>[mid, b, c]);
    expect(
      p.remainingMeters,
      closeTo(distanceMeters(mid, b) + distanceMeters(b, c), 1),
    );
  });

  test('on the second leg, the first leg is gone', () {
    const LatLng onSecond = LatLng(11.570, 104.925);
    final RouteProgress p = routeProgress(route, onSecond);

    expect(p.remaining, <LatLng>[onSecond, c]);
    expect(p.remainingMeters, closeTo(distanceMeters(onSecond, c), 1));
  });

  test('reports how far the driver has left the route', () {
    // ~200 m west of the first leg.
    const LatLng off = LatLng(11.565, 104.91817);
    final RouteProgress p = routeProgress(route, off);

    expect(p.offRouteMeters, closeTo(200, 5));
  });

  test('at the end, nothing is left', () {
    final RouteProgress p = routeProgress(route, c);
    expect(p.remainingMeters, closeTo(0, 0.5));
  });

  test('a route with fewer than two points leaves nothing', () {
    expect(routeProgress(const <LatLng>[], a).remainingMeters, 0);
    expect(
        routeProgress(const <LatLng>[b], a).offRouteMeters, closeTo(1112, 2));
  });
}
