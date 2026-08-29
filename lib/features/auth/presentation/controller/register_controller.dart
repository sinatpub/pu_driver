import 'dart:io';

import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/helper/get_device_info.dart';
import 'package:tara_driver_application/core/storages/get_storages.dart';
import 'package:tara_driver_application/core/storages/set_storages.dart';
import 'package:tara_driver_application/data/models/register_model.dart';
import 'package:tara_driver_application/features/auth/data/repository/auth_repository.dart';

enum RegisterStatus { initial, loading, loaded, fail }

class RegisterController extends GetxController {
  RegisterController(this._repository);

  final AuthRepository _repository;
  final DeviceInfoHelper _deviceInfo = DeviceInfoHelper();

  final status = Rx<RegisterStatus>(RegisterStatus.initial);
  final registerModel = Rxn<RegisterModel>();

  Future<void> register({
    required String fullname,
    required String vehicalId,
    required String vehicalColor,
    required String plateNumber,
    required File cardImage,
    required File profileImage,
    required File vehicleImage,
    required File driverLicenseImage,
  }) async {
    status.value = RegisterStatus.loading;
    try {
      final platformInfo = await _deviceInfo.getDeviceInfo();
      final phonePref = await StorageGet.getPhoneNumber();
      final result = await _repository.register(
        fullName: fullname,
        phoneNumber: '$phonePref',
        vehicleImage: vehicleImage,
        vehicalId: vehicalId,
        plateNumber: plateNumber,
        vehicalColor: vehicalColor,
        deviceToken: '9999',
        platform: platformInfo['model'],
        cardImage: cardImage,
        profileImage: profileImage,
        driverLicenseImage: driverLicenseImage,
      );
      result.when(
        ok: (data) {
          registerModel.value = data;
          status.value = RegisterStatus.loaded;
          StorageSet.storeDriverData(data);
        },
        err: (_) => status.value = RegisterStatus.fail,
      );
    } catch (_) {
      status.value = RegisterStatus.fail;
    }
  }
}
