import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/utils/load_custom_marker.dart';

/// The home map crashed a profile/release build on its first GPS fix: the
/// vehicle type was still 0, the marker asset path was "", and Google Maps
/// threw `'asset' cannot open asset:` on the main thread.
void main() {
  test('every vehicle type, known or not, has a marker image', () {
    for (final int id in <int>[-1, 0, 1, 2, 3, 4, 5, 6, 7, 99]) {
      expect(vehicleMarkerAsset(id), isNotEmpty, reason: 'type $id');
    }
  });

  test('unknown types fall back to the classic car', () {
    expect(vehicleMarkerAsset(0), fallbackVehicleMarkerAsset);
    expect(vehicleMarkerAsset(7), fallbackVehicleMarkerAsset);
  });

  test('each of the six services has its own marker', () {
    final Set<String> known = <String>{
      for (final int id in <int>[1, 2, 3, 4, 5, 6]) vehicleMarkerAsset(id),
    };
    expect(known, hasLength(6));
    expect(vehicleMarkerAsset(6), 'assets/marker/vehicle_motor.png');
  });

  final List<String> allMarkers = <String>[
    for (final int id in <int>[0, 1, 2, 3, 4, 5, 6]) vehicleMarkerAsset(id),
  ];

  test('every marker image exists and is bundled', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    for (final String path in allMarkers) {
      expect(File(path).existsSync(), isTrue, reason: path);
      // `assets/marker/` is listed as a directory, which bundles every file
      // directly inside it.
      expect(pubspec, contains('- assets/marker/'), reason: path);
    }
  });

  // The marker is drawn in a 30x50 box; an image of any other shape is
  // stretched to fit it (the old ones were about 1:2).
  test('every marker image is 3:5, the shape of the box it is drawn in', () {
    for (final String path in allMarkers) {
      final ByteData header =
          ByteData.sublistView(File(path).readAsBytesSync(), 0, 24);
      // PNG: 8-byte signature, then the IHDR chunk's width and height.
      final int width = header.getUint32(16);
      final int height = header.getUint32(20);
      expect(width * 5, height * 3, reason: '$path is ${width}x$height');
    }
  });
}
