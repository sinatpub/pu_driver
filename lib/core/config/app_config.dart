/// F-07 (docs/12) — every value this app takes from the build environment,
/// in one place.
///
/// Before this, `String.fromEnvironment` calls were spread across
/// `core/utils/app_constant.dart`, `core/network_config/telegram.dart` and
/// `core/utils/debug_auth_bypass.dart`, so there was no single answer to
/// "what does this build need to be given?" — you had to grep for it.
///
/// The flavor scaffolding half of F-07 (`productFlavors`, per-environment
/// bundle ids) is **not** here: it is blocked on Q-12 (does a staging backend
/// exist) and Q-13 (does this tree build the shipped store binaries). This is
/// the half that does not depend on either answer.
///
/// ## Why the validation below exists
///
/// `String.fromEnvironment('GOOGLE_MAPS_API_KEY')` has no default, so a build
/// that forgets `--dart-define-from-file=dart_defines.json` does not fail —
/// it compiles, installs, launches, and *then* fails every Maps and Places
/// call at runtime with an empty key. That is a slow, confusing failure a
/// long way from its cause. [missingRequiredKeys] turns it into a check the
/// app can run at startup.
library;

class AppConfig {
  const AppConfig._();

  // ---- Backend ----------------------------------------------------------
  // Both default to the current driver backend. The Socket.IO server is
  // mounted at `/socket.io/` on the REST host rather than on a separate host
  // as the old `socket.tara-taxi.com` deployment was (docs/04 §1.2).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://taxi-api.simpledevelopertools.com',
  );

  static const String socketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: 'https://taxi-api.simpledevelopertools.com',
  );

  // ---- Third-party keys, supplied via dart_defines.json ------------------
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// The driver app calls the REST API with a bearer token supplied at build
  /// time. It has no Places key — destination search is passenger-only.
  static const String apiBearerToken =
      String.fromEnvironment('API_BEARER_TOKEN');

  static const String telegramBotToken =
      String.fromEnvironment('TELEGRAM_BOT_TOKEN');

  // ---- Debug-only ------------------------------------------------------
  // Deliberately absent from dart_defines.example.json, matching pu_passenger:
  // this must be opted into explicitly, never inherited from a template.
  static const bool debugOtpBypass =
      bool.fromEnvironment('DEBUG_OTP_BYPASS', defaultValue: false);

  static const String debugLoginPhone =
      String.fromEnvironment('DEBUG_LOGIN_PHONE');

  static const String debugLoginPassword =
      String.fromEnvironment('DEBUG_LOGIN_PASSWORD');

  /// The keys this app cannot function without. The Telegram token is not
  /// here on purpose — it backs error reporting, which degrades quietly
  /// rather than breaking the app.
  static Map<String, String> get requiredKeys => {
        'GOOGLE_MAPS_API_KEY': googleMapsApiKey,
      };

  /// Names of required keys the build was not given. Empty means configured.
  static List<String> get missingRequiredKeys =>
      missingKeysIn(requiredKeys);

  static bool get isConfigured => missingRequiredKeys.isEmpty;
}

/// Which of [values] were not supplied.
///
/// A key is missing when it is empty or whitespace — `--dart-define` cannot
/// express "absent", so an unsupplied key arrives as `''` and a mistyped
/// blank entry in `dart_defines.json` arrives as `' '`. Both are failures,
/// and treating only `''` as missing would let the second through.
///
/// Pure and separate from [AppConfig] so it is testable: the `fromEnvironment`
/// values themselves are compile-time constants and cannot be varied from a
/// unit test.
List<String> missingKeysIn(Map<String, String> values) {
  final missing = <String>[];
  values.forEach((name, value) {
    if (value.trim().isEmpty) missing.add(name);
  });
  return missing;
}
