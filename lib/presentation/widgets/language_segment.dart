import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/presentation/repository/language_data.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C1 — the language control, inline instead of a bottom sheet.
///
/// `allLangs` holds exactly two entries (English, ខ្មែរ) and the app supports
/// exactly those two locales, so a segmented control fits where a sheet and a
/// list were doing the work of a two-way switch.
///
/// Switching still does one thing: `context.setLocale`. The sheet it replaces
/// also popped twice on selection — once for itself and once for the drawer —
/// which an inline control has no reason to do. The drawer simply stays open,
/// and the app rebuilds in the new language underneath it.
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
      onChanged: (int index) {
        context.setLocale(Locale(langs[index].sublang));
      },
    );
  }
}
