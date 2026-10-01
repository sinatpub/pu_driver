import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/presentation/screens/history/data/models/history_driver_info_model.dart';
import 'package:tara_driver_application/presentation/screens/history/widgets/history_card_widget.dart';
import 'package:tara_driver_application/presentation/screens/history/widgets/history_days.dart';
import 'package:tara_driver_application/presentation/screens/history_detail/contact_window.dart';
import 'package:tara_driver_application/presentation/screens/history_detail/logic.dart';
import 'package:tara_driver_application/presentation/screens/history_detail/view.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'package:tara_driver_application/routes/route_arguments.dart';

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
  group('HistoryCardWidget (DD-41)', () {
    testWidgets('completed: time and amount, the route, then who and how far',
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

      // The day is in the list's header; the card leads with the time.
      expect(find.text('09:30'), findsOneWidget);
      expect(find.text('៛7,600'), findsOneWidget);
      // Only the payment method is a badge: the tab already says "Completed".
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is TBadge && w.label == 'Cash' && w.tone == TBadgeTone.neutral,
        ),
        findsOneWidget,
      );
      expect(find.byType(TBadge), findsOneWidget);
      // Place names only, in semi-bold; the full address is what is spoken.
      expect(find.text('St. 271'), findsOneWidget);
      expect(find.text('Sisowath Quay'), findsOneWidget);
      expect(
        t.widget<Text>(find.text('St. 271')).style!.fontWeight,
        FontWeight.w600,
      );
      expect(
        find.bySemanticsLabel(RegExp('Pickup: St. 271, Phnom Penh')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Destination: Sisowath Quay')),
        findsOneWidget,
      );
      expect(find.text('Mey Lin · #7712'), findsOneWidget);
      expect(find.text('3.5 KM · 14:00'), findsOneWidget);
      // DD-19: the whole card is the tap target — and looks it.
      expect(find.byType(InkWell), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is TIcon && w.asset == DsIcons.chevron,
        ),
        findsOneWidget,
      );
    });

    testWidgets('cancelled: status, passenger and invoice only, not tappable',
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
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is TBadge && w.tone == TBadgeTone.danger,
        ),
        findsOneWidget,
      );
      expect(find.text('09:30'), findsOneWidget);
      expect(find.text('Mey Lin · #7712'), findsOneWidget);
      // No ៛0, no "Unknown", no route, no figures, no method badge.
      expect(find.textContaining('៛'), findsNothing);
      expect(find.text('Unknown'), findsNothing);
      expect(find.text('Sisowath Quay'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Pickup:')), findsNothing);
      expect(find.textContaining('KM'), findsNothing);
      expect(find.text('Cash'), findsNothing);
    });

    testWidgets('the figures drop to their own line when the name has no room',
        (WidgetTester t) async {
      Future<(double name, double figures)> rowsAt(
          Size size, double scale) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(
          localizedHost(
            HistoryCardWidget(
              item: _trip(status: 4, statusName: 'completed'),
              canOpenDetail: true,
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        return (
          t.getCenter(find.text('Mey Lin · #7712')).dy,
          t.getCenter(find.text('3.5 KM · 14:00')).dy,
        );
      }

      // Roomy: one line.
      final (double name, double figures) =
          await rowsAt(const Size(600, 900), 1);
      expect(figures, closeTo(name, 2));

      // 320 px with large text: the figures sit under the name, and the name
      // is not squeezed away.
      final (double narrowName, double narrowFigures) =
          await rowsAt(const Size(320, 900), 1.3);
      expect(narrowFigures, greaterThan(narrowName + 8));
      expect(
        t.getSize(find.text('Mey Lin · #7712')).width,
        greaterThanOrEqualTo(96),
      );
    });

    testWidgets('a trip with no start time falls back to when it was created',
        (WidgetTester t) async {
      final DataHistory item = _trip(status: 5, statusName: 'cancelled')
        ..startTime = null
        ..createdAt = '2026-09-12 08:05:00';
      await t.pumpWidget(
        localizedHost(HistoryCardWidget(item: item, canOpenDetail: false)),
      );
      await t.pumpAndSettle();

      expect(find.text('08:05'), findsOneWidget);
    });
  });

  group('history days (DD-40)', () {
    DataHistory at(String? start) =>
        _trip(status: 4, statusName: 'completed')..startTime = start;

    test('a header goes before the first trip of each day', () {
      final List<HistoryRow> rows = historyRows(<DataHistory>[
        at('2026-10-01 07:14:00'),
        at('2026-10-01 06:02:00'),
        at('2026-09-28 07:14:00'),
      ]);

      expect(
        rows.map((HistoryRow r) => switch (r) {
              HistoryDayHeader(:final DateTime day) =>
                'day ${day.month}/${day.day}',
              HistoryTripRow() => 'trip',
            }),
        <String>['day 10/1', 'trip', 'trip', 'day 9/28', 'trip'],
      );
    });

    test('a trip with no readable date stays under the header above it', () {
      final List<HistoryRow> rows = historyRows(<DataHistory>[
        at('2026-10-01 07:14:00'),
        at(null)..createdAt = null,
      ]);

      expect(rows.whereType<HistoryDayHeader>(), hasLength(1));
      expect(rows.whereType<HistoryTripRow>(), hasLength(2));
    });

    testWidgets('a Khmer label never throws, whatever date names are loaded',
        (WidgetTester t) async {
      late String label;
      await t.pumpWidget(localizedHost(
        Builder(builder: (_) {
          label = historyDayLabel(
            DateTime(2026, 9, 28),
            now: DateTime(2026, 10, 1),
            locale: 'km',
          );
          return const SizedBox();
        }),
        locale: const Locale('km'),
      ));
      await t.pumpAndSettle();

      expect(label, isNotEmpty);
      expect(label, contains('28'));
    });

    testWidgets('labels read Today, Yesterday, then the date',
        (WidgetTester t) async {
      late List<String> labels;
      final DateTime now = DateTime(2026, 10, 1, 9, 17);
      await t.pumpWidget(localizedHost(Builder(builder: (_) {
        labels = <String>[
          historyDayLabel(DateTime(2026, 10, 1), now: now, locale: 'en'),
          historyDayLabel(DateTime(2026, 9, 30), now: now, locale: 'en'),
          historyDayLabel(DateTime(2026, 9, 28), now: now, locale: 'en'),
          historyDayLabel(DateTime(2025, 12, 31), now: now, locale: 'en'),
        ];
        return const SizedBox();
      })));
      await t.pumpAndSettle();

      expect(labels, <String>[
        'Today',
        'Yesterday',
        'Mon 28 Sep',
        'Wed 31 Dec 2025',
      ]);
    });
  });

  testWidgets('HistoryCardSkeleton renders', (WidgetTester t) async {
    await t.pumpWidget(localizedHost(const HistoryCardSkeleton()));
    await t.pump();
    expect(find.byType(TSkeleton), findsWidgets);
  });

  group('trip detail (DD-42)', () {
    MapHistoryDetailArgs args({String? phone = '098765432'}) =>
        MapHistoryDetailArgs(
          typeVehicleId: 2,
          cost: '7,600',
          distand: '3.5 km',
          duration: '14:00',
          latStart: 11.55,
          lngStart: 104.92,
          latEnd: 11.57,
          lngEnd: 104.93,
          invoiceId: '7712',
          passengerName: 'Mey Lin',
          passengerPhone: phone,
          startAddress: 'St. 271, Phnom Penh',
          endAddress: 'Sisowath Quay',
          paymentMethod: 'Cash',
          tripTime: DateTime(2026, 9, 12, 9, 30),
          endedAt: DateTime(2026, 9, 12, 9, 44),
        );

    Future<void> pumpBody(
      WidgetTester t, {
      required bool canCall,
      VoidCallback? onCall,
      VoidCallback? onSupport,
    }) async {
      await t.pumpWidget(
        localizedHost(
          TripDetailBody(
            trip: args(),
            canCallPassenger: canCall,
            onCallPassenger: onCall ?? () {},
            onContactSupport: onSupport ?? () {},
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('shows the whole trip: amount, figures, route, passenger',
        (WidgetTester t) async {
      await pumpBody(t, canCall: true);

      expect(find.text('៛7,600'), findsOneWidget);
      expect(find.text('Total price'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      // The payment screen's "collect" wording does not belong here.
      expect(find.text('Collect in cash'), findsNothing);
      expect(find.text('3.5 km'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('12/09 09:30'), findsOneWidget);
      expect(find.text('St. 271'), findsOneWidget);
      expect(find.text('Sisowath Quay'), findsOneWidget);
      expect(find.text('Mey Lin'), findsOneWidget);
      expect(find.text('#7712'), findsOneWidget);
    });

    testWidgets('within the window: call the passenger, or support',
        (WidgetTester t) async {
      int calls = 0;
      int support = 0;
      await pumpBody(
        t,
        canCall: true,
        onCall: () => calls++,
        onSupport: () => support++,
      );

      await t.ensureVisible(find.text('Call passenger'));
      await t.tap(find.text('Call passenger'));
      await t.tap(find.text('Contact support'));
      expect(calls, 1);
      expect(support, 1);
      // Button only: the number is never printed.
      expect(find.textContaining('098765432'), findsNothing);
      expect(
        find.text('You can call the passenger for 24 hours after the trip.'),
        findsOneWidget,
      );
    });

    testWidgets('after the window: support only, with the invoice to quote',
        (WidgetTester t) async {
      await pumpBody(t, canCall: false);

      expect(find.text('Call passenger'), findsNothing);
      expect(find.text('Contact support'), findsOneWidget);
      expect(
        find.text(
          'To reach the passenger now, contact support and give them '
          'invoice #7712.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('098765432'), findsNothing);
    });

    test('the call window is 24 hours from the end of the trip', () {
      final DateTime ended = DateTime(2026, 9, 12, 9, 44);
      bool at(Duration after, {String? phone = '098765432'}) =>
          canCallPassenger(
            endedAt: ended,
            phone: phone,
            now: ended.add(after),
          );

      expect(at(const Duration(minutes: 5)), isTrue);
      expect(at(const Duration(hours: 23, minutes: 59)), isTrue);
      expect(at(const Duration(hours: 24)), isFalse);
      expect(at(const Duration(days: 3)), isFalse);
      // No number, or no known end time: no call.
      expect(at(const Duration(minutes: 5), phone: ''), isFalse);
      expect(at(const Duration(minutes: 5), phone: null), isFalse);
      expect(
        canCallPassenger(endedAt: null, phone: '098765432', now: ended),
        isFalse,
      );
    });

    test('the logic follows the clock, and refuses a call once closed', () {
      DateTime now = DateTime(2026, 9, 12, 10);
      final HistoryDetailLogic logic =
          HistoryDetailLogic(args(), now: () => now);
      expect(logic.canCallPassenger, isTrue);

      now = DateTime(2026, 9, 13, 10);
      expect(logic.canCallPassenger, isFalse);
      // A screen left open past the window: the call is a no-op.
      expect(logic.callPassenger(), completes);
    });

    test('the trip ends at end_time, else the payment, else its start', () {
      final DataHistory item = _trip(status: 4, statusName: 'completed')
        ..endTime = '2026-09-12 09:44:00';
      expect(historyEndedAt(item), DateTime(2026, 9, 12, 9, 44));

      item.endTime = null;
      expect(historyEndedAt(item), DateTime(2026, 9, 12, 9, 30));
    });
  });
}
