import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/core/pagination/paginated_controller.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/models/history_driver_info_model.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/repository/history_repository.dart';

import 'state.dart';

/// One tab's trips: the paged list for a single booking status (DD-41).
class HistoryListLogic extends PaginatedController<DataHistory> {
  HistoryListLogic(this._repository, {required this.status});

  final HistoryRepository _repository;

  /// The booking status the API is filtered on.
  final int status;

  bool _started = false;

  /// Fetches the first page, once. The completed list starts with the
  /// screen; the cancelled one when its tab is first shown.
  void ensureLoaded() {
    if (_started) return;
    _started = true;
    fetchNext();
  }

  @override
  Future<List<DataHistory>> fetchPage(int page) async {
    final result = await _repository.getHistory(page: page, status: status);
    return result.when(
      ok: (model) => model.data ?? [],
      err: (error) => throw error,
    );
  }
}

/// D-09 (`12`). Moved out of `features/history/presentation/controller/` per
/// `14` §3.6.
///
/// DD-41: the two tabs are pages the driver swipes between, so each keeps its
/// own list ([lists]) and its own place in it. Until then one list was
/// reloaded from page 1 on every tab switch; now a list is fetched the first
/// time its tab shows and kept. Pull-to-refresh still reloads it.
class HistoryLogic extends GetxController {
  HistoryLogic(HistoryRepository repository)
      : lists = <HistoryListLogic>[
          for (final int status in HistoryState.statuses)
            HistoryListLogic(repository, status: status),
        ];

  final HistoryState state = HistoryState();

  /// Index-aligned with the tabs: completed, cancelled.
  final List<HistoryListLogic> lists;

  @override
  void onInit() {
    super.onInit();
    lists[state.indexActive.value].ensureLoaded();
  }

  /// The tab in view changed — by a tap or at the end of a swipe.
  void switchTab(int index) {
    if (state.indexActive.value == index) return;
    state.indexActive.value = index;
    lists[index].ensureLoaded();
  }

  @override
  void onClose() {
    for (final HistoryListLogic list in lists) {
      list.dispose();
    }
    super.onClose();
  }
}
