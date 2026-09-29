import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tara_driver_application/mock/mock_backend.dart';
import 'package:tara_driver_application/mock/mock_mode.dart';
import 'package:tara_driver_application/mock/mock_timings.dart';

/// Answers requests on the shared Dio client (`BaseHttpClient.dio`) from
/// [MockBackend] instead of the network. Both HTTP stacks in the app —
/// `ApiClient` and the legacy `BaseApiService` — use that client, so every
/// datasource, repository and model runs unchanged above this.
///
/// Failures are produced as the same `DioException` shapes the real network
/// produces, so `ApiException.fromDioException` and the legacy error mapper
/// classify them exactly as they would in production.
class MockHttpInterceptor extends Interceptor {
  MockHttpInterceptor({
    MockBackend? backend,
    @visibleForTesting bool Function()? isActive,
    @visibleForTesting Duration Function(String path)? latency,
  })  : _backend = backend,
        _isActive = isActive ?? (() => MockMode.isActive),
        _latency = latency;

  final MockBackend? _backend;
  final bool Function() _isActive;
  final Duration Function(String path)? _latency;
  MockBackend get backend => _backend ?? MockBackend.instance;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isActive()) return handler.next(options);

    final uri = options.uri;
    final request = MockRequest(
      method: options.method,
      path: uri.path,
      query: {...uri.queryParameters, ...options.queryParameters},
      body: bodyToMap(options.data),
      authenticated: options.headers['Authorization'] != null,
    );

    await Future<void>.delayed((_latency ?? _latencyFor)(request.path));

    try {
      final reply = await backend.handle(request);
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: reply.statusCode,
        data: reply.data,
      );
      if (reply.isSuccess) {
        handler.resolve(response, true);
      } else {
        handler.reject(
          DioException.badResponse(
            statusCode: reply.statusCode,
            requestOptions: options,
            response: response,
          ),
          true,
        );
      }
    } on MockConnectionFailure {
      handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: 'QA mock: NETWORK_ERROR scenario',
          error: const SocketException('QA mock: NETWORK_ERROR scenario'),
        ),
        true,
      );
    }
  }

  Duration _latencyFor(String path) {
    final Duration base;
    if (path.contains('login') ||
        path.contains('otp') ||
        path.endsWith('/register')) {
      base = MockTimings.authLatency;
    } else if (path.endsWith('/accept-payment')) {
      base = MockTimings.paymentLatency;
    } else if (RegExp(
            r'(confirm-drive-request|cancel-drive|drive-arrive|start-drive|complete-drive)$')
        .hasMatch(path)) {
      base = MockTimings.tripActionLatency;
    } else if (path.endsWith('/update-driver-location')) {
      return MockTimings.minLatency;
    } else {
      base = MockTimings.latency;
    }
    final scaled = MockMode.scaled(base);
    return scaled < MockTimings.minLatency ? MockTimings.minLatency : scaled;
  }

  /// A request body as a flat map, whichever shape the caller sent: a map
  /// (`ApiClient`), `FormData` (trip actions, location updates), or nothing.
  static Map<String, dynamic> bodyToMap(Object? data) {
    if (data is Map) return data.map((k, v) => MapEntry('$k', v));
    if (data is FormData) {
      return {for (final field in data.fields) field.key: field.value};
    }
    return const {};
  }
}
