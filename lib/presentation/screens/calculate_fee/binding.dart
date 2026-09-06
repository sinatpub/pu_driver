import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/features/payment/data/datasource/payment_datasource.dart';
import 'package:tara_driver_application/features/payment/data/repository/payment_repository.dart';

import 'logic.dart';

class CalculateFeeBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as CalculateFeeScreenArgs;
    Get.lazyPut<PaymentDatasource>(() => PaymentDatasource(), fenix: true);
    Get.lazyPut<PaymentRepository>(() => PaymentRepository(Get.find()),
        fenix: true);
    Get.lazyPut<CalculateFeeLogic>(
      () => CalculateFeeLogic(
        Get.find(),
        routFrom: args.routFrom,
        dataComplete: args.dataComplete,
        dataDriverInfo: args.dataDriverInfo,
        startAddress: args.startAddress,
        endAddress: args.endAddress,
      ),
      fenix: true,
    );
  }
}
