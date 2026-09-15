import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/presentation/screens/history/data/models/history_driver_info_model.dart';
import 'package:tara_driver_application/presentation/screens/history/widgets/history_card_widget.dart';
import 'package:tara_driver_application/presentation/screens/history_detail/view.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import '../../../helpers/localized_host.dart';

/// UX-redesign S1 — the history card and the history detail card
/// (`03 S09`/`S10`, `DD-19`, `DD-20`).
///
/// `history/view.dart` and `history_detail/view.dart` are not pumped: they
/// reach for GetX controllers, and the detail screen embeds a `GoogleMap`
/// platform view. Paging, pull-to-refresh, the empty/error states and the
/// navigation arguments are verified on a device (roadmap S1 Verification).
///
/// The card is not tapped here either — its tap calls `Get.toNamed`. What is
/// asserted: only a completed card is tappable, the fake map thumbnail is
/// gone, and the old "UNKNOWN" / hidden-destination rules still hold.
DataHistory _trip({required int status, required String statusName}) {
  return DataHistory.fromJson(<String, dynamic>{
    'id': 1,
    'start_latitude': '11.5564',
    'start_longitude': '104.9282',
    'end_latitude': '11.5700',
    'end_longitude': '104.9300',
    'start_time': '2026-09-12 09:30:00',
    'start_address': 'St. 271, Phnom Penh',
    'end_address': 'Sisowath Quay',
    'status': status,
    'status_name': statusName,
    'passenger': <String, dynamic>{'name': 'Mey Lin'},
    'payment': <String, dynamic>{
      'invoice_id': 7712,
      'distance': '3.5 km',
      'duration': '14 mins',
      'amount': '7600',
      'payment_method': 'Cash',
    },
  });
}

void main() {
  group('HistoryCardWidget', () {
    testWidgets('completed card is tappable and shows the trip',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          HistoryCardWidget(
            item: _trip(status: 4, statusName: 'completed'),
            canOpenDetail: true,
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('#7712'), findsOneWidget);
      expect(find.text('៛7,600'), findsOneWidget);
      expect(find.text('St. 271, Phnom Penh'), findsOneWidget);
      expect(find.text('Sisowath Quay'), findsOneWidget);
      expect(find.text('3.50 km'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Destination: Sisowath Quay')),
        findsOneWidget,
      );
      // DD-19: the whole card is the tap target.
      expect(find.byType(InkWell), findsOneWidget);
      // The fake thumbnail is gone.
      expect(
          find.byType(DecoratedBox).evaluate().where((Element e) {
            final DecoratedBox box = e.widget as DecoratedBox;
            final Decoration d = box.decoration;
            return d is BoxDecoration && d.image != null;
          }),
          isEmpty);
    });

    testWidgets('cancelled card is not tappable and hides the destination',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          HistoryCardWidget(
            item: _trip(status: 5, statusName: 'cancelled'),
            canOpenDetail: false,
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.byType(InkWell), findsNothing);
      // Pickup and duration fall back to "Unknown", as the old card did.
      expect(find.text('Unknown'), findsNWidgets(2));
      expect(find.text('Sisowath Quay'), findsNothing);
      // The destination line is not rendered at all, not merely blank.
      expect(find.bySemanticsLabel(RegExp('Destination:')), findsNothing);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is TBadge && w.tone == TBadgeTone.danger,
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('HistoryCardSkeleton renders', (WidgetTester t) async {
    await t.pumpWidget(localizedHost(const HistoryCardSkeleton()));
    await t.pump();
    expect(find.byType(TSkeleton), findsWidgets);
  });

  testWidgets('TripDetailCard shows only what the args carry',
      (WidgetTester t) async {
    await t.pumpWidget(
      localizedHost(
        const TripDetailCard(
          distance: '3.50 km',
          duration: '14:00',
          amount: '៛7,600',
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('3.50 km'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('៛7,600'), findsOneWidget);
    expect(find.byType(TKeyValueRow), findsNWidgets(3));
    expect(find.byType(TButton), findsNothing); // no replay (DD-20)
  });
}
