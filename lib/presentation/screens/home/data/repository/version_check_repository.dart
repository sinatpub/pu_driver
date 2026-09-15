import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/presentation/screens/home/data/datasource/version_check_datasource.dart';
import 'package:tara_driver_application/presentation/screens/home/data/models/version_app_model.dart';

class VersionCheckRepository {
  VersionCheckRepository(this._datasource);

  final VersionCheckDatasource _datasource;

  Future<Result<VersionAppModel>> getCurrentVersion() =>
      _datasource.getCurrentVersion();
}
