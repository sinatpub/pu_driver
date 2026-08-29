import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/data/models/current_driver_info_model.dart';
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

  /// D-04 (docs/12) — replaces `GetCurrentDriverInfo`
  /// (`data/datasources/current_driver_info_api.dart`, the old
  /// `BaseApiService`-based caller `CurrentDriverInfoBloc` used). Despite
  /// the name, this returns the driver's *current active ride*, if any —
  /// not their profile — plus the driver's approval status nested inside
  /// it (`data.driver.status`, see D-03/`core/contracts/booking_status.dart`
  /// for `data.status`, the ride's own status).
  Future<Result<CurrentDriverInfoModel>> getCurrentDriveInfo() {
    return _apiClient.request<CurrentDriverInfoModel>(
      path: '/taxi-driver/get-current-drive-info',
      method: 'GET',
      decode: (response) => CurrentDriverInfoModel.fromJson(response.data),
    );
  }
}
