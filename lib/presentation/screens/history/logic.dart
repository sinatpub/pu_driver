import 'package:tara_driver_application/core/pagination/paginated_controller.dart';
import 'package:tara_driver_application/presentation/screens/history/data/models/history_driver_info_model.dart';
import 'package:tara_driver_application/presentation/screens/history/data/repository/history_repository.dart';

import 'state.dart';

/// D-09 (`12`). Moved out of `features/history/presentation/controller/` per
/// `14` §3.6.
///
/// `riding_history_screen.dart` used to build a brand-new `HistoryController`
/// on every tab tap and drop the previous one on the floor undisposed. One
/// controller now lives for the screen and [switchTab] re-runs the query,
/// which reproduces the old behavior exactly — `reload()` resets to page 1,
/// clears the list and fetches — without leaking an instance per tap.
class HistoryLogic extends PaginatedController<DataHistory> {
  HistoryLogic(this._repository);

  final HistoryRepository _repository;
  final HistoryState state = HistoryState();

  @override
  void onInit() {
    super.onInit();
    fetchNext();
  }

  @override
  Future<List<DataHistory>> fetchPage(int page) async {
    final result =
        await _repository.getHistory(page: page, status: state.filterStatus);
    return result.when(
      ok: (model) => model.data ?? [],
      err: (error) => throw error,
    );
  }

  Future<void> switchTab(int index) async {
    if (state.indexActive.value == index) return;
    state.indexActive.value = index;
    await reload();
  }
}
