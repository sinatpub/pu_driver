import 'package:get/get.dart' hide Trans;

/// Which tab is showing: 0 = completed, 1 = cancelled.
///
/// The list itself (`items`, `isLoading`, `hasReachedMax`, `errorMessage`)
/// lives on [PaginatedController], the shared paging base that `HistoryLogic`
/// extends — a deliberate exception to `14` §3.3, since that state is owned by
/// a base class shared with the announcement list, not by this screen.
class HistoryState {
  final RxInt indexActive = 0.obs;

  /// Booking status the API is filtered on. Driver history only ever shows
  /// completed (4) or cancelled (5) trips.
  int get filterStatus => indexActive.value == 0 ? 4 : 5;
}
