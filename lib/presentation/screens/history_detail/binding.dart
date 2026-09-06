import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/route_arguments.dart';

import 'logic.dart';

class HistoryDetailBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as MapHistoryDetailArgs;
    Get.lazyPut<HistoryDetailLogic>(
      () => HistoryDetailLogic(
        typeVehicleId: args.typeVehicleId,
        cost: args.cost,
        distand: args.distand,
        duration: args.duration,
        latStart: args.latStart,
        lngStart: args.lngStart,
        latEnd: args.latEnd,
        lngEnd: args.lngEnd,
      ),
      fenix: true,
    );
  }
}
