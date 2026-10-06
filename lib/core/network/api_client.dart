import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:pu_taxi_driver/core/api_service/client/dio_http_client.dart';
import 'package:pu_taxi_driver/services/session_service.dart';

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
      if (apiException.endsSession) {
        unawaited(_session.handleUnauthorized());
      }
      return Result.err(apiException);
    } catch (exception, stack) {
      // The response arrived but could not be read: almost always a field
      // whose type is not what a model declares. Callers show a generic
      // message, or nothing at all, so without this line the failure has no
      // trace anywhere.
      developer.log(
        'Could not read the response of $method $path',
        name: 'api',
        error: exception,
        stackTrace: stack,
      );
      return Result.err(ApiException.unknown(exception));
    }
  }
}
