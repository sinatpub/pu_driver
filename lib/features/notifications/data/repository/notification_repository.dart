import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/features/notifications/data/datasource/notification_datasource.dart';
import 'package:tara_driver_application/features/notifications/data/models/notifcation_model.dart';
import 'package:tara_driver_application/features/notifications/data/models/notification_detail_model.dart';

class NotificationRepository {
  NotificationRepository(this._datasource);

  final NotificationDatasource _datasource;

  Future<Result<NotificationModel>> getAnnouncements({required int page}) =>
      _datasource.getAnnouncements(page: page);

  Future<Result<DetailNotificationModel>> getAnnouncement(
          {required String id}) =>
      _datasource.getAnnouncement(id: id);
}
