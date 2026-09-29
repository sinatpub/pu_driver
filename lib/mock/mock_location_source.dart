import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:tara_driver_application/mock/mock_backend.dart';
import 'package:tara_driver_application/mock/mock_geo.dart';
import 'package:tara_driver_application/mock/mock_mode.dart';
import 'package:tara_driver_application/mock/mock_timings.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/services/location_service.dart';

/// Simulated GPS for [LocationService]. The car's position comes from
/// [MockBackend.driverFix] — parked while idle, driving to the pickup after
/// accept, driving to the destination after start — so the map, the trip
/// meter and the server's view of the ride always agree.
class MockLocationSource implements PositionSource {
  MockLocationSource({MockBackend? backend}) : _backend = backend;

  static final MockLocationSource instance = MockLocationSource();

  final MockBackend? _backend;
  MockBackend get _b => _backend ?? MockBackend.instance;

  bool get _unavailable =>
      MockMode.settings.scenario == MockScenario.locationError;

  @override
  Future<bool> requestPermission() async => true;

  /// `LOCATION_ERROR`: permission is granted but no fix ever arrives — the
  /// same null the real source returns when the GPS times out.
  @override
  Future<Position?> getCurrentPosition() async =>
      _unavailable ? null : _position();

  @override
  Stream<Position> positionStream() {
    late StreamController<Position> controller;
    Timer? timer;
    LatLng? last;
    controller = StreamController<Position>(
      onListen: () {
        timer = Timer.periodic(MockTimings.gpsTick, (_) {
          if (_unavailable) return;
          final position = _position();
          final point = LatLng(position.latitude, position.longitude);
          // Like the real stream's distanceFilter: a parked car is silent.
          if (last != null && distanceMeters(last!, point) < 1) return;
          last = point;
          controller.add(position);
        });
      },
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }

  Position _position() {
    final fix = _b.driverFix();
    return Position(
      latitude: fix.point.latitude,
      longitude: fix.point.longitude,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 12,
      altitudeAccuracy: 3,
      heading: fix.heading,
      headingAccuracy: 10,
      speed: fix.speedMps,
      speedAccuracy: 1,
      isMocked: true,
    );
  }
}
