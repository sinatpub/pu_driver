import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/routes/route_arguments.dart';

import 'logic.dart';

class HistoryDetailBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as MapHistoryDetailArgs;
    Get.lazyPut<HistoryDetailLogic>(
      () => HistoryDetailLogic(args),
      fenix: true,
    );
  }
}
