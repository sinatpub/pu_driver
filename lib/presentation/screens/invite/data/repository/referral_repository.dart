import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/datasource/referral_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/models/referral_model.dart';

class ReferralRepository {
  ReferralRepository(this._datasource);

  final ReferralDatasource _datasource;

  Future<Result<ReferralModel>> getReferral() => _datasource.getReferral();

  Future<Result<RewardTransferResult>> transferRewards({
    required num amount,
    required String requestId,
  }) =>
      _datasource.transferRewards(amount: amount, requestId: requestId);

  Future<Result<InviteCodeCheck>> checkCode(String code) =>
      _datasource.checkCode(code);
}
