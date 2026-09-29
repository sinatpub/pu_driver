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
Future<BitmapDescriptor> loadCustomMarkerTukTuk({
  required int typeVehicleId,
}) async {
  return BitmapDescriptor.asset(
    const ImageConfiguration(size: Size(30, 50)),
    typeVehicleId == 1
        ? "assets/marker/rickshaw_icon_svg.png"
        : typeVehicleId == 2
            ? "assets/marker/classis_car.png"
            : typeVehicleId == 3
                ? "assets/marker/mini_van.png"
                : typeVehicleId == 4
                    ? "assets/marker/SUV.png"
                    : typeVehicleId == 5
                        ? "assets/marker/alphard_vip.png"
                        : "",
  );
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
