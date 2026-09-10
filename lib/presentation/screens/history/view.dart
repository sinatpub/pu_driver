import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/presentation/widgets/simmer_widget.dart';

import 'logic.dart';
import 'widgets/history_card_widget.dart';

/// Drawer tab 1 ("RIDING_HISTORY"). Was `history_booking/riding_history_screen.dart`.
///
/// Stateful only to own the [ScrollController] that drives infinite scroll —
/// that is widget lifetime, not screen state. Everything else moved to
/// [HistoryLogic] / `HistoryState`.
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
    return Container(
      color: AppColors.light4,
      child: Column(
        children: [
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _tab(
                      label: "COMPLETED".tr(),
                      index: 0,
                      selected: logic.state.indexActive.value == 0,
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: _tab(
                      label: "CANCELLED".tr(),
                      index: 1,
                      selected: logic.state.indexActive.value == 1,
                    ),
                  ),
                ],
              )),
          Expanded(
            child: Container(
              color: AppColors.light3,
              child: Obx(() {
                final items = logic.items;
                if (logic.isLoading.value && items.isEmpty) {
                  return const ShimmerBookStory();
                }
                if (logic.errorMessage.value != null && items.isEmpty) {
                  return Center(child: Text(logic.errorMessage.value!.tr()));
                }
                return RefreshIndicator(
                  onRefresh: logic.reload,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount:
                        items.length + (logic.hasReachedMax.value ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index < items.length) {
                        return HistoryCardWidget(
                          item: items[index],
                          showMap: logic.state.indexActive.value != 1,
                        );
                      }
                      return Center(
                        child: items.length < 10
                            ? Container()
                            : const CircularProgressIndicator(),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab({
    required String label,
    required int index,
    required bool selected,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => logic.switchTab(index),
          child: Text(
            label,
            style: ThemeConstands.font16SemiBold.copyWith(
              color: selected ? AppColors.red : AppColors.dark2,
            ),
          ),
        ),
        Container(
          width: 100,
          height: 4,
          decoration: BoxDecoration(
            color: selected ? AppColors.red : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}
