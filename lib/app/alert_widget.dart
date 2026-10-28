import 'package:easy_localization/easy_localization.dart';
import 'package:pu_taxi_driver/app/logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:logger/logger.dart';
import 'package:pu_taxi_driver/presentation/widgets/cancel_book_dialog_widget.dart';
import 'package:pu_taxi_driver/presentation/widgets/process_book_dialog_widget.dart';

import '../presentation/widgets/yesno_dialog_widget.dart';

class AlertWidget {
  /// Audit D-1: the drawer's logout row. This used to remove the sign-in
  /// record and nothing else, from a row nobody could reach: the token, the
  /// socket and the online service outlived it, and the next launch signed
  /// the driver straight back in. [AppLogic.signOut] ends all of it.
  void logout(BuildContext context) {
    try {
      showYesNoCustomDialog(
          context: context,
          title: "LOGOUT".tr(),
          description: "ARE_YOU_LOGOUT".tr(),
          yesLabel: "LOGOUT".tr(),
          noLabel: "STAY".tr(),
          onYes: () {
            Navigator.of(context).pop();
            Get.find<AppLogic>().signOut();
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
