import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/data/models/set_status_model.dart';

class HomeDatasource {
  HomeDatasource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<SetDriverStatusModel>> getStatus() {
    return _apiClient.request<SetDriverStatusModel>(
      path: '/taxi-driver/check-status',
      method: 'GET',
      decode: (response) => SetDriverStatusModel.fromJson(response.data),
    );
  }

  Future<Result<SetDriverStatusModel>> setStatus(int status) {
    return _apiClient.request<SetDriverStatusModel>(
      path: '/taxi-driver/set-status',
      method: 'POST',
      body: {'status': status},
      decode: (response) => SetDriverStatusModel.fromJson(response.data),
    );
  }
}
