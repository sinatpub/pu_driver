import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/presentation/screens/profile/data/models/profile_model.dart';

class ProfileDatasource {
  ProfileDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<ProfileModel>> getProfile() {
    return _apiClient.request<ProfileModel>(
      path: '/taxi-driver/get-profile',
      method: 'GET',
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      decode: (response) => ProfileModel.fromJson(response.data),
    );
  }
}
