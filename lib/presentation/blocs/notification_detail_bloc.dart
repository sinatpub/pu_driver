import 'package:bloc/bloc.dart';
import 'package:tara_driver_application/data/datasources/notification_api.dart';
import 'package:tara_driver_application/data/models/notification_detail_model.dart';

/// Sealed class for NotificationDetailEvent
sealed class NotificationDetailEvent {}
class LoadNotificationDetail extends NotificationDetailEvent {
  final String notificationId;
  LoadNotificationDetail(this.notificationId);
}

/// Sealed class for NotificationDetailState
sealed class NotificationDetailState {}
final class NotificationDetailInitial extends NotificationDetailState {}
final class NotificationDetailLoading extends NotificationDetailState {}
final class NotificationDetailSuccess extends NotificationDetailState {
  final DetailNotificationModel detail;
  NotificationDetailSuccess(this.detail);
}
final class NotificationDetailError extends NotificationDetailState {
  final String message;
  NotificationDetailError(this.message);
}

class NotificationDetailBloc extends Bloc<NotificationDetailEvent, NotificationDetailState> {
  final NotificationApi notificationApi = NotificationApi();
  NotificationDetailBloc() : super(NotificationDetailInitial()) {
    on<LoadNotificationDetail>((event, emit) async{
      emit(NotificationDetailLoading());
      try {
        final detail = await NotificationApi.notificationDetailApi(idNotification: event.notificationId);
        emit(NotificationDetailSuccess(detail));
      } catch (e) {
        emit(NotificationDetailError("Failed to load notification detail"));
      } finally {
        // Any cleanup if necessary
      } 
    });
  }
}
