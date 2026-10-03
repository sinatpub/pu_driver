import 'package:pu_taxi_driver/core/api_service/base_api_service.dart';
import 'package:pu_taxi_driver/data/models/history_driver_info_model.dart';

class GetBopkingHistory {
  static Future<HistoryDriveInfoModel> getHistoryBookApi({required String page, required String status}) async {
    return BaseApiService().onRequest<HistoryDriveInfoModel>(
        path: "/taxi-driver/history-drive-info?page=$page&status=$status",
        method: "GET",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        onSuccess: (result) {
          return HistoryDriveInfoModel?.fromJson(result.data);
        });
  }
}
