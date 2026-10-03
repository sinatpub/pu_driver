import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'widgets/history_card_widget.dart';
import 'widgets/history_days.dart';

/// Drawer tab 1 ("RIDING_HISTORY"). Was `history_booking/riding_history_screen.dart`.
///
/// UX-redesign S1 (`03 S09`): `TTabs`, skeleton cards while loading, and real
/// empty and error states for both tabs.
///
/// DD-40: the trips are grouped by day, with a "Today" / "Yesterday" /
/// "Mon 28 Sep" header before each day's run — presentation only, each list
/// keeps the server's order.
///
/// DD-41: the two tabs are pages. Swiping sideways moves between them with
/// the tab thumb following the finger, and tapping a tab slides to its page.
/// Each page keeps its own list, scroll position, paging trigger and
/// pull-to-refresh.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Resolved on each access, never cached: GetX owns this instance's
  // lifetime, and a `final` field would keep pointing at a disposed one
  // if the route is left and re-entered (hit on device 2026-09-06 —
  // "A TextEditingController was used after being disposed").
  HistoryLogic get logic => Get.find<HistoryLogic>();

  late final PageController _pages =
      PageController(initialPage: logic.state.indexActive.value);

  /// The page position, fractional mid-swipe; drives the tab thumb.
  late final ValueNotifier<double> _position =
      ValueNotifier<double>(logic.state.indexActive.value.toDouble());

  @override
  void initState() {
    super.initState();
    _pages.addListener(() {
      if (_pages.hasClients) _position.value = _pages.page ?? _position.value;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _position.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    if (reduceMotion(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: Motion.screen,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return ColoredBox(
      color: c.bgPage,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.tabContent,
              Insets.s12,
              Insets.tabContent,
              Insets.s4,
            ),
            child: Obx(() => TTabs(
                  labels: <String>['COMPLETED'.tr(), 'CANCELLED'.tr()],
                  index: logic.state.indexActive.value,
                  position: _position,
                  onChanged: _goToTab,
                )),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: logic.switchTab,
              children: <Widget>[
                for (int i = 0; i < logic.lists.length; i++)
                  _HistoryList(list: logic.lists[i], isCompletedTab: i == 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tab's page: its list, with its own scroll position kept while the
/// other page is showing.
class _HistoryList extends StatefulWidget {
  const _HistoryList({required this.list, required this.isCompletedTab});

  final HistoryListLogic list;
  final bool isCompletedTab;

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList>
    with AutomaticKeepAliveClientMixin<_HistoryList> {
  final ScrollController _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels == _scroll.position.maxScrollExtent) {
        widget.list.fetchNext();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(_body);
  }

  Widget _body() {
    final HistoryListLogic list = widget.list;
    final items = list.items;

    if (items.isEmpty) {
      if (list.isLoading.value) return const _SkeletonList();
      if (list.errorMessage.value != null) {
        return Center(
          child: SingleChildScrollView(
            child: TErrorState(
              title: list.errorMessage.value!.tr(),
              actionLabel: 'TRY_AGAIN'.tr(),
              onAction: list.reload,
            ),
          ),
        );
      }
      if (list.hasReachedMax.value) {
        return RefreshIndicator(
          onRefresh: list.reload,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Scrollable so pull-to-refresh still works on an empty account.
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: TEmptyState(
                      icon: DsIcons.calendar,
                      title: widget.isCompletedTab
                          ? 'EMPTY_COMPLETED'.tr()
                          : 'EMPTY_CANCELLED'.tr(),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
      // Before this tab's first fetch has flipped isLoading.
      return const _SkeletonList();
    }

    final List<HistoryRow> rows = historyRows(items);
    final DateTime now = DateTime.now();
    final String locale = context.locale.toString();

    return RefreshIndicator(
      onRefresh: list.reload,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Insets.tabContent,
          Insets.s4,
          Insets.tabContent,
          Insets.s24,
        ),
        itemCount: rows.length + (list.hasReachedMax.value ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          if (index < rows.length) {
            return switch (rows[index]) {
              HistoryDayHeader(:final DateTime day) => _DayHeader(
                  label: historyDayLabel(day, now: now, locale: locale),
                ),
              HistoryTripRow(:final item) => HistoryCardWidget(
                  item: item,
                  canOpenDetail: widget.isCompletedTab,
                ),
            };
          }
          return Center(
            child: items.length < 10
                ? const SizedBox.shrink()
                : const CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

/// The day a run of trips happened on (DD-40).
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Insets.s4, Insets.s8, Insets.s4, 0),
        child: Text(
          label,
          style:
              context.texts.label.copyWith(color: context.colors.textPrimary),
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Insets.tabContent,
        Insets.s12,
        Insets.tabContent,
        Insets.s24,
      ),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const HistoryCardSkeleton(),
    );
  }
}
