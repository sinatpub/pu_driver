import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/data/datasources/get_vehical_remote_data_source.dart';
import 'package:tara_driver_application/data/models/vehical_model.dart';

enum VehicleStatus { initial, loading, loaded, error }

// Replaces VehicalBloc (docs/12) — same datasource, GetX front.
class VehicleController extends GetxController {
  VehicleController(this._api);

  final GetVehicalRemoteDataSource _api;

  final status = Rx<VehicleStatus>(VehicleStatus.initial);
  final vehicalData = Rx<VehicalTypeEntities?>(null);
  final error = ''.obs;

  Future<void> getAllVehicles() async {
    status.value = VehicleStatus.loading;
    try {
      vehicalData.value = await _api.getAllVehicalApi();
      status.value = VehicleStatus.loaded;
    } catch (e) {
      error.value = e.toString();
      status.value = VehicleStatus.error;
    }
  }
}
