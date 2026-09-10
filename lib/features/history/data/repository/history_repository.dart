import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/features/history/data/datasource/history_datasource.dart';
import 'package:tara_driver_application/features/history/data/models/history_driver_info_model.dart';

class HistoryRepository {
  HistoryRepository(this._datasource);

  final HistoryDatasource _datasource;

  Future<Result<HistoryDriveInfoModel>> getHistory({
    required int page,
    required int status,
  }) =>
      _datasource.getHistory(page: page, status: status);
}
