import 'package:pu_taxi_driver/core/network/api_client.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/profile/data/models/profile_model.dart';

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
