import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/data/models/set_status_model.dart';
import 'package:tara_driver_application/features/home/data/datasource/home_datasource.dart';

class HomeRepository {
  HomeRepository(this._datasource);

  final HomeDatasource _datasource;

  Future<Result<SetDriverStatusModel>> getStatus() => _datasource.getStatus();

  Future<Result<SetDriverStatusModel>> setStatus(int status) => _datasource.setStatus(status);
}
