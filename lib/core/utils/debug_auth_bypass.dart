import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:pu_taxi_driver/core/config/app_config.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/core/storage/get_storages.dart';
import 'package:pu_taxi_driver/core/storage/set_storages.dart';
import 'package:pu_taxi_driver/data/models/register_model.dart';
import 'package:pu_taxi_driver/services/session_service.dart';

/// The password login the bypass signs in with: `AuthRepository.passwordLogin`.
/// Passed in rather than imported, so this file does not reach up into a
/// screen's data layer.
typedef DebugPasswordLogin = Future<Result<RegisterModel>> Function({
  required String phone,
  required String password,
  required String deviceToken,
  required String platform,
});

/// A development-only shortcut past OTP verification, so the screens *behind*
/// login (drawer, home, trip) can be exercised on an emulator without a real
/// SMS round-trip.
///
/// **A release build does not have it unless it asks twice.** It requires:
///
/// 1. `--dart-define=DEBUG_OTP_BYPASS=true` — off unless a build explicitly
///    asks for it. Deliberately **not** in `dart_defines.example.json`.
/// 2. `kDebugMode` — the constant is `false` in profile/release, so the whole
///    branch is tree-shaken out of a shipped binary —
///    **or** `--dart-define=DEBUG_LOGIN_IN_RELEASE=true`, for a test APK
///    (DD-56). That second flag is passed on the command line of that one
///    build and kept out of `dart_defines.json`, so an ordinary release build
///    never carries the login, or the test account's password, by accident.
///
/// It has two doors: the login page's button ([loginLabel]), and typing
/// [bypassCode] on the OTP screen.
///
/// Either one performs a **real** password login against
/// `POST /taxi-driver/login` — an endpoint the driver app does not otherwise
/// use. That endpoint answers with the same body as `verify-phone-otp` (the
/// driver and a token), and the result is kept the same way a verified OTP
/// is, so everything downstream talks to the backend as that driver.
/// Credentials come from `--dart-define`, never from source;
/// `dart_defines.json` is gitignored, which is where they belong.
class DebugAuthBypass {
  DebugAuthBypass._();

  static const bypassCode = '0000';

  static const _enabledByDefine = AppConfig.debugOtpBypass;
  static const _phone = AppConfig.debugLoginPhone;
  static const _password = AppConfig.debugLoginPassword;

  /// Sent as `device_token` when the phone has no FCM token yet. The app
  /// registers the real one right after sign-in, through `push-device-token`.
  static const _noDeviceToken = 'debug-login';

  static const _allowedInRelease = AppConfig.debugLoginInRelease;

  static bool get isEnabled =>
      _enabledByDefine && (kDebugMode || _allowedInRelease);

  static bool accepts(String otpCode) => isEnabled && otpCode == bypassCode;

  /// The login page's debug button. Kept here, not in the translation files:
  /// it is developer tooling and no driver ever sees it.
  static const loginLabel = 'Debug login';

  /// Which account the button signs in as, so nobody has to open
  /// `dart_defines.json` to find out.
  static String get loginCaption => _phone.isEmpty
      ? '$_buildKind. DEBUG_LOGIN_PHONE is not set.'
      : '$_buildKind. Signs in as $_phone.';

  /// Says what the person is holding: a test APK is not a debug build.
  static const String _buildKind =
      kDebugMode ? 'Debug build only' : 'Test build, not for release';

  /// Why the last [seedSession] failed, for the screen that asked; the log
  /// has the same text. Null after a success.
  static String? lastError;

  /// Signs in for real through [login] and keeps the driver and the token as
  /// a verified OTP does. Returns true when a session was obtained; false
  /// (with [lastError] and a log line saying why) otherwise.
  static Future<bool> seedSession(DebugPasswordLogin login) async {
    if (!isEnabled) return false;
    lastError = null;
    if (_phone.isEmpty || _password.isEmpty) {
      return _fail('DEBUG_LOGIN_PHONE / DEBUG_LOGIN_PASSWORD are unset. '
          'Add them to dart_defines.json (gitignored).');
    }

    final String? fcmToken = await StorageGet.getFcmTokenLocal();
    final result = await login(
      phone: _phone,
      password: _password,
      deviceToken:
          fcmToken == null || fcmToken.isEmpty ? _noDeviceToken : fcmToken,
      platform: Platform.isIOS ? 'ios' : 'android',
    );

    return result.when(
      ok: (RegisterModel model) async {
        final String? token = model.data?.token;
        final Driver? driver = model.data?.driver;
        // The same rule the OTP screen applies: a session is a driver and a
        // token together.
        if (token == null || token.isEmpty || driver == null) {
          return _fail(model.message ?? 'Login returned no driver session.');
        }
        await SessionService.instance.saveToken(token);
        await StorageSet.storeDriverData(model);
        debugPrint(
          '[DebugAuthBypass] signed in as ${driver.name} (id=${driver.id}).',
        );
        return true;
      },
      err: (error) async => _fail(error.message),
    );
  }

  static bool _fail(String reason) {
    lastError = reason;
    debugPrint('[DebugAuthBypass] no session: $reason');
    return false;
  }
}
