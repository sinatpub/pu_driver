import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tara_driver_application/core/storage/get_storages.dart';
import 'package:tara_driver_application/core/storage/remove_storage.dart';
import 'package:tara_driver_application/core/storage/set_storages.dart';

/// DD-37 — the at-pickup waiting timer survives an app restart.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('reads back the arrival for the same booking', () async {
    final DateTime at = DateTime.fromMillisecondsSinceEpoch(1790000000000);
    await StorageSet.setArrivedAt(990001, at);

    expect(await StorageGet.getArrivedAt(990001), at);
  });

  test('ignores an arrival saved for another booking', () async {
    await StorageSet.setArrivedAt(990001, DateTime.now());

    expect(await StorageGet.getArrivedAt(990002), isNull);
  });

  test('is gone once removed', () async {
    await StorageSet.setArrivedAt(990001, DateTime.now());
    await StorageRemove.removeArrivedAt();

    expect(await StorageGet.getArrivedAt(990001), isNull);
  });
}
