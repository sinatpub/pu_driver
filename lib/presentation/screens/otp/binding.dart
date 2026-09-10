import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/features/auth/data/datasource/auth_datasource.dart';
import 'package:tara_driver_application/features/auth/data/repository/auth_repository.dart';

import 'logic.dart';

class OtpBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as OtpPageArgs;
    Get.lazyPut<AuthDatasource>(() => AuthDatasource(), fenix: true);
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find()), fenix: true);
    Get.lazyPut<OtpLogic>(
      () => OtpLogic(
        Get.find(),
        phoneNumberModel: args.phoneNumberModel,
        phoneNumber: args.phoneNumber,
        onResend: args.onResend,
      ),
      fenix: true,
    );
  }
}
