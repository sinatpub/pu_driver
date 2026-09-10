import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/data/datasources/get_vehical_remote_data_source.dart';
import 'package:tara_driver_application/features/auth/data/datasource/auth_datasource.dart';
import 'package:tara_driver_application/features/auth/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/controllers/vehicle_controller.dart';

import 'logic.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthDatasource>(() => AuthDatasource(), fenix: true);
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find()), fenix: true);
    Get.lazyPut<RegisterLogic>(() => RegisterLogic(Get.find()), fenix: true);
    Get.lazyPut<GetVehicalRemoteDataSource>(() => GetVehicalRemoteDataSource(),
        fenix: true);
    Get.lazyPut<VehicleController>(() => VehicleController(Get.find()),
        fenix: true);
  }
}
