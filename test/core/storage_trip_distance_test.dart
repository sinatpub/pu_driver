import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pu_taxi_driver/core/storage/get_storages.dart';
import 'package:pu_taxi_driver/core/storage/key_storages.dart';
import 'package:pu_taxi_driver/core/storage/remove_storage.dart';
import 'package:pu_taxi_driver/core/storage/set_storages.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The trip meter survives an app restart. Found on a real trip,
/// 2026-10-06: the app was restarted mid-ride and the screen went back to
/// "0 m · $0.50", because the distance driven lived only in the trip screen.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<void> save(int bookingId, double meters) => StorageSet.setTripDistance(
        bookingId,
        meters: meters,
        latitude: 11.5259032,
        longitude: 104.9233525,
      );

  test('reads back the metres and the point they were counted at', () async {
    await save(4, 1234.567);

    final saved = await StorageGet.getTripDistance(4);
    expect(saved?.meters, 1234.567);
    expect(saved?.lastPoint, const LatLng(11.5259032, 104.9233525));
  });

  test('a later save replaces the earlier one', () async {
    await save(4, 500);
    await save(4, 1750.25);

    expect((await StorageGet.getTripDistance(4))?.meters, 1750.25);
  });

  test('ignores a distance saved for another booking', () async {
    await save(4, 1234);

    expect(await StorageGet.getTripDistance(5), isNull);
  });

  test('is gone once removed: the next ride starts at zero', () async {
    await save(4, 1234);
    await StorageRemove.removeTripDistance();

    expect(await StorageGet.getTripDistance(4), isNull);
  });

  test('nothing saved, or something unreadable, is no distance at all',
      () async {
    expect(await StorageGet.getTripDistance(4), isNull);

    for (final String broken in <String>[
      '4|abc|11.5|104.9',
      '4|1200',
      '4|-5|11.5|104.9',
      '4|1200|north|104.9',
      '',
    ]) {
      SharedPreferences.setMockInitialValues(
        <String, Object>{StorageKeys.tripDistance: broken},
      );
      expect(
        await StorageGet.getTripDistance(4),
        isNull,
        reason: 'saved text: "$broken"',
      );
    }
  });
}
