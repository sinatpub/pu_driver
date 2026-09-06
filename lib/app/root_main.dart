import 'package:tara_driver_application/routes/app_pages.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/check_platform_device.dart';
import 'package:tara_driver_application/services/navigation_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      gestures: const [GestureType.onTap, GestureType.onPanUpdateDownDirection],
      child: GetMaterialApp(
        builder: (BuildContext context, Widget? child) {
          // `EasyLoading.init()` RETURNS the TransitionBuilder that installs
          // the overlay — it has to wrap `child`, not be called and thrown
          // away. Discarding it left `overlayEntry` null, so every
          // `EasyLoading.show()` threw "You should call EasyLoading.init()
          // in your MaterialApp" (hit on device 2026-09-06 verifying an OTP).
          // This is how the passenger app has always done it.
          final easyLoading = EasyLoading.init()(context, child);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler:
                  TextScaler.linear(checkPlatformDevice() == "ios" ? 1.0 : 0.9),
            ),
            child: easyLoading,
          );
        },
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        navigatorKey: NavigationService().navigatorKey,
        locale: context.locale,
        title: AppConstant.titleApp,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
      ),
    );
  }
}
