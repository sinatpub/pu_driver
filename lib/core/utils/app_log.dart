import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logs simple debug messages with custom formatting.
/// Displays the file path and line number. Works only in `kDebugMode`.
void xLog({
  required String message,
  String? region,
  bool isFullPrint = false,
  bool isNeedStackTrace = false,
}) {
  if (kDebugMode) {
    const maxWidth = 200;
    final border = '=' * maxWidth;
    final header = region != null ? '🔍 [$region]' : '🐛 LOG';
    final callerInfo = _getCallerInfo();

    if (isFullPrint) {
      // Print a full line and the entire message as-is
      debugPrint(
        '\n$border\n$header File: ${callerInfo['file']} (line ${callerInfo['line']})\n\n$message\n$border\n',
      );
    } else {
      final formattedMessage = message.length > maxWidth
          ? _formatMessage(message, maxWidth)
          : message;
      final stackTrace =
          isNeedStackTrace ? '\nStackTrace:\n${StackTrace.current}' : '';

      debugPrint(
        '\n$border\n$header\nFile: ${callerInfo['file']} (line ${callerInfo['line']})\n$formattedMessage$stackTrace\n$border\n',
      );
    }
  }
}

/// Logs detailed debug messages using the `Logger` package.
/// Displays the file path, line number, and timestamp. Works only in `kDebugMode`.
void xPrettyLog({
  required String message,
  String? region,
  bool isNeedStackTrace = false,
}) {
  if (kDebugMode) {
    final callerInfo = _getCallerInfo();
    const maxWidth = 200;
    final border = '=' * maxWidth;
    final header = region != null ? '🔍 [$region]' : '🐛 PRETTY LOG';
    final formattedMessage =
        message.length > maxWidth ? _formatMessage(message, maxWidth) : message;
    final stackTrace =
        isNeedStackTrace ? '\nStackTrace:\n${StackTrace.current}' : '';

    Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        lineLength: maxWidth,
        printEmojis: true,
        printTime: true,
        colors: true,
      ),
    ).d(
      '\n$border\n$header\nFile: ${callerInfo['file']} (line ${callerInfo['line']})\n$formattedMessage$stackTrace\n$border\n',
    );
  }
}

/// Helper function to format messages with a specified width.
String _formatMessage(String message, int maxWidth) {
  final buffer = StringBuffer();
  for (int i = 0; i < message.length; i += maxWidth) {
    buffer.writeln(
      message.substring(
          i, i + maxWidth > message.length ? message.length : i + maxWidth),
    );
  }
  return buffer.toString();
}

/// Extracts the caller's full file path and line number from the stack trace.
Map<String, String> _getCallerInfo() {
  final trace = StackTrace.current.toString().split("\n");
  if (trace.length < 3) return {'file': 'unknown', 'line': 'unknown'};

  final targetLine = trace[2];
  final regex = RegExp(r'^(#\d+\s+)(.+?):(\d+):(\d+)');
  final match = regex.firstMatch(targetLine);

  if (match != null) {
    String filePath = match.group(2) ?? 'unknown';
    String lineNumber = match.group(3) ?? 'unknown';

    return {'file': filePath, 'line': lineNumber};
  }
  return {'file': 'unknown', 'line': 'unknown'};
}
