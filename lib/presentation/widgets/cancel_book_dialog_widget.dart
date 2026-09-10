import 'dart:async';

import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

Future<void> showCancelBookingDialog({
  required Function() onYes,
  required BuildContext context,
  required String title,
  required String description,
}) {
  int number = 10;
  bool close = false;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setState) {
        Future.delayed(Duration(seconds: number), () {
          if (close == false) {
            Get.offAllNamed(AppRoutes.home);
          }
        });
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(description),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: () {
                  setState(() {
                    Get.offAllNamed(AppRoutes.home);
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("YES".tr(),
                        style: ThemeConstands.font16Regular.copyWith(
                          color: AppColors.light4,
                        )),
                  ],
                )),
          ],
        );
      });
    },
  );
}
