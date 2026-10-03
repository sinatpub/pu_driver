import 'package:pu_taxi_driver/core/api_service/base_api_service.dart';
import 'package:pu_taxi_driver/data/models/set_status_model.dart';

class SetDriverStatusApi {
  Future<SetDriverStatusModel> toggleStatusDriver({int status = 1}) async {
    return BaseApiService().onRequest(
      path: "/taxi-driver/set-status",
      method: "POST",
      bodyParse: {"status": status},
      // customToken: AppConstant.customeToken,
      onSuccess: (result) {
        return SetDriverStatusModel.fromJson(result.data);
      },
    );
  }

  Future<SetDriverStatusModel> getStatusDriver() async {
    return BaseApiService().onRequest(
      path: "/taxi-driver/check-status",
      method: "GET",
      // customToken: AppConstant.customeToken
      onSuccess: (result) {
        // return false;
        return SetDriverStatusModel.fromJson(result.data);
      },
    );
  }
}
