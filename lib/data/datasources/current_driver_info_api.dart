import 'package:tara_driver_application/core/api_service/base_api_service.dart';
import 'package:tara_driver_application/data/models/current_driver_info_model.dart';

class GetCurrentDriverInfo {
  Future<CurrentDriverInfoModel> getCurrentDriverInfoApi() async {
    return BaseApiService().onRequest<CurrentDriverInfoModel>(
        path: "/taxi-driver/get-current-drive-info",
        method: "GET",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        onSuccess: (result) {
          return CurrentDriverInfoModel?.fromJson(result.data);
        });
  }
}
