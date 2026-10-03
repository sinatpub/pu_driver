import 'package:pu_taxi_driver/core/network/api_client.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/data/models/wallet_model.dart';

class WalletDatasource {
  WalletDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<WalletModel>> getWallet() {
    return _apiClient.request<WalletModel>(
      path: '/taxi-driver/wallet',
      method: 'GET',
      decode: (response) => WalletModel.fromJson(response.data),
    );
  }
}
