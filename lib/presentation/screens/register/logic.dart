import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';
import 'package:pu_taxi_driver/core/helper/get_device_info.dart';
import 'package:pu_taxi_driver/routes/app_routes.dart';
import 'package:pu_taxi_driver/core/storage/get_storages.dart';
import 'package:pu_taxi_driver/core/storage/set_storages.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/models/referral_model.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/repository/referral_repository.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/invite_presentation.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/widgets/invite_code_field.dart';
import 'package:pu_taxi_driver/presentation/screens/login/data/repository/auth_repository.dart';
import 'package:pu_taxi_driver/presentation/widgets/error_dialog_widget.dart';
import 'package:pu_taxi_driver/taxi_single_ton/taxi.dart';

import 'state.dart';
import 'package:easy_localization/easy_localization.dart';

/// Which attachment a pick is for. Was three bare `int` comparisons
/// (`0`/`1`/`2`/else) repeated in two near-identical picker methods.
enum RegisterAttachment { license, cardId, profile, vehicle }

/// D-02 (`12`). Moved out of `features/auth/presentation/controller/` per
/// `14` §3.6, absorbing the form state, the two image-picker methods and the
/// navigation worker that lived in `_RegisterPageState`.
class RegisterLogic extends GetxController {
  RegisterLogic(this._repository, {ReferralRepository? referral})
      : _referral = referral;

  final AuthRepository _repository;

  /// DD-45: checks the optional invite code. Null where the invite feature
  /// is not wired, in which case a code is never checked or sent.
  final ReferralRepository? _referral;
  final DeviceInfoHelper _deviceInfo = DeviceInfoHelper();
  final ImagePicker _picker = ImagePicker();

  final RegisterState state = RegisterState();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController vehicleColorController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();

  /// How long typing must pause before the invite code is checked.
  static const Duration inviteCheckDelay = Duration(milliseconds: 700);
  Timer? _inviteDebounce;

  /// Bumped on every edit, so a slow answer for an old code is dropped.
  int _inviteCheckId = 0;

  @override
  void onInit() {
    super.onInit();
    ever<RegisterStatus>(state.status, _onStatusChanged);
  }

  @override
  void onClose() {
    nameController.dispose();
    plateController.dispose();
    vehicleColorController.dispose();
    inviteCodeController.dispose();
    _inviteDebounce?.cancel();
    super.onClose();
  }

  void _onStatusChanged(RegisterStatus status) {
    if (status == RegisterStatus.fail) {
      showErrorCustomDialog(Get.context!, "PLEASE_TRY_AGAIN".tr(),
          "REGISTER_FIELDS_REQUIRED".tr(), false);
    } else if (status == RegisterStatus.loaded) {
      Taxi.shared.checkDriverAvailability();
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Replaces the bare `setState(() {})` calls the text fields used to make.
  void markFormChanged() => state.formRevision.value++;

  void selectVehicle(int? id) => state.vehicalId.value = id;

  void clearAttachment(RegisterAttachment which) => _setAttachment(which, null);

  Future<void> pickFromCamera(RegisterAttachment which) =>
      _pick(which, ImageSource.camera);

  Future<void> pickFromGallery(RegisterAttachment which) =>
      _pick(which, ImageSource.gallery);

  Future<void> _pick(RegisterAttachment which, ImageSource source) async {
    final imageFile = await _picker.pickImage(source: source);
    if (imageFile != null) _setAttachment(which, File(imageFile.path));
  }

  void _setAttachment(RegisterAttachment which, File? file) {
    switch (which) {
      case RegisterAttachment.license:
        state.imageLicense.value = file;
      case RegisterAttachment.cardId:
        state.imageCardID.value = file;
      case RegisterAttachment.profile:
        state.imageProfile.value = file;
      case RegisterAttachment.vehicle:
        state.imageVehicle.value = file;
    }
  }

  /// The invite code field changed: forget the last answer, and check the
  /// new text once typing pauses.
  void onInviteCodeChanged(String text) {
    _inviteDebounce?.cancel();
    _inviteCheckId++;
    state.inviteStatus.value = InviteCodeStatus.idle;
    state.inviterName.value = null;
    if (parseInviteCode(text) == null) return;
    _inviteDebounce = Timer(inviteCheckDelay, verifyInviteCode);
  }

  /// A code read from the inviter's QR: fill the field and check it now.
  Future<void> applyScannedCode(String code) {
    inviteCodeController.text = code;
    _inviteDebounce?.cancel();
    return verifyInviteCode();
  }

  /// Asks the server whether the typed code is real. True when there is no
  /// code to check, or the code is valid.
  Future<bool> verifyInviteCode() async {
    _inviteDebounce?.cancel();
    final String text = inviteCodeController.text.trim();
    if (text.isEmpty) {
      state.inviteStatus.value = InviteCodeStatus.idle;
      return true;
    }
    if (state.inviteStatus.value == InviteCodeStatus.valid) return true;

    final String? code = parseInviteCode(text);
    final ReferralRepository? referral = _referral;
    if (code == null || referral == null) {
      state.inviteStatus.value = InviteCodeStatus.invalid;
      return false;
    }

    final int checkId = ++_inviteCheckId;
    state.inviteStatus.value = InviteCodeStatus.checking;
    final result = await referral.checkCode(code);
    // The field was edited while the request was out.
    if (checkId != _inviteCheckId) return false;
    return result.when(
      ok: (InviteCodeCheck check) {
        state.inviterName.value = check.valid ? check.inviterName : null;
        state.inviteStatus.value =
            check.valid ? InviteCodeStatus.valid : InviteCodeStatus.invalid;
        return check.valid;
      },
      err: (_) {
        state.inviteStatus.value = InviteCodeStatus.failed;
        return false;
      },
    );
  }

  Future<void> submit() async {
    // DD-45: an invite code can only be given at sign-up, so a code that is
    // wrong must stop the form — silently dropping it would lose the invite
    // for good. The field shows why; clearing it lets the driver continue.
    if (!await verifyInviteCode()) return;
    final String inviteCode = inviteCodeController.text.trim();

    state.status.value = RegisterStatus.loading;
    try {
      final platformInfo = await _deviceInfo.getDeviceInfo();
      final phonePref = await StorageGet.getPhoneNumber();
      final result = await _repository.register(
        fullName: nameController.text.toString(),
        phoneNumber: '$phonePref',
        vehicleImage: state.imageVehicle.value!,
        vehicalId: "${state.vehicalId.value}",
        plateNumber: plateController.text.toString(),
        vehicalColor: vehicleColorController.text.toString(),
        deviceToken: '9999',
        platform: platformInfo['model'],
        cardImage: state.imageCardID.value!,
        profileImage: state.imageProfile.value!,
        driverLicenseImage: state.imageLicense.value!,
        inviteCode: inviteCode.isEmpty ? null : inviteCode,
      );
      result.when(
        ok: (data) {
          state.registerModel.value = data;
          state.status.value = RegisterStatus.loaded;
          StorageSet.storeDriverData(data);
        },
        err: (_) => state.status.value = RegisterStatus.fail,
      );
    } catch (_) {
      state.status.value = RegisterStatus.fail;
    }
  }
}
