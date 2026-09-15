import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/screens/login/data/datasource/auth_datasource.dart';
import 'package:tara_driver_application/presentation/screens/login/data/repository/auth_repository.dart';

import 'logic.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthDatasource>(() => AuthDatasource(), fenix: true);
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find()), fenix: true);
    Get.lazyPut<LoginLogic>(() => LoginLogic(Get.find()), fenix: true);
  }
}
