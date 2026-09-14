import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/announcement/widgets/news_card.dart';
import 'package:tara_driver_application/presentation/screens/announcement_detail/view.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import '../../../helpers/localized_host.dart';

/// UX-redesign S3 — announcements list card and detail body (`03 S12/S13`).
///
/// The pages are not pumped: they resolve GetX controllers, and the FCM deep
/// link (background / terminated) can only be exercised on a device.
Finder _unreadDot() => find.byWidgetPredicate(
      (Widget w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).shape == BoxShape.circle,
    );

Border? _cardBorder(WidgetTester t) {
  final Container box = t.widget<Container>(
    find
        .descendant(of: find.byType(TCard), matching: find.byType(Container))
        .first,
  );
  return (box.decoration! as BoxDecoration).border as Border?;
}

void main() {
  group('NewsCard', () {
    testWidgets('unread uses the brand border and a dot',
        (WidgetTester t) async {
      bool tapped = false;
      await t.pumpWidget(
        localizedHost(
          NewsCard(
            title: 'Fuel price update',
            body: 'From Monday the base fare changes.',
            date: '2026-09-12',
            unread: true,
            onTap: () => tapped = true,
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Fuel price update'), findsOneWidget);
      expect(find.text('2026-09-12'), findsOneWidget);
      expect(_unreadDot(), findsOneWidget);
      expect(
        _cardBorder(t)!.top.color,
        TaarraaColors.light.brandIdentity,
      );
      // The dot's label merges into the card's tap target, so a screen reader
      // announces "Unread" with the title.
      expect(find.bySemanticsLabel(RegExp('Unread')), findsOneWidget);

      await t.tap(find.byType(NewsCard));
      expect(tapped, isTrue);
    });

    testWidgets('read has the neutral border and no dot',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          NewsCard(
            title: 'T',
            body: 'B',
            date: 'D',
            unread: false,
            onTap: () {},
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(_unreadDot(), findsNothing);
      expect(_cardBorder(t)!.top.color, TaarraaColors.light.borderDivider);
    });
  });

  group('AnnouncementDetailBody', () {
    testWidgets('shows title, date and body', (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(khmer: false),
          home: const Scaffold(
            body: AnnouncementDetailBody(
              title: 'Holiday hours',
              date: '12-Sep-2026 09:30 AM',
              body: 'Support is closed on Monday.',
            ),
          ),
        ),
      );

      expect(find.text('Holiday hours'), findsOneWidget);
      expect(find.text('12-Sep-2026 09:30 AM'), findsOneWidget);
      expect(find.text('Support is closed on Monday.'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('omits a missing date', (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(khmer: false),
          home: const Scaffold(
            body: AnnouncementDetailBody(title: 'T', body: 'B'),
          ),
        ),
      );
      expect(find.byType(Text), findsNWidgets(2));
    });
  });

  group('formatAnnouncementDate', () {
    test('formats a server timestamp', () {
      expect(
        formatAnnouncementDate('2026-09-12T09:30:00'),
        '12-Sep-2026 09:30 AM',
      );
    });

    test('null or unparseable is null, not a crash', () {
      expect(formatAnnouncementDate(null), isNull);
      expect(formatAnnouncementDate('null'), isNull);
    });
  });

  testWidgets('NewsCardSkeleton renders', (WidgetTester t) async {
    await t.pumpWidget(localizedHost(const NewsCardSkeleton()));
    await t.pump();
    expect(find.byType(TSkeleton), findsWidgets);
  });
}
