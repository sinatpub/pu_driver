import 'package:pu_taxi_driver/core/api_service/base_api_service.dart';
import 'package:pu_taxi_driver/data/models/register_model.dart';

class OtpVerifyApi {
  Future<RegisterModel> verifyOTPApi(
      {required String phoneNumer, required String otpCode}) async {
    return BaseApiService().onRequest<RegisterModel>(
        path: "/taxi-driver/verify-phone-otp",
        method: "POST",
        requiredToken: false,
        onSuccess: (result) {
          return RegisterModel?.fromJson(result.data);
        },
        bodyParse: {
          "phone": phoneNumer,
          "otp_code": otpCode,
        });
  }
}
