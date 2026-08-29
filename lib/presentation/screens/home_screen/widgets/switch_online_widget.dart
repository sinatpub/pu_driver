import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/features/home/presentation/controller/home_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart' hide Trans;

class SwitchOnlineWidget extends StatelessWidget {
  const SwitchOnlineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Obx(() => FlutterSwitch(
          activeTextColor: AppColors.light4,
          inactiveTextColor: AppColors.error,
          activeColor: AppColors.success,
          inactiveColor: AppColors.light1,
          activeText: "ONLINE".tr(),
          inactiveText: "OFFLINE".tr(),
          value: homeController.isOnline.value,
          valueFontSize: 14.0,
          width: 110,
          borderRadius: 15,
          height: 30,
          toggleSize: 35,
          padding: 3,
          showOnOff: true,
          onToggle: (val) {
            homeController.toggle(val);
          },
        ));
  }
}
