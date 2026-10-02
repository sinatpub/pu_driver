import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/datasource/referral_datasource.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';

class ReferralRepository {
  ReferralRepository(this._datasource);

  final ReferralDatasource _datasource;

  Future<Result<ReferralModel>> getReferral() => _datasource.getReferral();

  Future<Result<InviteCodeCheck>> checkCode(String code) =>
      _datasource.checkCode(code);
}
