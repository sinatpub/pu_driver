import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tara_driver_application/app/root_main.dart';
import 'package:tara_driver_application/app/service.dart';
import 'package:tara_driver_application/presentation/widgets/custom_animated_loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tara_driver_application/core/api_service/client/dio_http_client.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
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
  // init firebase notification — also initializes Firebase itself, which
  // Crashlytics below depends on
  await NotificationLogic().setupInteractedMessage();

  // F-09 (docs/12): Crashlytics was declared as a dependency but never
  // wired up (docs/05). Disabled in debug builds so local crashes don't
  // pollute production data.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // init local notification
  await NotificationLocal().initLocationNotification();
  await EasyLocalization.ensureInitialized();
  EasyLocalization.logger.enableBuildModes = [];

  // init taxi single ton
  TaxiLocation.shared.onInit();
  // * config easy loading
  configLoading();

  // `14` §3.5: permanent DI lives in exactly one place.
  await initialService();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('km'), Locale('en')],
      path: 'assets/translations',
      startLocale: const Locale('en'),
      child: const Root(),
    ),
  );
}

/// UX-redesign F1: the overlay used to be yellow on green behind a blue mask,
/// which belonged to no palette in the app. It now uses the design tokens
/// (`docs/ux-redesign/02-design-system.md`). Behaviour — duration, dismissal,
/// interaction and the custom animation — is unchanged.
void configLoading() {
  const TaarraaColors colors = TaarraaColors.light;
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = Radii.md
    ..progressColor = colors.actionPrimary
    ..backgroundColor = colors.bgSurface
    ..indicatorColor = colors.actionPrimary
    ..textColor = colors.textPrimary
    ..maskColor = colors.scrim
    ..userInteractions = true
    ..dismissOnTap = true
    ..customAnimation = CustomAnimation();
}
