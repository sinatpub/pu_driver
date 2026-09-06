import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/services/session_service.dart';

/// A development-only shortcut past OTP verification, so the screens *behind*
/// login (drawer, home, trip) can be exercised on an emulator without a real
/// SMS round-trip.
///
/// **This cannot be switched on in a release build.** It requires all three:
///
/// 1. `kDebugMode` — the constant is `false` in profile/release, so the whole
///    branch is tree-shaken out of a shipped binary.
/// 2. `--dart-define=DEBUG_OTP_BYPASS=true` — off unless a build explicitly
///    asks for it. Deliberately **not** in `dart_defines.example.json`.
/// 3. The typed code matching [bypassCode].
///
/// On a match it performs a **real** password login against `POST /taxi/login`
/// — an endpoint the driver app does not otherwise use — and caches the token
/// and user it returns, so everything downstream talks to the backend as that
/// account. Credentials come from `--dart-define`, never from source;
/// `dart_defines.json` is gitignored, which is where they belong.
class DebugAuthBypass {
  DebugAuthBypass._();

  static const bypassCode = '0000';

  /// Where the cached login user lands, for anything that wants to inspect it.
  static const userCacheKey = 'debug_bypass_user';

  static const _enabledByDefine =
      bool.fromEnvironment('DEBUG_OTP_BYPASS', defaultValue: false);
  static const _phone = String.fromEnvironment('DEBUG_LOGIN_PHONE');
  static const _password = String.fromEnvironment('DEBUG_LOGIN_PASSWORD');

  static bool get isEnabled => kDebugMode && _enabledByDefine;

  static bool accepts(String otpCode) => isEnabled && otpCode == bypassCode;

  static Map<String, dynamic>? _cachedUser;

  /// The user object from the bypass login, once [seedSession] has run.
  static Map<String, dynamic>? get cachedUser => _cachedUser;

  /// Logs in for real and caches the result. Returns true when a token was
  /// obtained; false (with a log line saying why) otherwise.
  static Future<bool> seedSession() async {
    if (!isEnabled) return false;
    if (_phone.isEmpty || _password.isEmpty) {
      debugPrint(
        '[DebugAuthBypass] OTP bypassed, but DEBUG_LOGIN_PHONE / '
        'DEBUG_LOGIN_PASSWORD are unset — no session. Add them to '
        'dart_defines.json (gitignored).',
      );
      return false;
    }

    final result = await ApiClient().request<Map<String, dynamic>>(
      path: '/taxi/login',
      method: 'POST',
      requiresToken: false,
      body: {'phone': _phone, 'password': _password},
      decode: (response) => Map<String, dynamic>.from(response.data as Map),
    );

    return await result.when(
      ok: (json) async {
        final data = json['data'] as Map<String, dynamic>?;
        final token = data?['token'] as String?;
        if (token == null || token.isEmpty) {
          debugPrint('[DebugAuthBypass] login returned no token: $json');
          return false;
        }
        await SessionService.instance.saveToken(token);
        await _cacheUser(data?['user']);
        debugPrint(
          '[DebugAuthBypass] logged in as '
          '${_cachedUser?['name']} (id=${_cachedUser?['id']}, '
          'role_id=${_cachedUser?['role_id']}); token cached.',
        );
        return true;
      },
      err: (error) async {
        debugPrint('[DebugAuthBypass] login failed: ${error.message}');
        return false;
      },
    );
  }

  static Future<void> _cacheUser(Object? user) async {
    if (user is! Map) return;
    _cachedUser = Map<String, dynamic>.from(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userCacheKey, _cachedUser.toString());
  }
}
