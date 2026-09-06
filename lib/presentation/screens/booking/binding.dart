import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/data/datasources/get_vehical_remote_data_source.dart';
import 'package:tara_driver_application/features/trip/data/datasource/trip_datasource.dart';
import 'package:tara_driver_application/features/trip/data/repository/trip_repository.dart';
import 'package:tara_driver_application/features/trip/domain/trip_state_machine.dart';
import 'package:tara_driver_application/presentation/controllers/vehicle_controller.dart';

import 'logic.dart';

class BookingBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as BookingScreenArgs;
    Get.lazyPut<TripDatasource>(() => TripDatasource(), fenix: true);
    Get.lazyPut<TripRepository>(() => TripRepository(Get.find()), fenix: true);
    Get.lazyPut<BookingLogic>(
      () => BookingLogic(
        Get.find(),
        rideId: args.bookingId,
        initialStage:
            TripStageProcessStep.fromProcessStep(args.processStepBook),
      ),
      fenix: true,
    );
    Get.lazyPut<GetVehicalRemoteDataSource>(() => GetVehicalRemoteDataSource(),
        fenix: true);
    Get.lazyPut<VehicleController>(() => VehicleController(Get.find()),
        fenix: true);
  }
}
