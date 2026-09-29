import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:tara_driver_application/data/datasources/update_driver_location_api.dart';

/// Where positions come from. [GeolocatorPositionSource] in every normal
/// build; the QA mock build swaps in a simulated one (`lib/mock/`).
abstract class PositionSource {
  Future<bool> requestPermission();
  Future<Position?> getCurrentPosition();
  Stream<Position> positionStream();
}

class GeolocatorPositionSource implements PositionSource {
  const GeolocatorPositionSource();

  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<Position?> getCurrentPosition() async {
    return await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 15),
          desiredAccuracy: LocationAccuracy.best,
        );
  }

  @override
  Stream<Position> positionStream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        ),
      );
}

/// The single owner of the app's live GPS subscription (F-05, docs/12).
///
/// Previously `HomeScreen`, `BookingScreen`, `LocationBloc` and the
/// `TaxiLocation` singleton each opened their own `Geolocator.getPositionStream`
/// and posted to `update-driver-location` independently — several concurrent
/// subscriptions draining battery and writing the server out of order.
/// [start] is idempotent, so every screen can call it safely; only the first
/// call actually opens a stream, and only this service ever calls the API.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  /// Replaced by `MockMode.init` in a QA mock build.
  PositionSource source = const GeolocatorPositionSource();

  final UpdateDriverLocation _updateLocationRepo = UpdateDriverLocation();
  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();
  StreamSubscription<Position>? _subscription;
  Position? lastPosition;

  /// Live position updates. Does not itself start the subscription — call
  /// [start] once (from app/session init, or lazily from the first screen
  /// that needs it; repeat calls are no-ops).
  Stream<Position> get positionStream => _controller.stream;

  Future<bool> requestPermission() => source.requestPermission();

  Future<Position?> getCurrentPosition() => source.getCurrentPosition();

  /// One-shot fetch that also reports to the server and emits on
  /// [positionStream], for screens that need a location before the live
  /// stream has ticked yet.
  Future<Position?> primeCurrentLocation() async {
    final position = await getCurrentPosition();
    if (position != null) {
      _emit(position);
    }
    return position;
  }

  /// Opens the single live GPS subscription if one isn't already running.
  void start() {
    if (_subscription != null) return;
    _subscription = source.positionStream().listen(_emit);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _emit(Position position) {
    lastPosition = position;
    _controller.add(position);
    unawaited(_updateLocationRepo.updateDriverLocationApi(
      lat: position.latitude,
      log: position.longitude,
      heading: position.heading,
    ));
  }
}
