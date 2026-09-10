import 'package:get/get.dart' hide Trans;

/// Shared page-by-page list controller (D-09/D-10, docs/12 §5 — "merge
/// paging"). `HistoryBookBloc` and `NotificationBloc` were near-identical
/// copies of the same currentPage/isFetching/hasReachedMax bookkeeping;
/// this is that logic written once.
abstract class PaginatedController<T> extends GetxController {
  final items = <T>[].obs;
  final isLoading = false.obs;
  final hasReachedMax = false.obs;
  final errorMessage = RxnString();

  int _page = 1;
  bool _isFetching = false;

  /// Fetch one page (1-indexed). An empty result marks the list exhausted.
  Future<List<T>> fetchPage(int page);

  Future<void> fetchNext() async {
    if (_isFetching || hasReachedMax.value) return;
    _isFetching = true;
    if (items.isEmpty) isLoading.value = true;

    try {
      final page = await fetchPage(_page);
      if (page.isEmpty) {
        hasReachedMax.value = true;
      } else {
        _page++;
        items.addAll(page);
      }
      errorMessage.value = null;
    } catch (_) {
      errorMessage.value = 'FAILED_TO_LOAD_DATA';
    } finally {
      isLoading.value = false;
      _isFetching = false;
    }
  }

  /// Not named `refresh` — GetxController already declares that (forces a
  /// GetBuilder rebuild) and overriding it would silently change its meaning.
  Future<void> reload() async {
    _page = 1;
    hasReachedMax.value = false;
    items.clear();
    await fetchNext();
  }
}
