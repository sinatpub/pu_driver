import 'package:get/get.dart' hide Trans;

import 'logic.dart';

class ContactUsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ContactUsLogic>(() => ContactUsLogic(), fenix: true);
  }
}
