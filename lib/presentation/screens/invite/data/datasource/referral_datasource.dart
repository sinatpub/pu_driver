import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';

/// DD-45. **Neither endpoint exists on the real backend yet** — the paths are
/// the app's proposal and only the mock backend answers them. See
/// `invite_feature.dart`, which keeps the screens hidden until they do.
class ReferralDatasource {
  ReferralDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<ReferralModel>> getReferral() {
    return _apiClient.request<ReferralModel>(
      path: '/taxi-driver/referral',
      method: 'GET',
      decode: (response) => ReferralModel.fromJson(response.data),
    );
  }

  Future<Result<InviteCodeCheck>> checkCode(String code) {
    return _apiClient.request<InviteCodeCheck>(
      path: '/taxi-driver/referral/check-code',
      method: 'GET',
      // Asked from the sign-up form, before the driver has a session.
      requiresToken: false,
      query: <String, dynamic>{'code': code},
      decode: (response) => InviteCodeCheck.fromJson(response.data),
    );
  }
}
