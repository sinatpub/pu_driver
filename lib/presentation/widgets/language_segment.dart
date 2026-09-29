import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/repository/language_data.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C1 — the language control, inline instead of a bottom sheet.
///
/// `allLangs` holds exactly two entries (English, ខ្មែរ) and the app supports
/// exactly those two locales, so a segmented control fits where a sheet and a
/// list were doing the work of a two-way switch.
///
/// Switching calls `context.setLocale` and `Get.updateLocale`. The sheet it
/// replaces also popped twice on selection — once for itself and once for the
/// drawer — which an inline control has no reason to do. The drawer simply
/// stays open, and the app rebuilds in the new language underneath it.
class LanguageSegment extends StatelessWidget {
  const LanguageSegment({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Lang> langs = allLangs;
    final String current = context.locale.languageCode;
    final int selected = langs.indexWhere((Lang l) => l.sublang == current);

    return TSegmented(
      options: langs.map((Lang l) => l.title).toList(),
      selected: selected < 0 ? 0 : selected,
      onChanged: (int index) async {
        final Locale locale = Locale(langs[index].sublang);
        await context.setLocale(locale);
        // GetMaterialApp builds with `Get.locale ?? locale`, and `Get.locale`
        // is fixed to the start locale on first build — so `setLocale` alone
        // never reached Flutter's localizations and the app stayed in
        // English. `updateLocale` moves `Get.locale` too and rebuilds every
        // open screen (they read strings with `String.tr()`, which does not
        // subscribe to locale changes).
        await Get.updateLocale(locale);
      },
    );
  }
}
