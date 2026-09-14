import 'package:easy_localization/easy_localization.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/core/storage/remove_storage.dart';
import 'package:tara_driver_application/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:logger/logger.dart';
import 'package:tara_driver_application/presentation/widgets/cancel_book_dialog_widget.dart';
import 'package:tara_driver_application/presentation/widgets/process_book_dialog_widget.dart';

import '../presentation/widgets/yesno_dialog_widget.dart';

class AlertWidget {
  void logout(BuildContext context) async {
    try {
      showYesNoCustomDialog(
          context: context,
          title: "LOGOUT".tr(),
          description: "ARE_YOU_LOGOUT".tr(),
          onYes: () async {
            EasyLoading.show();
            await StorageRemove.removeDriverData();
            LocationService.instance.stop();
            Get.offAllNamed(AppRoutes.login);
            EasyLoading.dismiss();
          });
    } catch (e) {
      Logger().e("message: $e");
    }
  }

  void cancelBooking(
    BuildContext context,
  ) async {
    try {
      showCancelBookingDialog(
          context: context,
          title: "BOOKINGS_CANCELED".tr(),
          description: "PASSENGER_CANCEL".tr(),
          onYes: () async {
            EasyLoading.show();
            Navigator.of(context).pop();
            EasyLoading.dismiss();
          });
    } catch (e) {
      Logger().e("message: $e");
    }
  }

  void onProcessBooking(
    BuildContext context,
  ) async {
    try {
      showPocessBookingLoadingDialog(
          context: context,
          // C2 / DD-32: "In Process Booking" described the server's state, not
          // the driver's. The dialog appears for two seconds while the app
          // returns them to a trip already under way.
          title: "RESUMING_TRIP".tr(),
          onYes: () async {
            EasyLoading.show();
            Navigator.of(context).pop();
            EasyLoading.dismiss();
          });
    } catch (e) {
      Logger().e("message: $e");
    }
  }
}
