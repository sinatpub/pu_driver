import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/screens/profile/data/datasource/profile_datasource.dart';
import 'package:tara_driver_application/presentation/screens/profile/data/repository/profile_repository.dart';

import 'logic.dart';

/// `permanent: true` preserves the lifetime `main.dart` gave this controller.
/// `calculate_fee` can sit above `home` in the stack and reads the same
/// profile, so it must outlive any single route (`14` §6.3).
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ProfileDatasource>(ProfileDatasource(), permanent: true);
    Get.put<ProfileRepository>(ProfileRepository(Get.find()), permanent: true);
    Get.put<ProfileLogic>(ProfileLogic(Get.find()), permanent: true);
  }
}
