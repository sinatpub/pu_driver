import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/utils/app_version.dart';

/// Audit D-11 — the update check reads the installed version and prompts
/// only for a newer one.
void main() {
  group('isNewerVersion', () {
    test('a newer server version prompts', () {
      expect(isNewerVersion('1.2.0', installed: '1.1.9'), isTrue);
      expect(isNewerVersion('1.10.0', installed: '1.9.9'), isTrue);
      expect(isNewerVersion('2', installed: '1.9.9'), isTrue);
      expect(isNewerVersion('1.1.9.1', installed: '1.1.9'), isTrue);
    });

    test('the same or an older one does not', () {
      expect(isNewerVersion('1.1.9', installed: '1.1.9'), isFalse);
      expect(isNewerVersion('1.1.9', installed: '1.1.9+1191'), isFalse);
      expect(isNewerVersion('1.1.8', installed: '1.1.9'), isFalse,
          reason: "a tester's newer build is not told to downgrade");
      expect(isNewerVersion('1.1', installed: '1.1.0'), isFalse);
    });

    test('a missing or malformed version does not', () {
      expect(isNewerVersion(null, installed: '1.1.9'), isFalse);
      expect(isNewerVersion('', installed: '1.1.9'), isFalse);
      expect(isNewerVersion('null', installed: '1.1.9'), isFalse);
      expect(isNewerVersion('1.2.0', installed: ''), isFalse,
          reason: 'the installed version could not be read');
    });
  });

  group('AppVersion.load', () {
    tearDown(() => AppVersion.current = '');

    test('keeps what the build says', () async {
      await AppVersion.load(read: () async => '1.1.9');
      expect(AppVersion.current, '1.1.9');
    });

    test('a failed read leaves it empty', () async {
      await AppVersion.load(read: () async => throw Exception('no plugin'));
      expect(AppVersion.current, '');
    });
  });
}
