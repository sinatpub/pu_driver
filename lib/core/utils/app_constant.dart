import 'package:tara_driver_application/core/config/app_config.dart';
enum ClientMethod { POST, GET, PATCH, DELETE }

class AppConstant {
  // Translate
  static const String khmerCode = "km";
  static const String englishCode = 'en';

  static const String titleApp = 'TAARRAA';

  // F-07: these now delegate to AppConfig, which owns every environment
  // value. Kept as AppConstant members so existing call sites are
  // unaffected — one source of truth, not a second one.
  static const baseUrlApi = AppConfig.apiBaseUrl;
  static const socketBasedUrl = AppConfig.socketBaseUrl;
  static const String customeToken = AppConfig.apiBearerToken;
  static const googleKeyApi = AppConfig.googleMapsApiKey;

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
