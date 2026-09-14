
import 'package:tara_driver_application/core/api_service/base_api_service.dart';
import 'package:tara_driver_application/data/models/notifcation_model.dart';
import 'package:tara_driver_application/data/models/notification_detail_model.dart';

class NotificationApi {
  static Future<DetailNotificationModel> notificationDetailApi({required String idNotification}) async {
    return BaseApiService().onRequest<DetailNotificationModel>(
        path: "/taxi-driver/announcement/$idNotification",
        method: "GET",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        onSuccess: (result) {
          return DetailNotificationModel?.fromJson(result.data);
        });
  }

  static Future<NotificationModel> notificationApi({required String page,}) async {
    return BaseApiService().onRequest<NotificationModel>(
        path: "/taxi-driver/announcements?page=$page",
        method: "GET",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        onSuccess: (result) {
          return NotificationModel?.fromJson(result.data);
        });
  }
}