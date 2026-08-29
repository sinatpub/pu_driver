import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/storages/set_storages.dart';
import 'package:tara_driver_application/data/models/register_model.dart';
import 'package:tara_driver_application/features/auth/data/repository/auth_repository.dart';

enum OtpStatus { initial, loading, loaded, newDriver, fail }

class OtpController extends GetxController {
  OtpController(this._repository);

  final AuthRepository _repository;

  final status = Rx<OtpStatus>(OtpStatus.initial);
  final registerModel = Rxn<RegisterModel>();

  Future<void> verify({required String phone, required String otpCode}) async {
    status.value = OtpStatus.loading;
    EasyLoading.show(dismissOnTap: false);
    try {
      final result = await _repository.verifyOtp(phone: phone, otpCode: otpCode);
      result.when(
        ok: (data) {
          if (data.status != true && data.data == null) {
            // Matches OTPVerifyBloc: neither branch below fires, status
            // is left as-is (stuck loading) — a pre-existing gap, not
            // something this migration should paper over silently.
            return;
          }
          if (data.data?.driver == null && data.data?.token == null) {
            status.value = OtpStatus.newDriver;
          } else if (data.data?.driver != null && data.data?.token != null) {
            registerModel.value = data;
            status.value = OtpStatus.loaded;
            StorageSet.storeDriverData(data);
          } else {
            status.value = OtpStatus.fail;
          }
        },
        err: (_) => status.value = OtpStatus.fail,
      );
    } finally {
      EasyLoading.dismiss();
    }
  }
}
