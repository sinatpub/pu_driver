import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/notifications/data/models/notification_detail_model.dart';

enum AnnouncementDetailStatus { initial, loading, loaded, error }

class AnnouncementDetailState {
  final Rx<AnnouncementDetailStatus> status =
      Rx<AnnouncementDetailStatus>(AnnouncementDetailStatus.initial);
  final Rxn<DetailNotificationModel> detail = Rxn<DetailNotificationModel>();
  final RxnString errorMessage = RxnString();
}
