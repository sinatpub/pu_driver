import 'package:tara_driver_application/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// F-07 (docs/12). `String.fromEnvironment` has no way to express "absent" —
/// an unsupplied key arrives as an empty string. A build that forgets
/// `--dart-define-from-file=dart_defines.json` therefore compiles, installs,
/// launches, and only then fails every Maps and Places call with an empty
/// key. These pin the check that turns that into a startup-time answer.
void main() {
  group('missingKeysIn', () {
    test('a fully supplied config reports nothing missing', () {
      expect(
        missingKeysIn({'GOOGLE_MAPS_API_KEY': 'abc', 'OTHER': 'def'}),
        isEmpty,
      );
    });

    test('an unsupplied key arrives as empty and is reported', () {
      expect(
        missingKeysIn({'GOOGLE_MAPS_API_KEY': '', 'OTHER': 'def'}),
        ['GOOGLE_MAPS_API_KEY'],
      );
    });

    test('a whitespace-only value counts as missing', () {
      // A blank entry mistyped into dart_defines.json arrives as ' ', which
      // would pass an `isEmpty` check and then fail at runtime anyway.
      expect(missingKeysIn({'GOOGLE_MAPS_API_KEY': '   '}),
          ['GOOGLE_MAPS_API_KEY']);
    });

    test('every missing key is reported, not just the first', () {
      expect(
        missingKeysIn({'A': '', 'B': 'ok', 'C': ''}),
        ['A', 'C'],
      );
    });

    test('an empty config is vacuously complete', () {
      expect(missingKeysIn({}), isEmpty);
    });
  });

  group('AppConfig', () {
    test('the backend defaults are present without any dart-define', () {
      // These carry defaultValue, so they must never be empty even on a
      // bare `flutter run`.
      expect(AppConfig.apiBaseUrl, isNotEmpty);
      expect(AppConfig.socketBaseUrl, isNotEmpty);
      expect(AppConfig.apiBaseUrl, startsWith('https://'));
      expect(AppConfig.socketBaseUrl, startsWith('https://'));
    });

    test('the debug OTP bypass is off unless explicitly opted into', () {
      // This test runs without --dart-define, which is the shape of a
      // release build. It must be false here or the gate is not a gate.
      expect(AppConfig.debugOtpBypass, isFalse);
    });

    test('requiredKeys covers the keys the app cannot work without', () {
      expect(AppConfig.requiredKeys.keys, contains('GOOGLE_MAPS_API_KEY'));
    });

    test('the driver has no Places key — destination search is passenger-only',
        () {
      expect(
          AppConfig.requiredKeys.containsKey('GOOGLE_PLACES_API_KEY'), isFalse);
    });

    test(
        'the Telegram token is deliberately not required — error reporting '
        'degrades quietly rather than breaking the app', () {
      expect(AppConfig.requiredKeys.containsKey('TELEGRAM_BOT_TOKEN'), isFalse);
    });
  });
}
