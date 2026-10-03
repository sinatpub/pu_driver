import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pu_taxi_driver/core/theme/app_theme.dart';
import 'package:pu_taxi_driver/presentation/widgets/language_segment.dart';

class _Page extends StatelessWidget {
  const _Page();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: <Widget>[
          const LanguageSegment(),
          Text('NEXT'.tr()),
        ]),
      );
}

/// Regression: `GetMaterialApp` builds with `Get.locale ?? locale`, so
/// `context.setLocale` alone left the app in English. The screen here reads
/// its string with `'KEY'.tr()`, like every real screen does.
void main() {
  testWidgets('switching to Khmer retranslates an open GetX page',
      (WidgetTester t) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    await t.pumpWidget(EasyLocalization(
      supportedLocales: const <Locale>[Locale('km'), Locale('en')],
      path: 'assets/translations',
      startLocale: const Locale('en'),
      child: Builder(
        builder: (BuildContext context) => GetMaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(khmer: false),
          getPages: <GetPage<dynamic>>[
            GetPage<dynamic>(name: '/', page: () => const _Page()),
          ],
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('Next'), findsOneWidget);
    await t.tap(find.text('ខ្មែរ'));
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    expect(find.text('បន្ទាប់'), findsOneWidget);
    await t.tap(find.text('English'));
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    expect(find.text('Next'), findsOneWidget);
  });
}
