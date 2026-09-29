// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';

/// User-facing network error messages, in the active language.
///
/// These were English constants, so a driver using Khmer saw English errors.
/// They are getters rather than constants so each read picks up the current
/// locale.
class ErrorMessage {
  static String get SOMETHING_WRONG => 'ERROR_SOMETHING_WRONG'.tr();
  static String get CONNECTION_ERROR => 'ERROR_CONNECTION'.tr();
  static String get TIMEOUT_ERROR => 'CONNECTION_TIMED_OUT'.tr();
  static String get UNEXPECTED_ERROR => 'ERROR_UNEXPECTED'.tr();
  static String get SERVER_ERROR => 'ERROR_SERVER_UNAVAILABLE'.tr();
}
