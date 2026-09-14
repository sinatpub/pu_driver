import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'widgets/history_card_widget.dart';

/// Drawer tab 1 ("RIDING_HISTORY"). Was `history_booking/riding_history_screen.dart`.
///
/// Stateful only to own the [ScrollController] that drives infinite scroll —
/// that is widget lifetime, not screen state. Everything else moved to
/// [HistoryLogic] / `HistoryState`.
///
/// UX-redesign S1 (`03 S09`): `TTabs`, skeleton cards while loading, and real
/// empty and error states for both tabs. The status filter, the paging
/// trigger, pull-to-refresh and the paging footer are unchanged.
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
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        logic.fetchNext();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
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
                  onChanged: logic.switchTab,
                )),
          ),
          Expanded(child: Obx(_body)),
        ],
      ),
    );
  }

  Widget _body() {
    final items = logic.items;
    final bool isCompletedTab = logic.state.indexActive.value == 0;

    if (items.isEmpty) {
      if (logic.isLoading.value) return const _SkeletonList();
      if (logic.errorMessage.value != null) {
        return Center(
          child: SingleChildScrollView(
            child: TErrorState(
              title: logic.errorMessage.value!.tr(),
              actionLabel: 'TRY_AGAIN'.tr(),
              onAction: logic.reload,
            ),
          ),
        );
      }
      if (logic.hasReachedMax.value) {
        return RefreshIndicator(
          onRefresh: logic.reload,
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
                      title: isCompletedTab
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
      // Between clearing the list and the first fetch flipping isLoading.
      return const _SkeletonList();
    }

    return RefreshIndicator(
      onRefresh: logic.reload,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          Insets.tabContent,
          Insets.s12,
          Insets.tabContent,
          Insets.s24,
        ),
        itemCount: items.length + (logic.hasReachedMax.value ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          if (index < items.length) {
            return HistoryCardWidget(
              item: items[index],
              canOpenDetail: isCompletedTab,
            );
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
