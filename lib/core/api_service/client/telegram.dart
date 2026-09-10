import 'package:tara_driver_application/core/config/app_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/app_log.dart';

Future<void> sendToTelegram(String message, {String? platform}) async {
  String chatId = '858455855';
  // Supplied via `--dart-define-from-file=dart_defines.json`
  String botToken = AppConfig.telegramBotToken;

  var url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
  // Prepare the request body
  var body = jsonEncode({
    'chat_id': chatId,
    'parse_mode': 'HTML',
    'text': "Driver: $message",
  });
  // Send the request
  try {
    var response = await http.post(
      url,
      body: body,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      xLog(message: 'Message sent successfully');
    } else {
      xLog(message: 'Failed to send message: ${response.statusCode}');
    }
  } catch (e) {
    xLog(message: 'Error sending message: $e');
  }
}
