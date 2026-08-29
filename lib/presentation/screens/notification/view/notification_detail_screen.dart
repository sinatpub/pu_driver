import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/features/notifications/data/datasource/notification_datasource.dart';
import 'package:tara_driver_application/features/notifications/data/repository/notification_repository.dart';
import 'package:tara_driver_application/features/notifications/presentation/controller/notification_detail_controller.dart';

class NotificationDetailPage extends StatefulWidget {
  final String? notificationId;
  final bool? appOpened;
  const NotificationDetailPage({super.key, required this.notificationId, required this.appOpened});

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  late final NotificationDetailController controller;

  String formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date).toLocal();
    return DateFormat('dd-MMM-yyyy hh:mm a').format(dateTime);
  }


  @override
  void initState() {
    super.initState();
    controller = NotificationDetailController(NotificationRepository(NotificationDatasource()));
    controller.load(widget.notificationId ?? '');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: widget.appOpened == true
              ? () => Navigator.pop(context)
              : () => Get.offNamed(AppRoutes.home),
        ),
        centerTitle: true,
        title: Text(
          'NOTIFICATION_DETAIL'.tr(),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() {
          if (controller.status.value == NotificationDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          else if (controller.status.value == NotificationDetailStatus.error) {
            return Center(child: Text(controller.errorMessage.value ?? ''));
          }
          else if (controller.status.value == NotificationDetailStatus.initial) {
            return const SizedBox();
          }
          else {
            final detail = controller.detail.value!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('TITLE'.tr()),
                  Text(
                    detail.data!.title ?? '',
                    style: ThemeConstands.font16SemiBold,
                  ),
                  const SizedBox(height: 12),
                  _label('CREATED_DATE'.tr()),
                  Text(
                    formatDate(detail.data!.updatedAt.toString()),
                    style: ThemeConstands.font14Regular,
                  ),
                  const SizedBox(height: 16),

                  _label('DESCRIPTION'.tr()),
                  Text(
                    detail.data!.description ?? '',
                    style: ThemeConstands.font16Regular,
                  ),
      
                  if (detail.data!.files != null && detail.data!.files!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _label('Images'),
                    const SizedBox(height: 8),
                    SizedBox(
                      child: ListView.separated(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        scrollDirection: Axis.vertical,
                        itemCount: detail.data!.files!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.network(
                                  detail.data!.files![index].fileUrl ?? '',
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
                    ),
                  ],
                ],
              ),
            );
          }
      }),
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
