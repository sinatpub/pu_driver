import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/presentation/screens/home/data/models/version_app_model.dart';

class VersionCheckDatasource {
  VersionCheckDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<VersionAppModel>> getCurrentVersion() {
    return _apiClient.request<VersionAppModel>(
      path: '/taxi/get-current-app-version/1',
      method: 'GET',
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      decode: (response) => VersionAppModel.fromJson(response.data),
    );
  }
}
