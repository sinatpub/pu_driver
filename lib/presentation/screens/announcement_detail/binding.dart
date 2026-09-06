import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/features/notifications/data/datasource/notification_datasource.dart';
import 'package:tara_driver_application/features/notifications/data/repository/notification_repository.dart';

import 'logic.dart';

class AnnouncementDetailBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as NotificationDetailArgs;
    Get.lazyPut<NotificationDatasource>(() => NotificationDatasource(),
        fenix: true);
    Get.lazyPut<NotificationRepository>(
        () => NotificationRepository(Get.find()),
        fenix: true);
    Get.lazyPut<AnnouncementDetailLogic>(
      () => AnnouncementDetailLogic(
        Get.find(),
        notificationId: args.notificationId,
        appOpened: args.appOpened,
      ),
      fenix: true,
    );
  }
}
