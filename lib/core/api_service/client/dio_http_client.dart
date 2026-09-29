import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/mock/mock_http_interceptor.dart';
import 'package:tara_driver_application/mock/mock_mode.dart';

class BaseHttpClient {
  static late final Dio dio;

  static void init() {
    final BaseOptions options = BaseOptions(
      baseUrl: AppConstant.baseUrlApi,
      connectTimeout: const Duration(minutes: 1),
      receiveTimeout: const Duration(minutes: 1),
    );

    dio = Dio()
      ..options = options
      ..interceptors.add(PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          compact: false,
          error: true,
          request: true));

    // QA mock mode (`lib/mock/`). `MockMode.enabled` is a compile-time
    // constant that is false in every release build, so this is dead code
    // there. The interceptor passes requests through when mock mode was
    // switched off at runtime.
    if (MockMode.enabled) dio.interceptors.add(MockHttpInterceptor());
  }
}

////
// class V2ApiClient {
//   static late final Dio dio;
//   static void init() {
//     final BaseOptions options = BaseOptions(
//       baseUrl: AppConfig.BASE_URL,
//       connectTimeout: const Duration(minutes: 1),
//       receiveTimeout: const Duration(minutes: 1),
//     );
//
//     dio = Dio()
//       ..options = options
//       ..interceptors.add(PrettyDioLogger(
//         requestHeader: true,
//         requestBody: true,
//         responseBody: true,
//         responseHeader: false,
//         compact: false,
//         error: true,
//       ));
//   }
// }

const JsonDecoder decoder = JsonDecoder();
const JsonEncoder encoder = JsonEncoder.withIndent('  ');
