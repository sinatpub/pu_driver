import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/notifications/data/repository/notification_repository.dart';

import 'state.dart';

/// D-10 (`12`). Moved out of `features/notifications/presentation/controller/`
/// per `14` §3.6.
///
/// [notificationId] and [appOpened] arrive as typed route arguments
/// ([NotificationDetailArgs], `14` §4.2) and are resolved by the binding, so
/// the view no longer has to carry them as widget fields.
class AnnouncementDetailLogic extends GetxController {
  AnnouncementDetailLogic(
    this._repository, {
    required this.notificationId,
    required this.appOpened,
  });

  final NotificationRepository _repository;
  final String? notificationId;

  /// False when the screen was opened cold from a push notification — the
  /// back button then routes home instead of popping onto an empty stack.
  final bool? appOpened;

  final AnnouncementDetailState state = AnnouncementDetailState();

  @override
  void onInit() {
    super.onInit();
    load(notificationId ?? '');
  }

  Future<void> load(String id) async {
    state.status.value = AnnouncementDetailStatus.loading;
    final result = await _repository.getAnnouncement(id: id);
    result.when(
      ok: (data) {
        state.detail.value = data;
        state.status.value = AnnouncementDetailStatus.loaded;
      },
      err: (error) {
        state.errorMessage.value = error.message;
        state.status.value = AnnouncementDetailStatus.error;
      },
    );
  }
}
