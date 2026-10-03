import 'package:pu_taxi_driver/core/api_service/base_api_service.dart';
import 'package:pu_taxi_driver/data/models/phone_model.dart';

class PhoneNumerRemoteDataSource {
  Future<PhoneNumberModel> postPhoneNumberApi(
      {required String phoneNumer}) async {
    return BaseApiService().onRequest(
        path: "/taxi-driver/login-phone",
        method: "POST",
        requiredToken: false,
        onSuccess: (result) {
          return PhoneNumberModel.fromJson(result.data);
        },
        bodyParse: {"phone": phoneNumer});
  }
}
