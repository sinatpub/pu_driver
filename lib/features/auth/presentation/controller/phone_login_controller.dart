import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/storages/set_storages.dart';
import 'package:tara_driver_application/features/auth/data/models/phone_model.dart';
import 'package:tara_driver_application/features/auth/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/widgets/shake_widget.dart';

enum PhoneLoginStatus { initial, loading, loaded, fail }

/// D-02, docs/12 — replaces `PhoneLoginBloc`, which validated a phone number
/// by dispatching a second event to itself and then `await`ing
/// `Future.delayed(Duration.zero)`, hoping that was enough time for the
/// other handler to run and update `state` before it checked it (the
/// author's own comment: "it will throw after event add above not return
/// this"). Validation is inline here — no dispatch, no race.
class PhoneLoginController extends GetxController {
  PhoneLoginController(this._repository);

  final AuthRepository _repository;
  final phoneShake = GlobalKey<ShakeWidgetState>();

  final status = Rx<PhoneLoginStatus>(PhoneLoginStatus.initial);
  final phoneModel = Rxn<PhoneNumberModel>();
  final isInvalidPhone = RxBool(false);
  final isRequired8Digit = RxBool(false);

  /// Preserves the original empty / `<10`-digit rules verbatim.
  bool validate(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      phoneShake.currentState?.shake();
      isInvalidPhone.value = true;
      isRequired8Digit.value = false;
      return false;
    } else if (phoneNumber.length < 10) {
      phoneShake.currentState?.shake();
      isInvalidPhone.value = false;
      isRequired8Digit.value = true;
      return false;
    }
    isInvalidPhone.value = false;
    isRequired8Digit.value = false;
    return true;
  }

  Future<void> submit(String phoneNumber) async {
    if (!validate(phoneNumber)) return;

    status.value = PhoneLoginStatus.loading;
    final result = await _repository.loginPhone(phoneNumber);
    result.when(
      ok: (data) {
        phoneModel.value = data;
        status.value = PhoneLoginStatus.loaded;
        StorageSet.setPhoneNumber(phoneNumber);
      },
      err: (_) {
        phoneShake.currentState?.shake();
        status.value = PhoneLoginStatus.fail;
      },
    );
  }
}
