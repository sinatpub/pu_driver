import 'package:get/get.dart' hide Trans;

import 'logic.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashLogic>(() => SplashLogic(), fenix: true);
  }
}
