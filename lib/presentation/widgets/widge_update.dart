import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/check_platform_device.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:url_launcher/url_launcher.dart';

/// The blocking "you must update" card, shown over the home map when the
/// version check says the installed build is behind.
///
/// UX-redesign C2 restyled it and moved its two hardcoded English strings
/// ("App must update", "Update Now") onto translation keys — a driver reading
/// Khmer previously got English here.
///
/// The platform branch and the store URLs are unchanged. Two incidental
/// tidies: the widget no longer needs to be stateful (its `initState` was
/// empty), and the `setState` that wrapped `launchUrl` is gone — it set
/// nothing and only forced a rebuild.
class WidgetUpdate extends StatelessWidget {
  const WidgetUpdate({super.key});

  void _openStore() {
    final String platform = checkPlatformDevice();
    launchUrl(
      Uri.parse(
        platform == "Android"
            ? AppConstant.playStoreUrl
            : AppConstant.appStoreUrl,
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.s24),
      child: TCard(
        padding: const EdgeInsets.all(Insets.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              "assets/image/png/Tara2.png",
              width: 72,
              height: 72,
            ),
            const SizedBox(height: Insets.s16),
            Text(
              'UPDATE_REQUIRED'.tr(),
              textAlign: TextAlign.center,
              style: context.texts.title.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: Insets.s8),
            Text(
              'UPDATE_VERSION_DISCRIPTION'.tr(),
              textAlign: TextAlign.center,
              style: context.texts.bodySecondary.copyWith(
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: Insets.s24),
            TButton(
              label: 'UPDATE_NOW'.tr(),
              onPressed: _openStore,
            ),
          ],
        ),
      ),
    );
  }
}
