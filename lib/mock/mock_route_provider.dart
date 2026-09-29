import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/mock/mock_fixtures.dart';
import 'package:tara_driver_application/mock/mock_geo.dart';
import 'package:tara_driver_application/mock/mock_timings.dart';
import 'package:tara_driver_application/services/route_service.dart';

/// Stands in for Google Directions: the same deterministic route the
/// simulated GPS drives along, so the polyline and the car line up.
class MockRouteProvider implements RouteProvider {
  const MockRouteProvider();

  static const _latency = Duration(milliseconds: 300);

  @override
  Future<List<LatLng>> route(LatLng from, LatLng to) async {
    await Future<void>.delayed(_latency);
    return mockRoute(from, to);
  }

  @override
  Future<double> drivingDistanceKm(LatLng from, LatLng to) async {
    await Future<void>.delayed(_latency);
    return pathLengthMeters(mockRoute(from, to)) / 1000;
  }

  /// The duration is the distance at [MockTimings.assumedCitySpeedKmh] —
  /// the same realistic pace the receipt and history use.
  @override
  Future<RouteSummary?> summary(LatLng from, LatLng to) async {
    await Future<void>.delayed(_latency);
    final points = mockRoute(from, to);
    final meters = pathLengthMeters(points);
    return RouteSummary(
      points: points,
      distanceMeters: meters,
      durationSeconds:
          (meters / (MockTimings.assumedCitySpeedKmh * 1000 / 3600)).round(),
    );
  }
}
