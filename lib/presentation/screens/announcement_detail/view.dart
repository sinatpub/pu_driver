import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/features/notifications/data/models/notification_detail_model.dart';

import 'logic.dart';
import 'state.dart';

/// Was `notification/view/notification_detail_screen.dart`.
class AnnouncementDetailPage extends StatelessWidget {
  const AnnouncementDetailPage({super.key});

  static String _formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date).toLocal();
    return DateFormat('dd-MMM-yyyy hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<AnnouncementDetailLogic>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: logic.appOpened == true
              ? () => Navigator.pop(context)
              : () => Get.offNamed(AppRoutes.home),
        ),
        centerTitle: true,
        title: Text(
          'NOTIFICATION_DETAIL'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
        switch (logic.state.status.value) {
          case AnnouncementDetailStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case AnnouncementDetailStatus.error:
            return Center(child: Text(logic.state.errorMessage.value ?? ''));
          case AnnouncementDetailStatus.initial:
            return const SizedBox();
          case AnnouncementDetailStatus.loaded:
            return _body(logic.state.detail.value!);
        }
      }),
    );
  }

  Widget _body(DetailNotificationModel detail) {
    final data = detail.data!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('TITLE'.tr()),
          Text(data.title ?? '', style: ThemeConstands.font16SemiBold),
          const SizedBox(height: 12),
          _label('CREATED_DATE'.tr()),
          Text(_formatDate(data.updatedAt.toString()),
              style: ThemeConstands.font14Regular),
          const SizedBox(height: 16),
          _label('DESCRIPTION'.tr()),
          Text(data.description ?? '', style: ThemeConstands.font16Regular),
          if (data.files != null && data.files!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _label('Images'),
            const SizedBox(height: 8),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              scrollDirection: Axis.vertical,
              itemCount: data.files!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        data.files![index].fileUrl ?? '',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: ThemeConstands.font18SemiBold.copyWith(color: AppColors.dark1),
      ),
    );
  }
}
