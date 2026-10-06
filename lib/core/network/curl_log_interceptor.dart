import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Logs each API call as one console entry a developer can copy from:
///
/// ```text
/// [api] 201 POST /taxi-driver/login-phone · 184 ms
/// curl -X POST 'https://host/taxi-driver/login-phone' -H 'content-type: application/json' -d '{"phone":"012345678"}'
/// {
///   "data": { "seconde": 90 },
///   "status": true
/// }
/// ```
///
/// - The first line says what happened: status, method, path, time.
/// - The second is the request as a **single-line** `curl` command, so one
///   copy takes all of it into a terminal or Postman's cURL import.
/// - The rest is the response body, indented.
///
/// The entry is written when the call ends, so a request and its response
/// stay together however many calls are in flight. A call that fails without
/// a response (no connection, timeout) is logged with the reason instead of
/// a status.
///
/// It goes through `dart:developer`'s `log`, not `print`: the console shows
/// it without a `I/flutter (1234):` prefix on every line, and a long body is
/// not cut off.
///
/// **Debug and profile builds only** — see `BaseHttpClient.init`. An entry
/// holds the bearer token and the request body, which is what makes the
/// command runnable and also why no release build may write one.
class CurlLogInterceptor extends Interceptor {
  CurlLogInterceptor({void Function(String entry)? sink})
      : _sink = sink ?? _toConsole;

  final void Function(String entry) _sink;

  /// When each request started. Keyed by the request itself, so nothing is
  /// written into the request that goes on the wire.
  static final Expando<Stopwatch> _started = Expando<Stopwatch>();

  static void _toConsole(String entry) => developer.log(entry, name: 'api');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _started[options] = Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _sink(apiLogEntry(
      options: response.requestOptions,
      status: '${response.statusCode ?? '???'}',
      body: response.data,
      elapsed: _started[response.requestOptions]?.elapsed,
    ));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final Response<dynamic>? response = err.response;
    _sink(apiLogEntry(
      options: err.requestOptions,
      status: response?.statusCode?.toString() ?? 'ERR ${err.type.name}',
      body: response != null
          ? response.data
          : (err.message ?? err.error?.toString() ?? 'No response'),
      elapsed: _started[err.requestOptions]?.elapsed,
    ));
    handler.next(err);
  }
}

/// One console entry for a finished call: summary line, `curl` line, body.
String apiLogEntry({
  required RequestOptions options,
  required String status,
  required Object? body,
  Duration? elapsed,
}) {
  final String time = elapsed == null ? '' : ' · ${elapsed.inMilliseconds} ms';
  return '$status ${options.method.toUpperCase()} ${options.uri.path}$time\n'
      '${curlCommand(options)}\n'
      '${_readableBody(body)}';
}

/// [options] as a single-line `curl` command.
///
/// A JSON body goes in `-d`, a multipart one as one `-F` per field. A file
/// is written as `@<its name>`: the path it was read from is not kept on the
/// request, so the command needs that one edit before it will run.
String curlCommand(RequestOptions options) {
  final Object? data = options.data;
  final bool multipart = data is FormData;
  final List<String> parts = <String>[
    'curl',
    '-X',
    options.method.toUpperCase(),
    _quote(options.uri.toString()),
  ];

  // By lower-case name: Dio's own `content-type` and a caller's
  // `Content-Type` are one header, and curl would send both.
  final Map<String, String> headers = <String, String>{};
  options.headers.forEach((String name, dynamic value) {
    final String key = name.toLowerCase();
    if (value == null || key == 'content-length') return;
    // curl writes this one itself for `-F`, with the boundary it picks.
    if (multipart && key == 'content-type') return;
    headers[key] = '$name: $value';
  });
  if (!multipart &&
      (data is Map || data is List) &&
      !headers.containsKey('content-type')) {
    headers['content-type'] = 'Content-Type: ${Headers.jsonContentType}';
  }
  for (final String header in headers.values) {
    parts
      ..add('-H')
      ..add(_quote(header));
  }

  if (data is FormData) {
    for (final MapEntry<String, String> field in data.fields) {
      parts
        ..add('-F')
        ..add(_quote('${field.key}=${field.value}'));
    }
    for (final MapEntry<String, MultipartFile> file in data.files) {
      parts
        ..add('-F')
        ..add(_quote('${file.key}=@${file.value.filename ?? 'file'}'));
    }
  } else if (data is Map || data is List) {
    final bool urlEncoded = (headers['content-type'] ?? '')
        .contains(Headers.formUrlEncodedContentType);
    parts
      ..add('-d')
      ..add(_quote(
        urlEncoded && data is Map
            ? Transformer.urlEncodeMap(<String, dynamic>{
                for (final MapEntry<dynamic, dynamic> pair in data.entries)
                  '${pair.key}': pair.value,
              })
            : _json(data, indent: false),
      ));
  } else if (data is String && data.isNotEmpty) {
    parts
      ..add('-d')
      ..add(_quote(data));
  }

  return parts.join(' ');
}

/// [text] as one shell word. A single quote inside it closes the word, adds
/// an escaped quote, and opens it again.
String _quote(String text) => "'${text.replaceAll("'", r"'\''")}'";

String _readableBody(Object? body) {
  if (body == null || (body is String && body.isEmpty)) return '(empty body)';
  if (body is Map || body is List) return _json(body, indent: true);
  if (body is String) {
    try {
      return _json(jsonDecode(body), indent: true);
    } on FormatException {
      return body;
    }
  }
  return body.toString();
}

String _json(Object? value, {required bool indent}) {
  try {
    return indent
        ? const JsonEncoder.withIndent('  ').convert(value)
        : jsonEncode(value);
  } on JsonUnsupportedObjectError {
    return value.toString();
  }
}
