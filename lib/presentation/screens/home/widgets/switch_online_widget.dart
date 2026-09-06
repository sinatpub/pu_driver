import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/app/logic.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart' hide Trans;

class SwitchOnlineWidget extends StatelessWidget {
  const SwitchOnlineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appLogic = Get.find<AppLogic>();

    return Obx(() => FlutterSwitch(
          activeTextColor: AppColors.light4,
          inactiveTextColor: AppColors.error,
          activeColor: AppColors.success,
          inactiveColor: AppColors.light1,
          activeText: "ONLINE".tr(),
          inactiveText: "OFFLINE".tr(),
          value: appLogic.state.isOnline.value,
          valueFontSize: 14.0,
          width: 110,
          borderRadius: 15,
          height: 30,
          toggleSize: 35,
          padding: 3,
          showOnOff: true,
          onToggle: (val) {
            if (val && !appLogic.isApproved) {
              EasyLoading.showToast("WAITING_APPROVED_FROM_ADMIN".tr());
              return;
            }
            appLogic.toggle(val);
          },
        ));
  }
}
