import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/utils/load_custom_marker.dart';

/// The home map crashed a profile/release build on its first GPS fix: the
/// vehicle type was still 0, the marker asset path was "", and Google Maps
/// threw `'asset' cannot open asset:` on the main thread.
void main() {
  test('every vehicle type, known or not, has a marker image', () {
    for (final int id in <int>[-1, 0, 1, 2, 3, 4, 5, 6, 99]) {
      expect(vehicleMarkerAsset(id), isNotEmpty, reason: 'type $id');
    }
  });

  test('unknown types fall back to the classic car', () {
    expect(vehicleMarkerAsset(0), fallbackVehicleMarkerAsset);
    expect(vehicleMarkerAsset(6), fallbackVehicleMarkerAsset);
  });

  test('every marker image exists and is bundled', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    for (final int id in <int>[0, 1, 2, 3, 4, 5]) {
      final String path = vehicleMarkerAsset(id);
      expect(File(path).existsSync(), isTrue, reason: path);
      // `assets/marker/` is listed as a directory, which bundles every file
      // directly inside it.
      expect(pubspec, contains('- assets/marker/'), reason: path);
    }
  });
}
