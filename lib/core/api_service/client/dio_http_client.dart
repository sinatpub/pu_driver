import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:pu_taxi_driver/core/network/curl_log_interceptor.dart';
import 'package:pu_taxi_driver/core/utils/app_constant.dart';
import 'package:pu_taxi_driver/demo/demo_invite.dart';
import 'package:pu_taxi_driver/mock/mock_http_interceptor.dart';
import 'package:pu_taxi_driver/mock/mock_mode.dart';

class BaseHttpClient {
  static late final Dio dio;

  static void init() {
    final BaseOptions options = BaseOptions(
      baseUrl: AppConstant.baseUrlApi,
      connectTimeout: const Duration(minutes: 1),
      receiveTimeout: const Duration(minutes: 1),
    );

    dio = Dio()..options = options;

    // Each call as a copyable `curl` line and its response. Not in a release
    // build: an entry holds the bearer token and the request body. It goes
    // first so it also sees what the mock backend below answers.
    if (!kReleaseMode) dio.interceptors.add(CurlLogInterceptor());

    // DD-55: a demo build answers the invite feature's calls with made-up
    // data; everything else still goes to the real backend. A compile-time
    // constant, false unless the build passes `DEMO_INVITE=true`.
    if (DemoInvite.enabled) dio.interceptors.add(DemoInviteInterceptor());

    // QA mock mode (`lib/mock/`). `MockMode.enabled` is a compile-time
    // constant that is false in every release build, so this is dead code
    // there. The interceptor passes requests through when mock mode was
    // switched off at runtime.
    if (MockMode.enabled) dio.interceptors.add(MockHttpInterceptor());
  }
}

const JsonDecoder decoder = JsonDecoder();
const JsonEncoder encoder = JsonEncoder.withIndent('  ');
