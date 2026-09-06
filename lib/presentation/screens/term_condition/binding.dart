import 'package:get/get.dart' hide Trans;

import 'logic.dart';

class TermConditionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TermConditionLogic>(() => TermConditionLogic(), fenix: true);
  }
}
