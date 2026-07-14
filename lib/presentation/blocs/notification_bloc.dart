import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tara_driver_application/data/datasources/notification_api.dart';
import 'package:tara_driver_application/data/models/notifcation_model.dart';


//===============. event ===================

sealed class NotificationEvent {}

class FetchPaginatedData extends NotificationEvent {}
class RefreshPaginatedData extends NotificationEvent {}
class RefreshPaginatedCancelData extends NotificationEvent {}


//===============. state ===================
sealed class NotificationState {}

final class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<DataNotification> items;
  final bool hasReachedMax;

  NotificationLoaded({required this.items, required this.hasReachedMax});
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}


//===============. bloc ===================

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  int currentPage = 1;
  int status = 4;
  int totalPages = 1;
  bool isFetching = false;
  List<DataNotification> allItems = [];

  NotificationBloc() : super(NotificationInitial()) {
    on<FetchPaginatedData>(_onFetchData);
    on<RefreshPaginatedData>(_onRefreshData);
  }

  Future<void> _onFetchData(
      FetchPaginatedData event, Emitter<NotificationState> emit) async {
    if (isFetching) return;
    isFetching = true;

    if (state is NotificationInitial) {
      emit(NotificationLoading());
    }

    try {
      final newItems = await NotificationApi.notificationApi(page: "$currentPage");
      if (newItems.data!.isEmpty) {
        emit(NotificationLoaded(items: allItems, hasReachedMax: true));
      } else {
        currentPage++;
        totalPages = newItems.total!;
        allItems.addAll(newItems.data!);
        emit(NotificationLoaded(items: allItems, hasReachedMax: false));
      }
    } catch (e) {
      emit(NotificationError("Failed to load data"));
    } finally {
      isFetching = false;
    }
  }

  Future<void> _onRefreshData(
      RefreshPaginatedData event, Emitter<NotificationState> emit) async {
    isFetching = true;
    currentPage = 1;
    allItems.clear();

    try {
      final response = await NotificationApi.notificationApi(page: "$currentPage");
      currentPage++;
      totalPages = response.total!;
      allItems.addAll(response.data!);

      emit(NotificationLoaded(items: allItems, hasReachedMax: currentPage > totalPages));
    } catch (e) {
      emit(NotificationError("Failed to refresh data"));
    } finally {
      isFetching = false;
    }
  }

}
