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