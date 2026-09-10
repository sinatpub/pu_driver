import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/features/wallet/data/models/wallet_model.dart';

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
