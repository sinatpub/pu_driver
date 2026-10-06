import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/network/curl_log_interceptor.dart';

/// The API console log: one entry per call — a summary line, the request as
/// a single-line `curl` command, and the response body.
void main() {
  RequestOptions request({
    String method = 'GET',
    String path = '/taxi-driver/wallet',
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Object? data,
  }) =>
      RequestOptions(
        baseUrl: 'https://example.test',
        method: method,
        path: path,
        queryParameters: query,
        headers: headers,
        data: data,
      );

  group('curlCommand', () {
    test('a GET carries its query and its token, on one line', () {
      final String curl = curlCommand(request(
        path: '/taxi-driver/history-drive-info',
        query: <String, dynamic>{'page': 2, 'status': 'done'},
        headers: <String, dynamic>{'Authorization': 'Bearer abc'},
      ));

      expect(
        curl,
        "curl -X GET "
        "'https://example.test/taxi-driver/history-drive-info?page=2&status=done' "
        "-H 'Authorization: Bearer abc'",
      );
      expect(curl.contains('\n'), isFalse);
    });

    test('a JSON body goes in -d, with its content type', () {
      final String curl = curlCommand(request(
        method: 'post',
        path: '/taxi-driver/login-phone',
        data: <String, dynamic>{'phone': '012345678'},
      ));

      expect(
        curl,
        "curl -X POST 'https://example.test/taxi-driver/login-phone' "
        "-H 'Content-Type: application/json' "
        "-d '{\"phone\":\"012345678\"}'",
      );
    });

    test('one content type, however the header was spelled', () {
      final String curl = curlCommand(request(
        method: 'POST',
        headers: <String, dynamic>{
          'content-type': 'application/json',
          'Content-Type': 'application/json',
          'content-length': 21,
        },
        data: <String, dynamic>{'a': 1},
      ));

      expect('application/json'.allMatches(curl).length, 1);
      expect(curl.toLowerCase().contains('content-length'), isFalse);
    });

    test('a single quote in the body cannot end the shell word', () {
      final String curl = curlCommand(request(
        method: 'POST',
        data: <String, dynamic>{'reason': "can't find passenger"},
      ));

      expect(
        curl,
        contains("-d '{\"reason\":\"can'\\''t find passenger\"}'"),
      );
    });

    test('a multipart body is one -F per field, and curl sets the type', () {
      final FormData form = FormData.fromMap(<String, dynamic>{
        'ride_id': '42',
        'profile_image':
            MultipartFile.fromBytes(<int>[1, 2, 3], filename: 'me.jpg'),
      });
      final String curl = curlCommand(request(
        method: 'POST',
        path: '/taxi-driver/register',
        headers: <String, dynamic>{'Content-Type': 'multipart/form-data'},
        data: form,
      ));

      expect(curl, contains("-F 'ride_id=42'"));
      expect(curl, contains("-F 'profile_image=@me.jpg'"));
      expect(curl.toLowerCase().contains('content-type'), isFalse);
      expect(curl.contains(' -d '), isFalse);
    });

    test('a form-urlencoded body is written as pairs', () {
      final String curl = curlCommand(request(
        method: 'POST',
        headers: <String, dynamic>{
          'content-type': Headers.formUrlEncodedContentType,
        },
        data: <String, dynamic>{'phone': '012 345', 'otp_code': '1234'},
      ));

      expect(curl, contains("-d 'phone=012+345&otp_code=1234'"));
    });
  });

  group('CurlLogInterceptor', () {
    late List<String> entries;

    /// A client whose "network" answers [status] with [body], or fails
    /// without a response when [status] is null.
    Dio clientAnswering(int? status, Object? body) =>
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(CurlLogInterceptor(sink: entries.add))
          ..interceptors.add(InterceptorsWrapper(
            onRequest: (RequestOptions options, RequestInterceptorHandler h) {
              if (status == null) {
                return h.reject(
                  DioException.connectionError(
                    requestOptions: options,
                    reason: 'no route to host',
                  ),
                  true,
                );
              }
              final Response<dynamic> response = Response<dynamic>(
                requestOptions: options,
                statusCode: status,
                data: body,
              );
              if (status >= 400) {
                return h.reject(
                  DioException.badResponse(
                    statusCode: status,
                    requestOptions: options,
                    response: response,
                  ),
                  true,
                );
              }
              h.resolve(response, true);
            },
          ));

    setUp(() => entries = <String>[]);

    test('a call is one entry: summary, curl, indented body', () async {
      await clientAnswering(201, <String, dynamic>{
        'data': <String, dynamic>{'seconde': 90},
        'status': true,
      }).post<dynamic>(
        '/taxi-driver/login-phone',
        data: <String, dynamic>{'phone': '012345678'},
      );

      expect(entries, hasLength(1));
      final List<String> lines = entries.single.split('\n');
      expect(
        lines.first,
        matches(r'^201 POST /taxi-driver/login-phone · \d+ ms$'),
      );
      expect(
        lines.elementAt(1),
        startsWith(
            "curl -X POST 'https://example.test/taxi-driver/login-phone' "),
      );
      expect(
        lines.elementAt(1),
        endsWith("-d '{\"phone\":\"012345678\"}'"),
      );
      expect(
        lines.skip(2).join('\n'),
        '{\n'
        '  "data": {\n'
        '    "seconde": 90\n'
        '  },\n'
        '  "status": true\n'
        '}',
      );
    });

    test('a refused call is logged with its status and the server body',
        () async {
      await expectLater(
        clientAnswering(403, <String, dynamic>{
          'message': 'You must be an Driver.',
        }).get<dynamic>('/taxi-driver/get-profile'),
        throwsA(isA<DioException>()),
      );

      expect(entries, hasLength(1));
      expect(entries.single, startsWith('403 GET /taxi-driver/get-profile'));
      expect(entries.single, contains('"message": "You must be an Driver."'));
    });

    test('a call with no response is logged with the reason', () async {
      await expectLater(
        clientAnswering(null, null).get<dynamic>('/taxi-driver/wallet'),
        throwsA(isA<DioException>()),
      );

      expect(entries, hasLength(1));
      final List<String> lines = entries.single.split('\n');
      expect(lines.first, startsWith('ERR connectionError GET '));
      expect(lines.elementAt(1), startsWith('curl -X GET '));
      expect(lines.last, contains('no route to host'));
    });

    test('an empty body says so', () {
      expect(
        apiLogEntry(options: request(), status: '204', body: null),
        endsWith('\n(empty body)'),
      );
    });
  });
}
