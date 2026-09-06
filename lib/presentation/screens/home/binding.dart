import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/version_check/data/datasource/version_check_datasource.dart';
import 'package:tara_driver_application/features/version_check/data/repository/version_check_repository.dart';

import 'logic.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VersionCheckDatasource>(() => VersionCheckDatasource(),
        fenix: true);
    Get.lazyPut<VersionCheckRepository>(
        () => VersionCheckRepository(Get.find()),
        fenix: true);
    Get.lazyPut<HomeLogic>(() => HomeLogic(Get.find()), fenix: true);
  }
}
