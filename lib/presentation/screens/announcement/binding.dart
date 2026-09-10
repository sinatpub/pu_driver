import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/notifications/data/datasource/notification_datasource.dart';
import 'package:tara_driver_application/features/notifications/data/repository/notification_repository.dart';

import 'logic.dart';

class AnnouncementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationDatasource>(() => NotificationDatasource(),
        fenix: true);
    Get.lazyPut<NotificationRepository>(
        () => NotificationRepository(Get.find()),
        fenix: true);
    Get.lazyPut<AnnouncementLogic>(() => AnnouncementLogic(Get.find()),
        fenix: true);
  }
}
