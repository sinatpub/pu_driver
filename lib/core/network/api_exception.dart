import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

/// `unauthorized` means the session itself is gone (401) and the user must sign in
/// again. `forbidden` (403) means the session is valid but the account may not do
/// this — a role/permission error — and must **not** clear the token: see
/// `.agent/TODO.md`, where a valid driver token on a non-driver account was being
/// discarded mid-session.
enum ApiErrorType {
  connection,
  timeout,
  badResponse,
  unauthorized,
  forbidden,
  unknown
}

class ApiException implements Exception {
  const ApiException(
      {required this.type, required this.message, this.statusCode});

  final ApiErrorType type;
  final String message;
  final int? statusCode;

  /// The one place that decides whether a failure should end the session.
  /// Only a 401 does: a 403 is "this account may not do this", and clearing a
  /// still-valid token on it bounces the user to login mid-session.
  bool get endsSession => type == ApiErrorType.unauthorized;

  factory ApiException.fromDioException(DioException exception) {
    if (exception.error is SocketException) {
      return ApiException(
        type: ApiErrorType.connection,
        message: 'NO_INTERNET_CONNECTION'.tr(),
      );
    }
    if (exception.type == DioExceptionType.connectionTimeout) {
      return ApiException(
        type: ApiErrorType.timeout,
        message: 'CONNECTION_TIMED_OUT'.tr(),
      );
    }
    if (exception.type == DioExceptionType.badResponse) {
      final status = exception.response?.statusCode;
      final data = exception.response?.data;
      final serverMessage = (data is Map ? data['message'] as String? : null) ??
          'PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG'.tr();
      return ApiException(
        type: _typeForStatus(status),
        message: serverMessage,
        statusCode: status,
      );
    }
    return ApiException(
        type: ApiErrorType.unknown,
        message: 'PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG'.tr());
  }

  static ApiErrorType _typeForStatus(int? status) {
    switch (status) {
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      default:
        return ApiErrorType.badResponse;
    }
  }

  factory ApiException.unknown(Object error) => ApiException(
      type: ApiErrorType.unknown,
      message: 'PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG'.tr());

  @override
  String toString() => message;
}
