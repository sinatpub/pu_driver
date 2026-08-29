import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/routing/route_arguments.dart';
import '../core/utils/app_log.dart';
import '../taxi_single_ton/taxi.dart';

class NotificationLogic {
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  static late AndroidNotificationChannel androidNotificationChannel;

  Future<void> setupInteractedMessage() async {
    await Firebase.initializeApp();
    await registerNotification();
    await initializeNotification();
    await disableIOSForegroundBanner();
  }

  // Android: As Default it is not display banner in foreground
  // iOS: It is automatic display banner in any life cycle of app
  static Future<void> disableIOSForegroundBanner() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );
  }

  static Future<void> initializeNotification() async {
    // Handle foreground messages | while running
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      xLog(message: "🧑🏽‍💻 Handle foreground");
      // showNotificationMessage(message);
      if (message.data['notification_type'] != 'service_booking') {
        handleOnNotificationPress(message.data,
            remoteNotification: message.notification,
            message: message,
            durationRoute: 1);
      }
    });

    // Handle background messages | not running but still alive
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      xLog(message: "🧑🏽‍💻 Handle background");
      handleOnNotificationPress(message.data,
          remoteNotification: message.notification,
          message: message,
          durationRoute: 6);
    });

    // Handle terminated messages | not alive

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      xLog(message: "🧑🏽‍💻 Handle terminated");
      handleOnNotificationPress(initialMessage.data,
          isTerminate: true, message: initialMessage, durationRoute: 6);
    }
    // FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    //   xLog(message: "🧑🏽‍💻 Handle terminated");
    //   if (message != null) {
    //     handleOnNotificationPress(message.data,
    //         isTerminate: true, message: message, durationRoute: 6);
    //   }
    // });
    // Request permission for iOS
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        provisional: true,
        criticalAlert: true,
        sound: true,
        providesAppNotificationSettings: true,
      );
    } catch (e) {
      xPrettyLog(message: "firebaseMessaging.requestPermission $e");
    }
  }

  static Future<void> showNotificationMessage(RemoteMessage message) async {
    // Customize how you want to handle the message
    xLog(
      message: 'RemoteMessage'
          '\nNotification title: ${message.notification?.title}'
          '\nNotification body: ${message.notification?.body}'
          '\nNotification: ${message.notification}'
          '\nMessage data: ${message.data}',
    );
    if (message.notification != null) {
      RemoteNotification? notification = message.notification;
      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          iOS: const DarwinNotificationDetails(
            // sound: "booking_sound.wav",
            presentBadge: true,
            interruptionLevel: InterruptionLevel.critical,
            presentBanner: true,
            presentList: true,
            presentSound: true,
            // criticalSoundVolume: 1,
            presentAlert: true,
          ),
          android: AndroidNotificationDetails(
            androidNotificationChannel.id,
            androidNotificationChannel.name,
            // "${message.notification?.title}",
            // "${message.notification?.body}",
            // sound: const RawResourceAndroidNotificationSound("booking_sound"),
            playSound: true,
            silent: false,
            enableVibration: true,
            channelShowBadge: true,
            onlyAlertOnce: false,
            importance: Importance.max,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
          ),
        ),
      );
      xPrettyLog(
        message: "Android Alert Notification: ${notification.toString()}",
      );
    }
  }

  static Future<void> registerNotification() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    androidNotificationChannel = const AndroidNotificationChannel(
      "booking_channel", // id
      'High Importance Notifications', // title
      importance: Importance.max,
      showBadge: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound("booking_sound"),
      playSound: true,
      enableVibration: true,
    );
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
    //android
    const androidSetting = AndroidInitializationSettings("@mipmap/ic_launcher");
    // ios
    const iOSSetting = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentSound: true,
      defaultPresentList: true,
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestCriticalPermission: true,
      requestProvisionalPermission: true,
      requestSoundPermission: true,
    );
    //
    const initSetting = InitializationSettings(
      android: androidSetting,
      iOS: iOSSetting,
    );
    flutterLocalNotificationsPlugin.initialize(
      initSetting,
      onDidReceiveNotificationResponse: (message) {
        Map<String, dynamic> payload = jsonDecode(message.payload!);
        handleOnNotificationPress(payload);
      },
    );
  }

  static Future<void> handleOnNotificationPress(
    Map<String, dynamic> payload, {
    int? durationRoute,
    bool isTerminate = false,
    RemoteNotification? remoteNotification,
    RemoteMessage message = const RemoteMessage(),
  }) async {
    xPrettyLog(
        message:
            "handleOnNotificationPress: $payload - ${remoteNotification.toString()}");
    // Taxi.shared.notifyBooking(
    //     title: remoteNotification?.title ?? "",
    //     description: remoteNotification?.body);
    await routeByNotificationTime(message, durationRoute!,
        isTerminate: isTerminate);
  }
}

Future<void> routeByNotificationTime(RemoteMessage message, int durationRoute,
    {bool isTerminate = false}) async {
  final passengerRaw = jsonDecode(message.data['passenger']);
  final locationRaw = jsonDecode(message.data['location']);
  final destinationRaw = jsonDecode(message.data['destination']);

  /// This is just delays for make sure context is fully completed
  /// Why return; empty because home page is handle for navigation already
  if (isTerminate == true) {
    await Future.delayed(Duration(seconds: 2));
    return;
  }
  await Future.delayed(Duration(seconds: durationRoute), () {
    if (message.data['notification_type'] == 'service_booking') {
      Get.toNamed(
        AppRoutes.booking,
        arguments: BookingScreenArgs(
          latStart: 0.0,
          lngStart: 0.0,
          startTime: "",
          refreshApp: false,
          typeVehicleId: int.parse(message.data["vehicleType"].toString()),
          pricrVehicle: int.parse(message.data["vehiclePrice"].toString()),
          namePassanger: passengerRaw["name"],
          phonePassanger: passengerRaw["phone"],
          imagePassanger: passengerRaw["profile"],
          timeOut: int.parse(message.data["timeout"].toString()),
          processStepBook: 1,
          bookingCode: int.parse(message.data["booking_code"]),
          bookingId: int.parse(message.data["booking_id"]),
          latPassenger: double.parse(locationRaw['latitude'].toString()),
          lngPassenger: double.parse(locationRaw['longitude'].toString()),
          desLatPassenger: destinationRaw['latitude'],
          desLngPassenger: destinationRaw['longitude'],
          passengerId: int.parse(message.data["passengerId"]),
        ),
      );
    } else {
      Get.toNamed(
        AppRoutes.notificationDetail,
        arguments: NotificationDetailArgs(
          notificationId: message.data["notification_id"],
          appOpened: false,
        ),
      );
    }
  });
}
