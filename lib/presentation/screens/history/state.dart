import 'package:get/get.dart' hide Trans;

/// Which tab is showing: 0 = completed, 1 = cancelled.
///
/// Each tab's list (`items`, `isLoading`, `hasReachedMax`, `errorMessage`)
/// lives on a `HistoryListLogic`, which extends [PaginatedController], the
/// paging base shared with the announcement list — a deliberate exception to
/// `14` §3.3, since that state is owned by a shared base class, not by this
/// screen.
class HistoryState {
  final RxInt indexActive = 0.obs;

  /// The booking status each tab's list is filtered on. Driver history only
  /// ever shows completed (4) or cancelled (5) trips.
  static const List<int> statuses = <int>[4, 5];
}
