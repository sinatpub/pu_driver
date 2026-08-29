import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/notifications/data/models/notification_detail_model.dart';
import 'package:tara_driver_application/features/notifications/data/repository/notification_repository.dart';

enum NotificationDetailStatus { initial, loading, loaded, error }

class NotificationDetailController extends GetxController {
  NotificationDetailController(this._repository);

  final NotificationRepository _repository;

  final status = Rx<NotificationDetailStatus>(NotificationDetailStatus.initial);
  final detail = Rxn<DetailNotificationModel>();
  final errorMessage = RxnString();

  Future<void> load(String id) async {
    status.value = NotificationDetailStatus.loading;
    final result = await _repository.getAnnouncement(id: id);
    result.when(
      ok: (data) {
        detail.value = data;
        status.value = NotificationDetailStatus.loaded;
      },
      err: (error) {
        errorMessage.value = error.message;
        status.value = NotificationDetailStatus.error;
      },
    );
  }
}
