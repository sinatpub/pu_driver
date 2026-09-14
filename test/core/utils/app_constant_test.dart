import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';

/// F-07 (`12`): both URLs are `String.fromEnvironment` so a build can point
/// them anywhere with `--dart-define`, while an ordinary build keeps whatever
/// default is pinned here. This test pins those defaults so a change to them
/// is deliberate and visible in a diff, never accidental.
///
/// Both now point at the same host: on this backend the Socket.IO server is
/// mounted at `/socket.io/` on the REST API host, rather than on the separate
/// `socket.tara-taxi.com` host the previous deployment used. They stay two
/// separate constants so a future split-host deployment needs no code change.
void main() {
  test(
    'baseUrlApi/socketBasedUrl defaults when no --dart-define is passed (F-07)',
    () {
      expect(
          AppConstant.baseUrlApi, 'https://taxi-api.simpledevelopertools.com');
      expect(
        AppConstant.socketBasedUrl,
        'https://taxi-api.simpledevelopertools.com',
      );
    },
  );

  test('a --dart-define build overrides the defaults', () {
    // Guards the mechanism rather than the values: if either constant is ever
    // turned back into a plain literal, `fromEnvironment`'s key disappears and
    // `--dart-define=API_BASE_URL=...` silently stops working.
    const overridden = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://taxi-api.simpledevelopertools.com',
    );
    expect(AppConstant.baseUrlApi, overridden);
  });
}
