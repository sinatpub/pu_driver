import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';
import 'package:tara_driver_application/core/helper/get_device_info.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/core/storage/get_storages.dart';
import 'package:tara_driver_application/core/storage/set_storages.dart';
import 'package:tara_driver_application/presentation/screens/login/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/widgets/error_dialog_widget.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';

import 'state.dart';
import 'package:easy_localization/easy_localization.dart';

/// Which attachment a pick is for. Was three bare `int` comparisons
/// (`0`/`1`/`2`/else) repeated in two near-identical picker methods.
enum RegisterAttachment { license, cardId, profile, vehicle }

/// D-02 (`12`). Moved out of `features/auth/presentation/controller/` per
/// `14` §3.6, absorbing the form state, the two image-picker methods and the
/// navigation worker that lived in `_RegisterPageState`.
class RegisterLogic extends GetxController {
  RegisterLogic(this._repository);

  final AuthRepository _repository;
  final DeviceInfoHelper _deviceInfo = DeviceInfoHelper();
  final ImagePicker _picker = ImagePicker();

  final RegisterState state = RegisterState();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController vehicleColorController = TextEditingController();

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

  Future<void> submit() async {
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
