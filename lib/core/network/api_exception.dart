import 'dart:io';

import 'package:dio/dio.dart';

enum ApiErrorType { connection, timeout, badResponse, unauthorized, unknown }

class ApiException implements Exception {
  const ApiException({required this.type, required this.message, this.statusCode});

  final ApiErrorType type;
  final String message;
  final int? statusCode;

  factory ApiException.fromDioException(DioException exception) {
    if (exception.error is SocketException) {
      return const ApiException(
        type: ApiErrorType.connection,
        message: 'Connection error. Please check your internet connection.',
      );
    }
    if (exception.type == DioExceptionType.connectionTimeout) {
      return const ApiException(
        type: ApiErrorType.timeout,
        message: 'Connection timed out. Please try again later.',
      );
    }
    if (exception.type == DioExceptionType.badResponse) {
      final status = exception.response?.statusCode;
      final data = exception.response?.data;
      final serverMessage =
          (data is Map ? data['message'] as String? : null) ?? 'Unexpected error occurred.';
      final isAuthError = status == 401 || status == 403;
      return ApiException(
        type: isAuthError ? ApiErrorType.unauthorized : ApiErrorType.badResponse,
        message: serverMessage,
        statusCode: status,
      );
    }
    return const ApiException(type: ApiErrorType.unknown, message: 'Unexpected error occurred.');
  }

  factory ApiException.unknown(Object error) =>
      const ApiException(type: ApiErrorType.unknown, message: 'Something went wrong. Please try again.');

  @override
  String toString() => message;
}
