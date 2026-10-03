import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/presentation/screens/invite/data/datasource/referral_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/repository/referral_repository.dart';

import 'logic.dart';

class InviteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferralDatasource>(() => ReferralDatasource(), fenix: true);
    Get.lazyPut<ReferralRepository>(() => ReferralRepository(Get.find()),
        fenix: true);
    Get.lazyPut<InviteLogic>(() => InviteLogic(Get.find()), fenix: true);
  }
}
