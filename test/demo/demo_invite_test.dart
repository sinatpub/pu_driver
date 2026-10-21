import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/demo/demo_invite.dart';
import 'package:pu_taxi_driver/mock/mock_fixtures.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/invite_feature.dart';

/// DD-55 — the invite feature shown on the real backend with made-up data.
/// Only the referral calls are answered here; the wallet is always exactly
/// what the "real backend" returns.
void main() {
  /// What the stand-in for the real backend was asked.
  late List<String> reachedBackend;
  late bool demoOn;
  late Dio dio;

  /// The real wallet as the backend sent it on 2026-10-06, trimmed.
  Map<String, dynamic> realWallet() => <String, dynamic>{
        'status': true,
        'message': 'Success',
        'data': <String, dynamic>{
          'id': 1,
          'balance': 0,
          'debted': '-5.00',
          'commission_fare': 5,
          'currency': 'KHR',
          'transactions': <dynamic>[
            <String, dynamic>{
              'id': 2,
              'type': 2,
              'type_name': 'payment',
              'amount': 0,
              'currency': 'KHR',
              'status': 1,
              'status_name': 'pending',
              'created_at': '2026-10-06T14:57:23.000000Z',
            },
          ],
        },
      };

  setUp(() {
    reachedBackend = <String>[];
    demoOn = true;
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(DemoInviteInterceptor(
        isActive: () => demoOn,
        clock: () => DateTime(2026, 10, 6, 12),
        latency: Duration.zero,
      ))
      // The "real backend": knows the wallet, and no referral route.
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler h) {
          reachedBackend.add(options.uri.path);
          if (options.uri.path.endsWith('/taxi-driver/wallet')) {
            return h.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: realWallet(),
              ),
              true,
            );
          }
          h.reject(
            DioException.badResponse(
              statusCode: 404,
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 404,
                data: <String, dynamic>{'message': 'Incorect route'},
              ),
            ),
            true,
          );
        },
      ));
  });

  Future<Map<String, dynamic>> referral() async =>
      ((await dio.get<dynamic>('/taxi-driver/referral')).data
          as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  Future<Map<String, dynamic>> wallet() async =>
      ((await dio.get<dynamic>('/taxi-driver/wallet')).data
          as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  Future<Response<dynamic>> transfer(num amount, String requestId) =>
      dio.post<dynamic>(
        '/taxi-driver/referral/transfer',
        data: <String, dynamic>{'amount': amount, 'request_id': requestId},
      );

  test('off by default: no build has the demo unless it asks', () {
    expect(DemoInvite.enabled, isFalse);
    expect(DemoInvite.isActive, isFalse);
  });

  test('the invite feature is on without the demo: the backend serves it',
      () {
    expect(inviteFeatureEnabled, isTrue);
  });

  test('the referral is answered here and never reaches the backend', () async {
    final Map<String, dynamic> data = await referral();

    expect(data['code'], MockData.inviteCode);
    expect(data['link'], contains(MockData.inviteCode));
    expect(data['invitees'], isNotEmpty);
    expect(data['rewards'], isNotEmpty);
    expect(data['reward_balance'], greaterThan(0));
    expect(reachedBackend, isEmpty);
  });

  test('the sign-up code check knows the demo inviters', () async {
    final String known = MockData.inviters.keys.first;
    final Response<dynamic> yes = await dio.get<dynamic>(
      '/taxi-driver/referral/check-code',
      queryParameters: <String, dynamic>{'code': known.toLowerCase()},
    );
    final Response<dynamic> no = await dio.get<dynamic>(
      '/taxi-driver/referral/check-code',
      queryParameters: <String, dynamic>{'code': 'NOBODY1'},
    );

    expect((yes.data as Map)['data']['valid'], isTrue);
    expect((yes.data as Map)['data']['inviter_name'], MockData.inviters[known]);
    expect((no.data as Map)['data']['valid'], isFalse);
    expect(reachedBackend, isEmpty);
  });

  test('a transfer lowers the reward balance and leaves the wallet alone',
      () async {
    final int before = (await referral())['reward_balance'] as int;

    final Response<dynamic> done = await transfer(1000, 'r-1');
    expect((done.data as Map)['data']['transferred'], 1000);

    final Map<String, dynamic> after = await referral();
    expect(after['reward_balance'], before - 1000);
    expect((after['transfers'] as List).single['amount'], 1000);

    // The wallet is the real one, with no demo transfer added.
    expect(await wallet(), realWallet()['data']);
  });

  test('the same request sent twice moves the money once', () async {
    final int before = (await referral())['reward_balance'] as int;
    await transfer(500, 'same-id');
    final Response<dynamic> again = await transfer(500, 'same-id');

    expect((again.data as Map)['message'], 'Already transferred');
    expect((await referral())['reward_balance'], before - 500);
  });

  test('an amount that cannot be moved is refused, with the reason', () async {
    final int available = (await referral())['reward_balance'] as int;

    for (final num bad in <num>[0, -5, 10.5, available + 1]) {
      await expectLater(
        transfer(bad, 'bad-$bad'),
        throwsA(
          isA<DioException>().having(
            (DioException e) => e.response?.statusCode,
            'status',
            422,
          ),
        ),
        reason: 'amount $bad',
      );
    }
    expect((await referral())['reward_balance'], available);
  });

  test('with no transfer made, the wallet is exactly what the backend sent',
      () async {
    expect(await wallet(), realWallet()['data']);
  });

  test('every other call goes to the backend untouched', () async {
    await expectLater(
      dio.get<dynamic>('/taxi-driver/get-profile'),
      throwsA(isA<DioException>()),
    );
    expect(reachedBackend, <String>['/taxi-driver/get-profile']);
  });

  test('switched off, the referral calls go to the backend like any other',
      () async {
    demoOn = false;

    await expectLater(
      dio.get<dynamic>('/taxi-driver/referral'),
      throwsA(isA<DioException>()),
    );
    expect(reachedBackend, <String>['/taxi-driver/referral']);
    expect(await wallet(), realWallet()['data']);
  });
}
