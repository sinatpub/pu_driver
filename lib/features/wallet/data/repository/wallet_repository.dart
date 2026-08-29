import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/features/wallet/data/models/wallet_model.dart';
import 'package:tara_driver_application/features/wallet/data/datasource/wallet_datasource.dart';

class WalletRepository {
  WalletRepository(this._datasource);

  final WalletDatasource _datasource;

  Future<Result<WalletModel>> getWallet() => _datasource.getWallet();
}
