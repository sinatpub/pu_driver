enum ClientMethod { POST, GET, PATCH, DELETE }

class AppConstant {
  // Translate
  static const String khmerCode = "km";
  static const String englishCode = 'en';

  static const String titleApp = 'TAARRAA';

  // Based Url — overridable via `--dart-define=API_BASE_URL=...`
  // (F-07, docs/12); default points at the current driver backend.
  static const baseUrlApi = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://taxi-api.simpledevelopertools.com',
  );

  // Socket IO Client — overridable via `--dart-define=SOCKET_BASE_URL=...`.
  // Same host as the REST API on this backend: the Socket.IO server is
  // mounted at `/socket.io/` on `baseUrlApi` rather than on a separate
  // host as the old `socket.tara-taxi.com` deployment was (docs/04 §1.2).
  static const socketBasedUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: 'https://taxi-api.simpledevelopertools.com',
  );

  // Custom Token — supplied via `--dart-define-from-file=dart_defines.json`
  static const String customeToken = String.fromEnvironment(
    'API_BEARER_TOKEN',
  );
  static const googleKeyApi = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const String playStoreUrl =
      "https://play.google.com/store/apps/details?id=com.tara.driver_application";
  static const String appStoreUrl =
      "https://apps.apple.com/kh/app/taarraa-driver/id6742987404";

  /// Marker
  static const String driverMarker = "DriverMarkerId";

  // Padding Constant
  static const double padding01 = 6.0;
  static const double padding02 = 8.0;
  static const double padding03 = 12.0;
  static const double padding04 = 16.0;
  static const double padding05 = 18.0;
  static const double padding06 = 20.0;

  // Margin Constant
  static const double margin01 = 6.0;
  static const double margin02 = 8.0;
  static const double margin03 = 12.0;
  static const double margin04 = 16.0;
  static const double margin05 = 18.0;
  static const double margin06 = 20.0;
}
