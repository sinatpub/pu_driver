import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/network/api_exception.dart';

DioException _badResponse(int status, {dynamic data}) {
  final options = RequestOptions(path: '/taxi-driver/profile');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  group('status → error type', () {
    test('401 is unauthorized — the session is gone', () {
      final exception = ApiException.fromDioException(_badResponse(401));
      expect(exception.type, ApiErrorType.unauthorized);
      expect(exception.statusCode, 401);
    });

    test(
        '403 is forbidden, not unauthorized — a role error is not a dead session',
        () {
      final exception = ApiException.fromDioException(_badResponse(403));
      expect(exception.type, ApiErrorType.forbidden);
      expect(exception.statusCode, 403);
    });

    test('other 4xx/5xx stay badResponse', () {
      expect(ApiException.fromDioException(_badResponse(400)).type,
          ApiErrorType.badResponse);
      expect(ApiException.fromDioException(_badResponse(404)).type,
          ApiErrorType.badResponse);
      expect(ApiException.fromDioException(_badResponse(500)).type,
          ApiErrorType.badResponse);
    });

    test('the server message survives on a 403', () {
      // The exact body observed on device 2026-09-06 against /taxi-driver/*
      // with an Admin-role token.
      final exception = ApiException.fromDioException(
        _badResponse(403, data: {'message': 'You must be an Driver.'}),
      );
      expect(exception.message, 'You must be an Driver.');
    });
  });

  group('endsSession — who gets logged out', () {
    test('only unauthorized ends the session', () {
      for (final type in ApiErrorType.values) {
        expect(
          ApiException(type: type, message: '').endsSession,
          type == ApiErrorType.unauthorized,
          reason: '$type',
        );
      }
    });

    test('a 403 does not end the session', () {
      expect(ApiException.fromDioException(_badResponse(403)).endsSession,
          isFalse);
    });
  });
}
