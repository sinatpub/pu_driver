import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/features/profile/data/datasource/profile_datasource.dart';
import 'package:tara_driver_application/features/profile/data/models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._datasource);

  final ProfileDatasource _datasource;

  Future<Result<ProfileModel>> getProfile() => _datasource.getProfile();
}
