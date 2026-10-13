import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/services/ride_push_alert.dart';

/// DD-58 — a ride request pushed while the app is not running.
void main() {
  group('which push is announced by the app', () {
    test('a data-only ride request', () {
      expect(
        isRideRequestToAnnounce(
          <String, dynamic>{'notification_type': 'service_booking'},
          shownBySystem: false,
        ),
        isTrue,
      );
    });

    test('not one Android has already shown: one request, one alert', () {
      expect(
        isRideRequestToAnnounce(
          <String, dynamic>{'notification_type': 'service_booking'},
          shownBySystem: true,
        ),
        isFalse,
      );
    });

    test('not an announcement or anything else', () {
      expect(
        isRideRequestToAnnounce(
          <String, dynamic>{'notification_type': 'news'},
          shownBySystem: false,
        ),
        isFalse,
      );
      expect(
        isRideRequestToAnnounce(<String, dynamic>{}, shownBySystem: false),
        isFalse,
      );
    });
  });

  group('how long the alert stays', () {
    test('the timeout the backend sends; FCM data is always text', () {
      expect(
        rideRequestTimeout(<String, dynamic>{'timeout': '15'}),
        const Duration(seconds: 15),
      );
      expect(
        rideRequestTimeout(<String, dynamic>{'timeout': 20}),
        const Duration(seconds: 20),
      );
    });

    test('30 seconds when it sends none, or nonsense', () {
      for (final Object? timeout in <Object?>[null, '', 'soon', '0', '-5']) {
        expect(
          rideRequestTimeout(<String, dynamic>{'timeout': timeout}),
          const Duration(seconds: 30),
          reason: '$timeout',
        );
      }
    });
  });

  group('the words of the alert', () {
    const Map<String, String> assets = <String, String>{
      'assets/translations/km.json':
          '{"NEWREQUEST": "km title", "DESREQUEST": "km body"}',
      'assets/translations/en.json':
          '{"NEWREQUEST": "en title", "DESREQUEST": "en body"}',
    };

    Future<({String title, String body})> load(String? locale) =>
        loadRideAlertText(
          savedLocale: () async => locale,
          loadAsset: (String path) async => assets[path]!,
        );

    test('Khmer for a driver who never chose a language', () async {
      expect(await load(null), (title: 'km title', body: 'km body'));
    });

    test('the language the driver chose', () async {
      expect(await load('en'), (title: 'en title', body: 'en body'));
      expect(await load('en_US'), (title: 'en title', body: 'en body'));
      expect(await load('km'), (title: 'km title', body: 'km body'));
    });

    test('English when the translations cannot be read', () async {
      final ({String title, String body}) text = await load('fr');
      expect(text.title, 'New ride request');
      expect(text.body, isNotEmpty);
    });
  });

  test('the real translation files have both lines', () async {
    for (final String language in <String>['km', 'en']) {
      final ({String title, String body}) text = await loadRideAlertText(
        savedLocale: () async => language,
        // Tests run from the package root, where `assets/` is.
        loadAsset: (String path) => File(path).readAsString(),
      );
      expect(text.title, isNot('New ride request'), reason: language);
    }
  });
}
