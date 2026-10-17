import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<Uint8List> loadImageFromAssets(String assetPath) async {
  final ByteData byteData = await rootBundle.load(assetPath);
  return byteData.buffer.asUint8List();
}

/// Shared by home_screen.dart and booking_screen.dart for the passenger pin.
Future<BitmapDescriptor> loadCustomMarker() async {
  return BitmapDescriptor.asset(
    const ImageConfiguration(size: Size(90, 90)),
    "assets/marker/passenger_marker.png",
  );
}

/// Shared by home_screen.dart and booking_screen.dart for the driver's own
/// pin, styled by the vehicle type on the driver's active booking.
///
/// The images (DD-60) are top-down, nose up and centred in the same 3:5 box
/// as this size, so `rotation: heading` with `anchor: Offset(0.5, 0.5)` turns
/// the vehicle about its middle and nothing is stretched. Each is a 120x200
/// PNG (4x) exported from its source in `docs/markers/`.
Future<BitmapDescriptor> loadCustomMarkerTukTuk({
  required int typeVehicleId,
}) async {
  return BitmapDescriptor.asset(
    const ImageConfiguration(size: Size(30, 50)),
    vehicleMarkerAsset(typeVehicleId),
  );
}

/// The marker image for a vehicle type. Any id without its own image — 0
/// before the driver's profile has loaded, a ride payload with no
/// `vehicleType`, or a type added on the server later — gets the classic car.
///
/// It used to return "" for those. A debug build stopped that at an
/// `assert` in `BitmapDescriptor.asset`; a profile or release build has no
/// asserts, so the empty path reached Google Maps, which threw
/// `IllegalArgumentException: 'asset' cannot open asset:` on the main thread
/// and crashed the app on the home map's first GPS fix.
String vehicleMarkerAsset(int typeVehicleId) => switch (typeVehicleId) {
      1 => "assets/marker/vehicle_tuk_tuk.png",
      2 => "assets/marker/vehicle_classic_car.png",
      3 => "assets/marker/vehicle_mini_van.png",
      4 => "assets/marker/vehicle_suv.png",
      5 => "assets/marker/vehicle_alphard_vip.png",
      6 => "assets/marker/vehicle_motor.png",
      _ => fallbackVehicleMarkerAsset,
    };

const String fallbackVehicleMarkerAsset =
    "assets/marker/vehicle_classic_car.png";

extension PutMarker on Set<Marker> {
  /// Replaces the marker with the same id. `Set.add` alone keeps every
  /// position a marker ever had, one per GPS tick: [Marker.==] compares every
  /// field but its hash is the id alone. A live map shows only the newest per
  /// id, but a map built afresh — the home tab reopened from the drawer —
  /// gets the whole set as its initial markers and draws each one.
  void putMarker(Marker marker) {
    removeWhere((Marker m) => m.markerId == marker.markerId);
    add(marker);
  }
}

/// The trip screen's pickup and destination pins (DD-35), drawn in code so
/// they stay sharp at every screen density and need no asset. Pickup is a
/// brand circle with a white centre; destination is a dark rounded square.
/// Both anchor at their centre: `Marker(anchor: const Offset(0.5, 0.5))`.
///
/// The map is always light (DD-28), so the light palette's values are used
/// directly. Each pin is drawn once and cached — `syncMarker` asks for them
/// on every GPS tick.
enum TripPin { pickup, destination }

final Map<TripPin, Future<BitmapDescriptor>> _tripPinCache =
    <TripPin, Future<BitmapDescriptor>>{};

Future<BitmapDescriptor> loadTripPin(TripPin pin) =>
    _tripPinCache.putIfAbsent(pin, () => _drawTripPin(pin));

Future<BitmapDescriptor> _drawTripPin(TripPin pin) async {
  const double logicalSize = 30;
  final double ratio =
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  final double size = logicalSize * ratio;
  final Offset centre = Offset(size / 2, size / 2);

  const Color brand = Color(0xFFFF4500);
  const Color dark = Color(0xFF3A3A3C);
  const Color white = Color(0xFFFFFFFF);
  const Color shadow = Color(0x33000000);

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);

  switch (pin) {
    case TripPin.pickup:
      canvas.drawCircle(centre, size * 0.48, Paint()..color = shadow);
      canvas.drawCircle(centre, size * 0.42, Paint()..color = white);
      canvas.drawCircle(centre, size * 0.32, Paint()..color = brand);
      canvas.drawCircle(centre, size * 0.12, Paint()..color = white);
    case TripPin.destination:
      RRect square(double half, double radius) => RRect.fromRectAndRadius(
            Rect.fromCenter(center: centre, width: half * 2, height: half * 2),
            Radius.circular(radius),
          );
      canvas.drawRRect(
          square(size * 0.46, size * 0.16), Paint()..color = shadow);
      canvas.drawRRect(
          square(size * 0.40, size * 0.13), Paint()..color = white);
      canvas.drawRRect(square(size * 0.30, size * 0.08), Paint()..color = dark);
      canvas.drawRRect(
          square(size * 0.10, size * 0.03), Paint()..color = white);
  }

  final ui.Image image =
      await recorder.endRecording().toImage(size.round(), size.round());
  final ByteData? bytes =
      await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: ratio,
  );
}
