import 'package:tara_driver_application/core/api_service/base_api_service.dart';
import 'package:tara_driver_application/data/models/wallet_model.dart';

class GetDriverWAallet {
  Future<WalletModel> getDriverWalletApi() async {
    return BaseApiService().onRequest<WalletModel>(
        path: "/taxi-driver/wallet",
        method: "GET",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        onSuccess: (result) {
          return WalletModel?.fromJson(result.data);
        });
  }
}