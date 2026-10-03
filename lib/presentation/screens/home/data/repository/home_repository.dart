import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/data/models/current_driver_info_model.dart';
import 'package:pu_taxi_driver/data/models/set_status_model.dart';
import 'package:pu_taxi_driver/presentation/screens/home/data/datasource/home_datasource.dart';

class HomeRepository {
  HomeRepository(this._datasource);

  final HomeDatasource _datasource;

  Future<Result<SetDriverStatusModel>> getStatus() => _datasource.getStatus();

  Future<Result<SetDriverStatusModel>> setStatus(int status) =>
      _datasource.setStatus(status);

  Future<Result<CurrentDriverInfoModel>> getCurrentDriveInfo() =>
      _datasource.getCurrentDriveInfo();
}
