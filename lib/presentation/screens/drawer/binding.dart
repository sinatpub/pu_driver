import 'package:get/get.dart' hide Trans;

import 'logic.dart';

class DrawerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DrawerLogic>(() => DrawerLogic(), fenix: true);
  }
}
