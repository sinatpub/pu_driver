import 'package:tara_driver_application/core/pagination/paginated_controller.dart';
import 'package:tara_driver_application/features/notifications/data/models/notifcation_model.dart';
import 'package:tara_driver_application/features/notifications/data/repository/notification_repository.dart';

class NotificationListController extends PaginatedController<DataNotification> {
  NotificationListController(this._repository);

  final NotificationRepository _repository;

  @override
  Future<List<DataNotification>> fetchPage(int page) async {
    final result = await _repository.getAnnouncements(page: page);
    return result.when(
      ok: (model) => model.data ?? [],
      err: (error) => throw error,
    );
  }
}
