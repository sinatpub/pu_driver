import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pu_taxi_driver/core/utils/app_constant.dart';
import 'package:pu_taxi_driver/core/utils/calculate_distance.dart';
import 'package:pu_taxi_driver/core/utils/pretty_logger.dart';

/// One driving route with the figures the Directions response carries
/// alongside it. The ride-request sheet shows [durationSeconds] and
/// [distanceMeters] as "4 min · 1.2 km to pickup" (DD-35).
class RouteSummary {
  const RouteSummary({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
}

/// Driving routes and distances. Wraps the two Google Directions call sites
/// the trip and history-detail screens used to make inline, so the provider
/// can be swapped (QA mock mode) without either screen knowing.
abstract class RouteProvider {
  /// The driving route as polyline points; empty when none was found.
  Future<List<LatLng>> route(LatLng from, LatLng to);

  /// Driving distance in kilometers (0 when none was found).
  Future<double> drivingDistanceKm(LatLng from, LatLng to);

  /// The route plus its distance and duration, from one request; null when
  /// none was found.
  Future<RouteSummary?> summary(LatLng from, LatLng to);
}

class GoogleRouteProvider implements RouteProvider {
  GoogleRouteProvider();

  final PolylinePoints _polylinePoints = PolylinePoints();

  Future<PolylineResult> _directions(LatLng from, LatLng to) =>
      _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: AppConstant.googleKeyApi,
        request: PolylineRequest(
          origin: PointLatLng(from.latitude, from.longitude),
          destination: PointLatLng(to.latitude, to.longitude),
          mode: TravelMode.driving,
        ),
      );

  @override
  Future<List<LatLng>> route(LatLng from, LatLng to) async {
    final result = await _directions(from, to);
    if (result.status == 'OK' && result.points.isNotEmpty) {
      return [for (final p in result.points) LatLng(p.latitude, p.longitude)];
    }
    tlog("Directions: no route — ${result.errorMessage}");
    return const [];
  }

  @override
  Future<double> drivingDistanceKm(LatLng from, LatLng to) =>
      AsyncDistance().calculateDistance(from, to);

  @override
  Future<RouteSummary?> summary(LatLng from, LatLng to) async {
    try {
      final result = await _directions(from, to);
      if (result.status != 'OK' || result.points.isEmpty) {
        tlog("Directions: no route — ${result.errorMessage}");
        return null;
      }
      return RouteSummary(
        points: [
          for (final p in result.points) LatLng(p.latitude, p.longitude)
        ],
        distanceMeters: (result.totalDistanceValue ?? 0).toDouble(),
        durationSeconds: result.totalDurationValue ?? 0,
      );
    } catch (e) {
      // The package throws on any non-OK Directions status.
      tlog("Directions: $e");
      return null;
    }
  }
}

class RouteService {
  RouteService._();

  static final RouteService instance = RouteService._();

  /// Replaced by `MockMode.init` in a QA mock build; Google otherwise.
  RouteProvider provider = GoogleRouteProvider();

  Future<List<LatLng>> route(LatLng from, LatLng to) =>
      provider.route(from, to);

  Future<double> drivingDistanceKm(LatLng from, LatLng to) =>
      provider.drivingDistanceKm(from, to);

  Future<RouteSummary?> summary(LatLng from, LatLng to) =>
      provider.summary(from, to);
}
