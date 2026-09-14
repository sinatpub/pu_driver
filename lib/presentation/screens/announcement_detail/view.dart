import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/routes/app_routes.dart';

import 'logic.dart';
import 'state.dart';

/// Was `notification/view/notification_detail_screen.dart`.
///
/// UX-redesign S3 (`03 S13`): `TAppBar` "Announcements", then a card with the
/// title (17/700), the date as a caption, the body (14/1.65, secondary) and
/// the existing images full width with `r.md` corners. Loading is a skeleton;
/// an error offers Try again → `logic.load`.
///
/// Back keeps the FCM rule exactly: opened from inside the app it pops, opened
/// cold from a push (`appOpened != true`) it goes to home.
class AnnouncementDetailPage extends StatelessWidget {
  const AnnouncementDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<AnnouncementDetailLogic>();

    return Scaffold(
      backgroundColor: context.colors.bgPage,
      appBar: TAppBar(
        title: 'ANNOUNCEMENTS'.tr(),
        onBack: logic.appOpened == true
            ? () => Navigator.pop(context)
            : () => Get.offNamed(AppRoutes.home),
      ),
      body: Obx(() {
        switch (logic.state.status.value) {
          case AnnouncementDetailStatus.initial:
          case AnnouncementDetailStatus.loading:
            return const AnnouncementDetailSkeleton();
          case AnnouncementDetailStatus.error:
            return Center(
              child: SingleChildScrollView(
                child: TErrorState(
                  title: 'FAILED_TO_LOAD_DATA'.tr(),
                  message: logic.state.errorMessage.value,
                  actionLabel: 'TRY_AGAIN'.tr(),
                  onAction: () => logic.load(logic.notificationId ?? ''),
                ),
              ),
            );
          case AnnouncementDetailStatus.loaded:
            final data = logic.state.detail.value!.data!;
            return AnnouncementDetailBody(
              title: data.title ?? '',
              date: formatAnnouncementDate(data.updatedAt),
              body: data.description ?? '',
              imageUrls: <String>[
                for (final file in data.files ?? const []) file.fileUrl ?? '',
              ],
            );
        }
      }),
    );
  }
}

/// `dd-MMM-yyyy hh:mm a` in local time, as before; null when there is no
/// parseable date (the old `DateTime.parse('null')` threw inside `build`).
String? formatAnnouncementDate(String? date) {
  final DateTime? parsed = date == null ? null : DateTime.tryParse(date);
  if (parsed == null) return null;
  return DateFormat('dd-MMM-yyyy hh:mm a').format(parsed.toLocal());
}

class AnnouncementDetailBody extends StatelessWidget {
  const AnnouncementDetailBody({
    super.key,
    required this.title,
    required this.body,
    this.date,
    this.imageUrls = const <String>[],
  });

  final String title;
  final String? date;
  final String body;
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Insets.s16,
        Insets.s16,
        Insets.s16,
        Insets.s24,
      ),
      child: TCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: context.texts.bodyStrong.copyWith(
                fontSize: 17,
                color: c.textPrimary,
              ),
            ),
            if (date != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                date!,
                style: context.texts.caption.copyWith(color: c.textSecondary),
              ),
            ],
            const SizedBox(height: Insets.s12),
            Text(
              body,
              style: context.texts.body.copyWith(
                fontSize: 14,
                height: 1.65,
                color: c.textSecondary,
              ),
            ),
            for (final String url in imageUrls) ...<Widget>[
              const SizedBox(height: Insets.s12),
              _AnnouncementImage(url: url),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnnouncementImage extends StatelessWidget {
  const _AnnouncementImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final Widget placeholder = ColoredBox(
      color: c.bgSunken,
      child: Center(
        child: TIcon(DsIcons.bell, size: TIconSize.lg, color: c.textSecondary),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
            if (progress == null) return child;
            return const TSkeleton.box(radius: Radii.md);
          },
          errorBuilder: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}

class AnnouncementDetailSkeleton extends StatelessWidget {
  const AnnouncementDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Insets.s16),
      child: TCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TSkeleton.line(width: 220),
            SizedBox(height: Insets.s8),
            TSkeleton(width: 120, height: 12),
            SizedBox(height: Insets.s16),
            TSkeleton(height: 12),
            SizedBox(height: Insets.s8),
            TSkeleton(height: 12),
            SizedBox(height: Insets.s8),
            TSkeleton(width: 180, height: 12),
          ],
        ),
      ),
    );
  }
}
