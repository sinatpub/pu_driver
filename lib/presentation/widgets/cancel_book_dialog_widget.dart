import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/routes/app_routes.dart';

/// "The passenger cancelled" — raised from the socket listener
/// (`services/socket_service.dart`), then it returns the driver home.
///
/// UX-redesign F3 restyled the body and added the draining bar that tells the
/// driver *why* the screen is about to change. **Every timing behaviour below
/// is carried over unchanged** (`DD-25`):
///
/// - `barrierDismissible: false`.
/// - The 10 s `Future.delayed` is still scheduled inside the builder, and
///   `close` is still never set — so the navigation fires even after OK is
///   tapped. That double-navigation is a known defect (B4 in
///   `docs/ux-redesign/06-implementation-plan.md §4`), not something a restyle
///   gets to fix.
///
/// **The progress bar is decoration and must stay that way.** It animates
/// inside its own [TAutoDismissBar] state object rather than through this
/// builder, because this builder schedules a fresh navigation timer every time
/// it runs — driving the bar from here would send the driver home several
/// times over.
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
        return TDialog(
          icon: DsIcons.close,
          iconColor: context.colors.danger,
          title: title,
          message: description,
          top: TAutoDismissBar(duration: Duration(seconds: number)),
          actions: <Widget>[
            TButton(
              label: 'OK'.tr(),
              size: TButtonSize.small,
              onPressed: () {
                setState(() {
                  Get.offAllNamed(AppRoutes.home);
                });
              },
            ),
          ],
        );
      });
    },
  );
}
