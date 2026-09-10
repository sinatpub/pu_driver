import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/presentation/widgets/simmer_widget.dart';

import 'logic.dart';

/// Was `notification/view/notification_screen.dart`. Stateful only to own the
/// [ScrollController] driving infinite scroll — same reasoning as `history/`.
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: Text("CHANNEL".tr()),
        centerTitle: true,
      ),
      body: Container(
        color: AppColors.light2,
        child: Obx(() {
          final items = logic.items;
          if (logic.isLoading.value && items.isEmpty) {
            return const ShimmerNotification();
          }
          if (logic.errorMessage.value != null && items.isEmpty) {
            return Center(child: Text(logic.errorMessage.value!.tr()));
          }
          return RefreshIndicator(
            onRefresh: logic.reload,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length + (logic.hasReachedMax.value ? 0 : 1),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return Center(
                    child: items.length < 10
                        ? Container()
                        : const CircularProgressIndicator(),
                  );
                }
                final item = items[index];
                return MaterialButton(
                  elevation: 0,
                  padding: const EdgeInsets.all(12),
                  onPressed: () => Get.toNamed(
                    AppRoutes.notificationDetail,
                    arguments: NotificationDetailArgs(
                      notificationId: item.id.toString(),
                      appOpened: true,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: item.status == 0 ? AppColors.light4 : Colors.white,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active,
                          color: AppColors.success, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title.toString(),
                                    style: ThemeConstands.font16SemiBold,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  item.releaseDate.toString(),
                                  style: ThemeConstands.font14Regular
                                      .copyWith(color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description.toString(),
                              style: ThemeConstands.font14Regular
                                  .copyWith(color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
