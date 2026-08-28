import 'dart:async';

import 'package:dio/dio.dart';
import 'package:tara_driver_application/core/api_service/client/dio_http_client.dart';
import 'package:tara_driver_application/services/session_service.dart';

import 'api_exception.dart';
import 'result.dart';

class ApiClient {
  ApiClient({Dio? dio, SessionService? session})
      : _dio = dio ?? BaseHttpClient.dio,
        _session = session ?? SessionService.instance;

  final Dio _dio;
  final SessionService _session;

  Future<Result<T>> request<T>({
    required String path,
    required String method,
    required T Function(Response response) decode,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    dynamic body,
    bool requiresToken = true,
  }) async {
    try {
      final token = requiresToken ? await _session.getToken() : null;
      final response = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            ...?headers,
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return Result.ok(decode(response));
    } on DioException catch (exception) {
      final apiException = ApiException.fromDioException(exception);
      if (apiException.type == ApiErrorType.unauthorized) {
        unawaited(_session.handleUnauthorized());
      }
      return Result.err(apiException);
    } catch (exception) {
      return Result.err(ApiException.unknown(exception));
    }
  }
}
