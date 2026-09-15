import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/screens/wallet/data/datasource/wallet_datasource.dart';
import 'package:tara_driver_application/presentation/screens/wallet/data/repository/wallet_repository.dart';

import 'logic.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletDatasource>(() => WalletDatasource(), fenix: true);
    Get.lazyPut<WalletRepository>(() => WalletRepository(Get.find()),
        fenix: true);
    Get.lazyPut<WalletLogic>(() => WalletLogic(Get.find()), fenix: true);
  }
}
