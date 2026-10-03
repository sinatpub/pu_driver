import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/datasource/history_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/models/history_driver_info_model.dart';

class HistoryRepository {
  HistoryRepository(this._datasource);

  final HistoryDatasource _datasource;

  Future<Result<HistoryDriveInfoModel>> getHistory({
    required int page,
    required int status,
  }) =>
      _datasource.getHistory(page: page, status: status);
}
