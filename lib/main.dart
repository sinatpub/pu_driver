import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tara_driver_application/app/root_main.dart';
import 'package:tara_driver_application/presentation/widgets/custom_animated_loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tara_driver_application/core/api_service/client/dio_http_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tara_driver_application/services/notification_logic.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi_location.dart';
import 'core/helper/local_notification_helper.dart';

@pragma('vm:entry-point')
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  BaseHttpClient.init();
  WidgetsFlutterBinding.ensureInitialized();
  // init firebase notification
  await NotificationLogic().setupInteractedMessage();

  // init local notification
  await NotificationLocal().initLocationNotification();
  await EasyLocalization.ensureInitialized();
  EasyLocalization.logger.enableBuildModes = [];

  // init taxi single ton
  TaxiLocation.shared.onInit();
  // * config easy loading
  configLoading();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('km'), Locale('en')],
      path: 'assets/translations',
      startLocale: const Locale('en'),
      child: const Root(),
    ),
  );
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withValues(alpha: 0.5)
    ..userInteractions = true
    ..dismissOnTap = true
    ..customAnimation = CustomAnimation();
}
