import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pu_taxi_driver/core/utils/load_custom_marker.dart';

/// The home map showed several driver markers after the driver opened
/// another tab from the drawer and came back. Each GPS tick had *added* a
/// "driverMarker" (`Marker.==` compares every field, its hash is the id
/// alone), and the rebuilt map drew every one it was handed.
void main() {
  Marker driverAt(double lat, double rotation) => Marker(
        markerId: const MarkerId('driverMarker'),
        position: LatLng(lat, 104.88),
        rotation: rotation,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      );

  test('a plain Set.add keeps every position (the bug)', () {
    final Set<Marker> markers = <Marker>{}
      ..add(driverAt(11.50, 0))
      ..add(driverAt(11.51, 90));
    expect(markers, hasLength(2));
  });

  test('putMarker keeps one marker per id, the newest', () {
    final Set<Marker> markers = <Marker>{};
    for (int i = 0; i < 50; i++) {
      markers.putMarker(driverAt(11.5 + i * 1e-4, i * 6.0));
    }
    expect(markers, hasLength(1));
    expect(markers.single.position.latitude, closeTo(11.5 + 49 * 1e-4, 1e-9));
    expect(markers.single.rotation, 49 * 6.0);
  });

  test('putMarker leaves markers with other ids alone', () {
    final Set<Marker> markers = <Marker>{
      const Marker(markerId: MarkerId('passengerMarker')),
    };
    markers
      ..putMarker(driverAt(11.50, 0))
      ..putMarker(driverAt(11.51, 90));
    expect(
      markers.map((Marker m) => m.markerId.value),
      unorderedEquals(<String>['passengerMarker', 'driverMarker']),
    );
  });

  test('on the home state RxSet it stays one marker and still notifies', () {
    final RxSet<Marker> markers = <Marker>{}.obs;
    int fires = 0;
    markers.listen((_) => fires++);
    for (int i = 0; i < 20; i++) {
      markers.putMarker(driverAt(11.5 + i * 1e-4, 0));
    }
    expect(markers, hasLength(1));
    expect(fires, greaterThan(0));
  });
}
