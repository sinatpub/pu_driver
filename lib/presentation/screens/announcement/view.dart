import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/routes/route_arguments.dart';

import 'logic.dart';
import 'widgets/news_card.dart';

/// Was `notification/view/notification_screen.dart`. Stateful only to own the
/// [ScrollController] driving infinite scroll — same reasoning as `history/`.
///
/// UX-redesign S3 (`03 S12`, `DD-06`): still the pushed route from the bell,
/// now with `TAppBar` "Announcements", `NewsCard`s (unread = brand border and
/// dot, same `status == 0` rule), skeleton cards, and real empty and error
/// states. Paging, pull-to-refresh and the detail arguments are unchanged.
class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  // Resolved on each access, never cached: GetX owns this instance's
  // lifetime, and a `final` field would keep pointing at a disposed one
  // if the route is left and re-entered (hit on device 2026-09-06 —
  // "A TextEditingController was used after being disposed").
  AnnouncementLogic get logic => Get.find<AnnouncementLogic>();
  final ScrollController _scrollController = ScrollController();

  static const EdgeInsets _listPadding = EdgeInsets.fromLTRB(
    Insets.s16,
    Insets.s16,
    Insets.s16,
    Insets.s24,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        logic.fetchNext();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPage,
      appBar: TAppBar(title: 'ANNOUNCEMENTS'.tr()),
      body: Obx(_body),
    );
  }

  Widget _body() {
    final items = logic.items;

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
              // Scrollable so pull-to-refresh still works with no items.
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: TEmptyState(
                      icon: DsIcons.bell,
                      title: 'EMPTY_ANNOUNCEMENTS'.tr(),
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
        padding: _listPadding,
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (logic.hasReachedMax.value ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          if (index >= items.length) {
            return Center(
              child: items.length < 10
                  ? const SizedBox.shrink()
                  : const CircularProgressIndicator(),
            );
          }
          final item = items[index];
          return NewsCard(
            title: item.title.toString(),
            body: item.description.toString(),
            date: item.releaseDate.toString(),
            unread: item.status == 0,
            onTap: () => Get.toNamed(
              AppRoutes.notificationDetail,
              arguments: NotificationDetailArgs(
                notificationId: item.id.toString(),
                appOpened: true,
              ),
            ),
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
      padding: _AnnouncementPageState._listPadding,
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const NewsCardSkeleton(),
    );
  }
}
