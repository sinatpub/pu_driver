import 'dart:io';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:tara_driver_application/core/utils/status_util.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../main.dart';

class NotificationLocal {
  static bool _isRequestingPermission = false;
  static final notifications = FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    '${AppConstant.titleApp}_notification_v2',
    '${AppConstant.titleApp} Driver',
    description: 'Channel for ${AppConstant.titleApp} notifications',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('booking_sound'),
  );

  // * Init Local Notification
  Future<void> initLocationNotification() async {
    // Initialize the plugin for both iOS and Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create the notification channel for Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    tlog("Init Local Notification");
  }

  // 3. Request Permission Method
  Future<bool> requestPermission() async {
    if (_isRequestingPermission) {
      tlog("Permission request already in progress — skipping duplicate.");
      return true; // Prevents multiple simultaneous requests
    }

    _isRequestingPermission = true;
    bool permissionGranted = false;

    try {
      if (Platform.isIOS || Platform.isMacOS) {
        final iosPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        permissionGranted = await iosPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      } else if (Platform.isAndroid) {
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          permissionGranted =
              await androidPlugin.requestNotificationsPermission() ?? false;
        } else {
          permissionGranted = true; // older Android versions automatically true
        }
      }

      tlog("Notification permission granted: $permissionGranted");
    } catch (e, st) {
      tlog("Error requesting permission: $e\n$st");
    } finally {
      _isRequestingPermission = false;
    }

    return permissionGranted;
  }

  static Future<void> notificationBooking(
      {required AndroidNotificationChannel channel,
      required FlutterLocalNotificationsPlugin plugin,
      required String title,
      bool useCustomSound = false,
      String? description}) async {
    const int notificationId = FcmType.request;

    /// This is very important :
    /// If you're want to custom sound notification, you need to change channel ID based on you want to custom sound notification
    final channelId = useCustomSound ? 'booking_urgent' : 'booking_normal';
    // Cancel any existing notifications with the same ID
    await plugin.cancel(notificationId);
    // Android Notification Details
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      useCustomSound ? 'Urgent Booking' : 'Booking',
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      sound: useCustomSound
          ? const RawResourceAndroidNotificationSound('booking_sound')
          : null,
      playSound: true,
      autoCancel: true,
      icon: "@mipmap/ic_launcher",
      enableLights: useCustomSound,
      enableVibration: useCustomSound,
      ongoing: false,
      channelShowBadge: true,
      fullScreenIntent: false,
      ticker: 'Booking',
    );

    // iOS Notification Details
    DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentSound: useCustomSound,
      presentBadge: useCustomSound,
      presentAlert: useCustomSound,
      sound: useCustomSound ? 'booking_sound.wav' : null,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    // await plugin.cancelAll();
    // Show the notification
    await plugin.show(
      notificationId,
      title,
      description,
      platformChannelSpecifics,
    );
  }
}
