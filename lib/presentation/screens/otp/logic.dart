import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/core/storage/set_storages.dart';
import 'package:tara_driver_application/core/utils/debug_auth_bypass.dart';
import 'package:tara_driver_application/presentation/screens/login/data/models/phone_model.dart';
import 'package:tara_driver_application/presentation/screens/login/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/widgets/error_dialog_widget.dart';

import 'state.dart';
import 'package:easy_localization/easy_localization.dart';

/// D-02 (`12`). Moved out of `features/auth/presentation/controller/` per
/// `14` §3.6, absorbing the countdown timer and navigation worker that lived
/// in `_OtpPageState`.
///
/// The countdown moved from `setState` fields to `Rx` for a reason beyond
/// convention: the old screen wrapped its whole body in an `Obx` that read no
/// observable, so `secondsRemaining` ticking via `setState` was what actually
/// repainted it. Now the `Obx` has something real to watch.
class OtpLogic extends GetxController {
  OtpLogic(
    this._repository, {
    required this.phoneNumberModel,
    required this.phoneNumber,
    required this.onResend,
  });

  final AuthRepository _repository;
  final PhoneNumberModel? phoneNumberModel;
  final String? phoneNumber;
  final void Function() onResend;

  final OtpState state = OtpState();

  final TextEditingController pinController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    ever<OtpStatus>(state.status, _onStatusChanged);
    state.secondsRemaining.value = phoneNumberModel?.data.seconde ?? 60;
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    pinController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining.value == 0) {
        state.isResendEnabled.value = true;
        timer.cancel();
      } else {
        state.secondsRemaining.value--;
      }
    });
  }

  void _onStatusChanged(OtpStatus status) {
    if (status == OtpStatus.newDriver) {
      Get.toNamed(AppRoutes.register);
    } else if (status == OtpStatus.loaded) {
      Get.offAllNamed(AppRoutes.home);
    } else if (status == OtpStatus.fail) {
      // Clear the field too: Pinput only fires `onCompleted` when the text
      // changes, so leaving the rejected digits in place means the driver
      // has to backspace four times before they can try again.
      pinController.clear();
      showErrorCustomDialog(
        Get.context!,
        "PLEASE_TRY_AGAIN".tr(),
        // The server's own message when it sent one (it is English, from the
        // backend); otherwise ours.
        state.errorMessage.value ?? "OTP_INCORRECT".tr(),
        false,
      );
    }
  }

  Future<void> verify({required String phone, required String otpCode}) async {
    // Debug-only shortcut — see [DebugAuthBypass] for the three conditions
    // that must all hold. Compiled out of release builds entirely.
    if (DebugAuthBypass.accepts(otpCode)) {
      state.status.value = OtpStatus.loading;
      final ok = await DebugAuthBypass.seedSession();
      if (!ok) {
        state.errorMessage.value =
            'Debug bypass could not obtain a session — see the log.';
        state.status.value = OtpStatus.fail;
        return;
      }
      state.errorMessage.value = null;
      state.status.value = OtpStatus.loaded;
      return;
    }

    state.status.value = OtpStatus.loading;
    EasyLoading.show(dismissOnTap: false);
    try {
      final result =
          await _repository.verifyOtp(phone: phone, otpCode: otpCode);
      result.when(
        ok: (data) {
          // A rejected code comes back 201 with `status:false, data:null`
          // ("OTP not correct"). This used to `return` here, leaving status
          // stuck on `loading` — no dialog, no spinner, nothing (reproduced
          // on device 2026-09-06). It must fail explicitly, and it must do so
          // *before* the checks below: with `data == null` the next branch's
          // `data?.driver == null && data?.token == null` is vacuously true,
          // which would send a driver who fat-fingered their code straight to
          // the registration screen.
          if (data.status != true && data.data == null) {
            state.errorMessage.value = data.message;
            state.status.value = OtpStatus.fail;
            return;
          }
          if (data.data?.driver == null && data.data?.token == null) {
            state.status.value = OtpStatus.newDriver;
          } else if (data.data?.driver != null && data.data?.token != null) {
            state.registerModel.value = data;
            state.errorMessage.value = null;
            state.status.value = OtpStatus.loaded;
            StorageSet.storeDriverData(data);
          } else {
            state.errorMessage.value = data.message;
            state.status.value = OtpStatus.fail;
          }
        },
        err: (error) {
          state.errorMessage.value = error.message;
          state.status.value = OtpStatus.fail;
        },
      );
    } finally {
      EasyLoading.dismiss();
    }
  }
}
