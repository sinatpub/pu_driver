import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:pu_taxi_driver/core/helper/local_notification_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A ride request that comes as a push while the app is not running (DD-58).
///
/// The socket brings requests to a running app. A push is the only thing that
/// reaches a phone whose app Android has closed. The backend sends it as a
/// **data-only** FCM message, `notification_type: service_booking`, with the
/// same fields the socket sends; this file turns it into the booking sound
/// and notification, which go away when the request times out.
///
/// A message that carries its own `notification` block is shown by Android
/// itself, so it is left alone here: one request, one alert.

/// Whether [data] is a ride request this app has to announce itself.
bool isRideRequestToAnnounce(
  Map<String, dynamic> data, {
  required bool shownBySystem,
}) =>
    data['notification_type'] == 'service_booking' && !shownBySystem;

/// How long the passenger waits for an answer: `timeout`, in seconds.
Duration rideRequestTimeout(Map<String, dynamic> data) {
  final int? seconds = int.tryParse('${data['timeout']}');
  return Duration(
    seconds: seconds == null || seconds <= 0 ? _defaultTimeoutSeconds : seconds,
  );
}

/// What the request screen itself assumes when the backend sends none.
const int _defaultTimeoutSeconds = 30;

/// The alert's two lines in the driver's language.
///
/// The handler runs in its own isolate, where the app's translations are not
/// loaded, so they are read here: the language the driver last chose
/// ([savedLocale], the key `easy_localization` writes), Khmer when they never
/// chose. Anything that fails falls back to English.
Future<({String title, String body})> loadRideAlertText({
  required Future<String?> Function() savedLocale,
  required Future<String> Function(String assetPath) loadAsset,
}) async {
  try {
    final String language = (await savedLocale() ?? 'km').split('_').first;
    final Object? strings = jsonDecode(
      await loadAsset('assets/translations/$language.json'),
    );
    if (strings is Map<String, dynamic>) {
      final Object? title = strings['NEWREQUEST'];
      final Object? body = strings['DESREQUEST'];
      if (title is String && body is String) return (title: title, body: body);
    }
  } catch (_) {
    // Falls through to English.
  }
  return (
    title: 'New ride request',
    body: 'A passenger is waiting for your answer.',
  );
}

/// Registered with `FirebaseMessaging.onBackgroundMessage`.
@pragma('vm:entry-point')
Future<void> onBackgroundPush(RemoteMessage message) async {
  final bool announce = isRideRequestToAnnounce(
    message.data,
    shownBySystem: message.notification != null,
  );
  // One line per push in `adb logcat -s flutter`, so a test on a phone can
  // tell "no push came" from "a push came and was not a ride request". The
  // type only: the rest of a request is the passenger's data.
  debugPrint(
    'ride push: notification_type=${message.data['notification_type']} '
    'shownBySystem=${message.notification != null} announced=$announce',
  );
  if (!announce) return;
  WidgetsFlutterBinding.ensureInitialized();
  final ({String title, String body}) text = await loadRideAlertText(
    savedLocale: () async =>
        (await SharedPreferences.getInstance()).getString('locale'),
    loadAsset: rootBundle.loadString,
  );
  await NotificationLocal.notificationBooking(
    channel: NotificationLocal.channel,
    plugin: NotificationLocal.notifications,
    title: text.title,
    description: text.body,
    useCustomSound: true,
    timeoutAfter: rideRequestTimeout(message.data),
  );
}
