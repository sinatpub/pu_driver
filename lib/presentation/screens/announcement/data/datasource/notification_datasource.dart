import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/presentation/screens/announcement/data/models/notifcation_model.dart';
import 'package:tara_driver_application/presentation/screens/announcement/data/models/notification_detail_model.dart';

class NotificationDatasource {
  NotificationDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Result<NotificationModel>> getAnnouncements({required int page}) {
    return _apiClient.request<NotificationModel>(
      path: '/taxi-driver/announcements',
      method: 'GET',
      query: {'page': page},
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      decode: (response) => NotificationModel.fromJson(response.data),
    );
  }

  Future<Result<DetailNotificationModel>> getAnnouncement(
      {required String id}) {
    return _apiClient.request<DetailNotificationModel>(
      path: '/taxi-driver/announcement/$id',
      method: 'GET',
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      decode: (response) => DetailNotificationModel.fromJson(response.data),
    );
  }
}
