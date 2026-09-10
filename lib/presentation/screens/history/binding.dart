import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/history/data/datasource/history_datasource.dart';
import 'package:tara_driver_application/features/history/data/repository/history_repository.dart';

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
