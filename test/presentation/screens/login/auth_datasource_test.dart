import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/network/api_client.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/data/models/register_model.dart';
import 'package:pu_taxi_driver/presentation/screens/login/data/datasource/auth_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/login/data/repository/auth_repository.dart';

/// The debug login's request (`DebugAuthBypass`): `POST /taxi-driver/login`,
/// which answers with the same body as `verify-phone-otp`.
///
/// The response below is the shape the backend returned on 2026-10-06, as
/// far as it was seen; the token is made up.
void main() {
  late RequestOptions sent;

  AuthRepository repositoryAnswering(int status, Map<String, dynamic> body) {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          sent = options;
          final Response<dynamic> response = Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: body,
          );
          if (status >= 400) {
            handler.reject(DioException(
              requestOptions: options,
              response: response,
              type: DioExceptionType.badResponse,
            ));
          } else {
            handler.resolve(response);
          }
        },
      ));
    return AuthRepository(AuthDatasource(apiClient: ApiClient(dio: dio)));
  }

  setUp(() {
    // A token from an earlier session must not ride along on a sign-in.
    FlutterSecureStorage.setMockInitialValues({'session_token': 'stale'});
  });

  test('passwordLogin posts the four fields, without a token', () async {
    final AuthRepository auth = repositoryAnswering(201, <String, dynamic>{
      'data': <String, dynamic>{
        'driver': <String, dynamic>{
          'id': 2,
          'driver_id': 'DRV0001',
          'name': 'Dummy Driver',
          'last_name': 'Driver',
          'first_name': 'Dummy',
          'email': 'driver@example.com',
          'gender': 0,
          'dob': '',
          'country_code': '+855',
        },
        'token': 'made-up-token',
      },
      'status': true,
      'message': 'success',
    });

    final Result<RegisterModel> result = await auth.passwordLogin(
      phone: '012345678',
      password: 'not-a-real-password',
      deviceToken: 'device-1',
      platform: 'android',
    );

    expect(sent.method, 'POST');
    expect(sent.path, '/taxi-driver/login');
    expect(sent.data, <String, dynamic>{
      'phone': '012345678',
      'password': 'not-a-real-password',
      'device_token': 'device-1',
      'platform': 'android',
    });
    expect(sent.headers.containsKey('Authorization'), isFalse);

    final RegisterModel model = (result as Ok<RegisterModel>).value;
    expect(model.data?.token, 'made-up-token');
    expect(model.data?.driver?.id, 2);
    expect(model.data?.driver?.name, 'Dummy Driver');
  });

  test('a refused login carries the server message', () async {
    final AuthRepository auth = repositoryAnswering(422, <String, dynamic>{
      'data': null,
      'status': false,
      'message': 'User does not exist',
    });

    final Result<RegisterModel> result = await auth.passwordLogin(
      phone: '012345678',
      password: 'not-a-real-password',
      deviceToken: 'device-1',
      platform: 'android',
    );

    expect((result as Err<RegisterModel>).error.message, 'User does not exist');
  });
}
