import 'package:tara_driver_application/core/pagination/paginated_controller.dart';
import 'package:tara_driver_application/features/history/data/models/history_driver_info_model.dart';
import 'package:tara_driver_application/features/history/data/repository/history_repository.dart';

/// Booking status filters this screen supports (docs/01 §... driver history
/// only ever shows completed or passenger-cancelled trips).
class HistoryController extends PaginatedController<DataHistory> {
  HistoryController(this._repository, {required this.status});

  final HistoryRepository _repository;
  final int status;

  @override
  Future<List<DataHistory>> fetchPage(int page) async {
    final result = await _repository.getHistory(page: page, status: status);
    return result.when(
      ok: (model) => model.data ?? [],
      err: (error) => throw error,
    );
  }
}
