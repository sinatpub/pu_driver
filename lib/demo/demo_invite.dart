import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pu_taxi_driver/core/utils/money.dart';
import 'package:pu_taxi_driver/mock/mock_fixtures.dart';
import 'package:pu_taxi_driver/mock/mock_mode.dart';

/// Invite QR, rewards and "transfer to balance", shown on the **real**
/// backend with made-up data (DD-55).
///
/// The backend has no referral routes yet, so against it the feature is
/// hidden (`invite_feature.dart`). This is for showing it to someone before
/// those routes exist: everything else in the app stays real — sign-in,
/// trips, the wallet — and only the invite feature is answered from here.
///
/// **Off unless a build asks for it**, with `--dart-define=DEMO_INVITE=true`
/// (or the same key in `dart_defines.json`). It is a compile-time constant:
/// in a build without the flag all of this is dead code. Unlike QA mock mode
/// it is allowed in a release build, so a demo APK can be handed over — which
/// is also why the flag must never be in a build that ships.
///
/// **What is made up:** the invite code and link, the invited people, the
/// rewards, and the transfers. A transfer moves no real money, and the
/// wallet always shows exactly what the real backend reports.
///
/// The data starts over each time the app starts.
class DemoInvite {
  const DemoInvite._();

  static const bool enabled = bool.fromEnvironment('DEMO_INVITE');

  /// QA mock mode already serves the whole feature; this stands aside.
  static bool get isActive => enabled && !MockMode.isActive;
}

/// Answers the three referral calls from made-up data. Every other request
/// goes to the network untouched.
class DemoInviteInterceptor extends Interceptor {
  DemoInviteInterceptor({
    @visibleForTesting bool Function()? isActive,
    @visibleForTesting DateTime Function()? clock,
    @visibleForTesting Duration latency = const Duration(milliseconds: 350),
  })  : _isActive = isActive ?? (() => DemoInvite.isActive),
        _now = clock ?? DateTime.now,
        _latency = latency;

  final bool Function() _isActive;
  final DateTime Function() _now;

  /// A made-up answer that arrives instantly looks made up.
  final Duration _latency;

  /// The transfers made in this run of the app, oldest first.
  final List<Map<String, dynamic>> _transfers = <Map<String, dynamic>>[];

  /// Request id → amount moved, so one transfer sent twice moves once.
  final Map<String, int> _requests = <String, int>{};

  Map<String, dynamic> get _referral =>
      MockData.referral(now: _now(), transfers: _transfers);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isActive()) return handler.next(options);

    final String path = options.uri.path;
    final Map<String, dynamic>? answer;
    if (path.endsWith('/taxi-driver/referral')) {
      answer = _ok('Success', _referral);
    } else if (path.endsWith('/taxi-driver/referral/check-code')) {
      answer = _checkCode(options);
    } else if (path.endsWith('/taxi-driver/referral/transfer')) {
      answer = _transfer(options);
    } else {
      return handler.next(options);
    }

    await Future<void>.delayed(_latency);
    final Response<dynamic> response = Response<dynamic>(
      requestOptions: options,
      statusCode: answer['status'] == true ? 200 : 422,
      data: answer,
    );
    if (answer['status'] == true) {
      // `true`: let the API log, earlier in the chain, see the answer too.
      handler.resolve(response, true);
    } else {
      handler.reject(
        DioException.badResponse(
          statusCode: 422,
          requestOptions: options,
          response: response,
        ),
        true,
      );
    }
  }

  Map<String, dynamic> _ok(String message, Object? data) =>
      <String, dynamic>{'status': true, 'message': message, 'data': data};

  Map<String, dynamic> _refused(String message) =>
      <String, dynamic>{'status': false, 'message': message};

  Map<String, dynamic> _checkCode(RequestOptions options) {
    final String code =
        '${options.uri.queryParameters['code'] ?? options.queryParameters['code'] ?? ''}'
            .trim()
            .toUpperCase();
    final String? inviter = MockData.inviters[code];
    return _ok('Success', <String, dynamic>{
      'valid': inviter != null,
      'inviter_name': inviter,
    });
  }

  /// The rules the real route is specified with: an amount above zero, in
  /// whole units, not more than the reward balance; a request id seen before
  /// is answered again without moving anything.
  Map<String, dynamic> _transfer(RequestOptions options) {
    final Object? body = options.data;
    final Map<dynamic, dynamic> fields =
        body is Map ? body : const <dynamic, dynamic>{};
    final String requestId = '${fields['request_id'] ?? ''}';
    final int available = _referral['reward_balance'] as int;

    final int? repeated = _requests[requestId];
    if (repeated != null) {
      return _ok('Already transferred', <String, dynamic>{
        'transferred': repeated,
        'reward_balance': available,
      });
    }

    final num? asked = parseMoney(fields['amount']);
    if (asked == null || asked <= 0 || asked != asked.roundToDouble()) {
      return _refused('Invalid amount');
    }
    final int amount = asked.round();
    if (amount > available) return _refused('More than the reward balance');

    _transfers.add(<String, dynamic>{
      'id': _transfers.length + 1,
      'amount': amount,
      'created_at': MockData.timestamp(_now()),
    });
    if (requestId.isNotEmpty) _requests[requestId] = amount;
    return _ok('Transferred', <String, dynamic>{
      'transferred': amount,
      'reward_balance': available - amount,
    });
  }
}
