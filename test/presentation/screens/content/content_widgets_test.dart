import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/contact_us/view.dart';
import 'package:tara_driver_application/presentation/screens/term_condition/state.dart';
import 'package:tara_driver_application/presentation/screens/term_condition/view.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign S3 — Terms rows, Contact rows and the shared `TAppBar`
/// (`03 S14/S15`). Launching the dialer and mail client is device-verified.
Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(khmer: false),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('TermRow numbers each term on a brand badge',
      (WidgetTester t) async {
    final List<String> keys = TermConditionState().termKeys;
    await t.pumpWidget(
      _host(
        Column(
          children: <Widget>[
            for (int i = 0; i < keys.length; i++)
              TermRow(number: i + 1, text: 'Term ${i + 1}'),
          ],
        ),
      ),
    );

    expect(keys, hasLength(5));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Term 1'), findsOneWidget);
    final Text number = t.widget<Text>(find.text('1'));
    expect(number.style!.color, TaarraaColors.light.brandText);
  });

  group('ContactRow', () {
    testWidgets('a tappable row has a chevron and reports taps',
        (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(
        _host(
          ContactRow(
            icon: DsIcons.phone,
            label: 'Smart: +855 70 427 213',
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.byType(TIcon), findsNWidgets(2));
      await t.tap(find.text('Smart: +855 70 427 213'));
      expect(taps, 1);
    });

    testWidgets('the address row is information, not a button',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(const ContactRow(icon: DsIcons.home, label: '#74, Street 192')),
      );

      expect(find.byType(TIcon), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('TAppBar', () {
    testWidgets('back uses the caller override when given',
        (WidgetTester t) async {
      bool backed = false;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(khmer: false),
          home: Scaffold(
            appBar:
                TAppBar(title: 'Announcements', onBack: () => backed = true),
          ),
        ),
      );

      expect(find.text('Announcements'), findsOneWidget);
      await t.tap(find.byType(TIconButton));
      expect(backed, isTrue);
    });

    testWidgets('back pops the route by default', (WidgetTester t) async {
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          theme: AppTheme.light(khmer: false),
          home: const Scaffold(body: Text('root')),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(appBar: TAppBar(title: 'Detail')),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      await t.tap(find.byType(TIconButton));
      await t.pumpAndSettle();
      expect(find.text('root'), findsOneWidget);
      expect(find.text('Detail'), findsNothing);
    });
  });
}
