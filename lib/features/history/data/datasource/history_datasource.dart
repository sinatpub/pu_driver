import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/features/history/data/models/history_driver_info_model.dart';

class HistoryDatasource {
  HistoryDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<HistoryDriveInfoModel>> getHistory({
    required int page,
    required int status,
  }) {
    return _apiClient.request<HistoryDriveInfoModel>(
      path: '/taxi-driver/history-drive-info',
      method: 'GET',
      query: {'page': page, 'status': status},
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      decode: (response) => HistoryDriveInfoModel.fromJson(response.data),
    );
  }
}
