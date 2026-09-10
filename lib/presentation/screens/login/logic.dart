import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/core/storage/set_storages.dart';
import 'package:tara_driver_application/features/auth/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/widgets/error_dialog_widget.dart';
import 'package:tara_driver_application/presentation/widgets/shake_widget.dart';

import 'state.dart';

/// D-02 (`12`) — replaces `PhoneLoginBloc`, which validated a phone number by
/// dispatching a second event to itself and then `await`ing
/// `Future.delayed(Duration.zero)`, hoping that was enough time for the other
/// handler to run and update `state` before it checked it (the author's own
/// comment: "it will throw after event add above not return this"). Validation
/// is inline here — no dispatch, no race.
///
/// Moved out of `features/auth/presentation/controller/` per `14` §3.6. The
/// text controller and shake key live here, matching how passenger's
/// `HistoryLogic` owns its `TabController`; the `ever` worker that used to sit
/// in `_LoginPageState.initState` moved with them, so GetX disposes it.
class LoginLogic extends GetxController {
  LoginLogic(this._repository);

  final AuthRepository _repository;
  final LoginState state = LoginState();

  final phoneShake = GlobalKey<ShakeWidgetState>();
  final TextEditingController phoneController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    ever<LoginStatus>(state.status, _onStatusChanged);
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  void _onStatusChanged(LoginStatus status) {
    if (status == LoginStatus.loaded) {
      Get.toNamed(
        AppRoutes.otp,
        arguments: OtpPageArgs(
          phoneNumberModel: state.phoneModel.value,
          // Normalised here too: the OTP screen sends this straight to
          // `verify-phone-otp`, which had the same formatted-string problem.
          phoneNumber: normalisePhone(phoneController.text),
          onResend: () => submit(phoneController.text.toString()),
        ),
      );
    } else if (status == LoginStatus.fail) {
      showErrorCustomDialog(
        Get.context!,
        "PLEASE_TRY_AGAIN".tr(),
        "CHECK_YOUR_PHONE_NUMBER_ERROR".tr(),
        false,
      );
    }
  }

  /// Preserves the original empty / `<10`-digit rules verbatim.
  bool validate(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      phoneShake.currentState?.shake();
      state.isInvalidPhone.value = true;
      state.isRequired8Digit.value = false;
      return false;
    } else if (phoneNumber.length < 10) {
      phoneShake.currentState?.shake();
      state.isInvalidPhone.value = false;
      state.isRequired8Digit.value = true;
      return false;
    }
    state.isInvalidPhone.value = false;
    state.isRequired8Digit.value = false;
    return true;
  }

  /// Strips everything that is not a digit.
  ///
  /// `CardNumberInputFormatter` rewrites the field as the driver types, so
  /// `phoneController.text` is `"90 000 0001"`, not `"900000001"` — and that
  /// formatted string was going straight onto the wire and into storage
  /// (captured in the device log 2026-09-06, on both `login-phone` and
  /// `verify-phone-otp`). The backend happens to normalise it on receipt, so
  /// this was luck rather than design; nothing guarantees the next endpoint
  /// or the next backend will.
  ///
  /// Deliberately does **not** force a leading `"0"`. That is the passenger
  /// app's rule (`.agent/RULES.md` §Quirks) and adding it here would change
  /// what the driver app sends — a contract change, not a bug fix.
  static String normalisePhone(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  Future<void> submit(String phoneNumber) async {
    // Validation deliberately runs on the *unnormalised* string. The
    // `length < 10` rule counts characters, so `"90 000 0001"` (11 chars)
    // passes where `"900000001"` (9 digits) would not. Which lengths are
    // legal is a product decision (`.agent/TODO.md` Discovered Tasks), so
    // this fix changes what goes on the wire without changing what the app
    // accepts.
    if (!validate(phoneNumber)) return;

    final normalised = normalisePhone(phoneNumber);

    state.status.value = LoginStatus.loading;
    final result = await _repository.loginPhone(normalised);
    result.when(
      ok: (data) {
        state.phoneModel.value = data;
        state.status.value = LoginStatus.loaded;
        StorageSet.setPhoneNumber(normalised);
      },
      err: (_) {
        phoneShake.currentState?.shake();
        state.status.value = LoginStatus.fail;
      },
    );
  }
}
