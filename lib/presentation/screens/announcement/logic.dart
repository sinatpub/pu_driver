import 'package:tara_driver_application/core/pagination/paginated_controller.dart';
import 'package:tara_driver_application/features/notifications/data/models/notifcation_model.dart';
import 'package:tara_driver_application/features/notifications/data/repository/notification_repository.dart';

import 'state.dart';

/// D-10 (`12`). Moved out of `features/notifications/presentation/controller/`
/// per `14` §3.6. `notification_screen.dart` used to build
/// `NotificationListController(NotificationRepository(NotificationDatasource()))`
/// by hand in `initState`; that graph is now [AnnouncementBinding]'s job.
class AnnouncementLogic extends PaginatedController<DataNotification> {
  AnnouncementLogic(this._repository);

  final NotificationRepository _repository;
  final AnnouncementState state = AnnouncementState();

  @override
  void onInit() {
    super.onInit();
    fetchNext();
  }

  @override
  Future<List<DataNotification>> fetchPage(int page) async {
    final result = await _repository.getAnnouncements(page: page);
    return result.when(
      ok: (model) => model.data ?? [],
      err: (error) => throw error,
    );
  }
}
