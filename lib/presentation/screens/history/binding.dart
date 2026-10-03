import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/presentation/screens/history/data/datasource/history_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/repository/history_repository.dart';

import 'logic.dart';

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HistoryDatasource>(() => HistoryDatasource(), fenix: true);
    Get.lazyPut<HistoryRepository>(() => HistoryRepository(Get.find()),
        fenix: true);
    Get.lazyPut<HistoryLogic>(() => HistoryLogic(Get.find()), fenix: true);
  }
}
