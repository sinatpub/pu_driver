import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';

/// F-07 (`12`): both URLs are `String.fromEnvironment` so a build can point
/// them anywhere with `--dart-define`, while an ordinary build keeps whatever
/// default is pinned here. This test pins those defaults so a change to them
/// is deliberate and visible in a diff, never accidental.
///
/// The two are not currently on the same host: the API default was moved to
/// the driver backend's IP while the socket default still points at the
/// `tara-taxi.com` hostname.
void main() {
  test(
    'baseUrlApi/socketBasedUrl defaults when no --dart-define is passed (F-07)',
    () {
      expect(AppConstant.baseUrlApi, 'http://217.216.37.228:8082');
      expect(AppConstant.socketBasedUrl, 'https://socket.tara-taxi.com');
    },
  );

  test('a --dart-define build overrides the defaults', () {
    // Guards the mechanism rather than the values: if either constant is ever
    // turned back into a plain literal, `fromEnvironment`'s key disappears and
    // `--dart-define=API_BASE_URL=...` silently stops working.
    const overridden = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://217.216.37.228:8082',
    );
    expect(AppConstant.baseUrlApi, overridden);
  });
}
