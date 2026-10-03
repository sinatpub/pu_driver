import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/data/models/wallet_model.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/data/datasource/wallet_datasource.dart';

class WalletRepository {
  WalletRepository(this._datasource);

  final WalletDatasource _datasource;

  Future<Result<WalletModel>> getWallet() => _datasource.getWallet();
}
