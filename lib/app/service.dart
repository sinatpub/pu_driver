import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/home/data/datasource/home_datasource.dart';
import 'package:tara_driver_application/features/home/data/repository/home_repository.dart';

import 'logic.dart';

/// The only place permanent DI happens (`14` §3.5). Everything else is
/// registered by a route's `Bindings`.
Future<void> initialService() async {
  Get.put<HomeRepository>(HomeRepository(HomeDatasource()), permanent: true);
  Get.put<AppLogic>(AppLogic(Get.find()), permanent: true);
}
