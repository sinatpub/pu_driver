import 'package:tara_driver_application/core/api_service/base_api_service.dart';
import 'package:tara_driver_application/data/models/version_app_model.dart';

class GetVersionAppApi {
  Future<VersionAppModel> getDriverWalletApi() async {
    return BaseApiService().onRequest<VersionAppModel>(
        path: "/taxi/get-current-app-version/1",
        method: "GET",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        onSuccess: (result) {
          return VersionAppModel?.fromJson(result.data);
        });
  }
}