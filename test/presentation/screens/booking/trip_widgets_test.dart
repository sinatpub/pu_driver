import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/features/trip/domain/trip_state_machine.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/passenger_row.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/show_distand_and_price_widget.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/trip_action_bar.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/trip_header.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/trip_timeline.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import '../../../helpers/localized_host.dart';

/// UX-redesign C3 and C4 — the trip screen's presentational pieces.
///
/// The sheet itself and `booking/view.dart` are not pumped: they reach for
/// GetX controllers, `.tr()` and a `GoogleMap` platform view. Their behaviour
/// is verified on a device against the G0 socket-emit oracle.
///
/// The test that matters most is the C3 one: an in-flight action must
/// not let Cancel through.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(khmer: false),
    home: Scaffold(body: child),
  );
}

/// [TripMeterStrip] is the one presentational piece that calls `.tr()` in its
/// build, so it gets a real `EasyLocalization` wrapper instead of the bare
/// theme the other groups use.
const List<String> _labels = <String>['Accept', 'Arrive', 'Start', 'Drop'];

void main() {
  group('TripHeader', () {
    testWidgets('names the stage and the booking', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TripHeader(
            stage: TripStage.requestReceived,
            title: 'New Ride Request',
            bookingCode: 8821,
          ),
        ),
      );

      expect(find.text('New Ride Request'), findsOneWidget);
      expect(find.text('#8821'), findsOneWidget);
    });
  });

  group('TripTimeline', () {
    testWidgets('a fresh request has nothing done', (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TripTimeline(processType: 1, labels: _labels)),
      );

      expect(
        const TripTimeline(processType: 1, labels: _labels).doneCount,
        0,
      );
      // Nothing is finished, so every step still shows its number.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('progress matches the stage', (WidgetTester t) async {
      // 2 = en route, 3 = at pickup, 4 = in progress, 6 = completing.
      expect(const TripTimeline(processType: 2, labels: _labels).doneCount, 1);
      expect(const TripTimeline(processType: 3, labels: _labels).doneCount, 2);
      expect(const TripTimeline(processType: 4, labels: _labels).doneCount, 3);
      expect(const TripTimeline(processType: 6, labels: _labels).doneCount, 4);

      await t.pumpWidget(
        _host(const TripTimeline(processType: 4, labels: _labels)),
      );
      // Three steps done, so only the fourth still shows a number.
      expect(find.text('4'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });
  });

  group('PassengerRow', () {
    testWidgets('shows who to collect and offers a call',
        (WidgetTester t) async {
      int calls = 0;
      await t.pumpWidget(
        _host(
          PassengerRow(
            name: 'Mey Lin',
            phone: '012345678',
            phoneLabel: 'Phone Number 012345678',
            callSemanticLabel: 'Phone Number',
            onCall: () => calls++,
          ),
        ),
      );

      expect(find.text('Mey Lin'), findsOneWidget);
      expect(find.text('Phone Number 012345678'), findsOneWidget);
      // No rating: the ride-request payload carries none (DD-15).
      expect(find.textContaining('4.8'), findsNothing);

      await t.tap(find.byType(TIconButton));
      expect(calls, 1);
    });
  });

  group('TripActionBar', () {
    testWidgets('a request offers Accept and, below it, Cancel',
        (WidgetTester t) async {
      int accepted = 0;
      int cancelled = 0;
      await t.pumpWidget(
        _host(
          TripActionBar(
            primaryLabel: 'Accept',
            onPrimary: () => accepted++,
            isLoading: false,
            showCancel: true,
            cancelLabel: 'Cancel',
            onCancel: () => cancelled++,
          ),
        ),
      );

      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel sits below Accept, not beside it — DD-11.
      expect(
        t.getCenter(find.text('Cancel')).dy,
        greaterThan(t.getCenter(find.text('Accept')).dy),
      );

      await t.tap(find.text('Accept'));
      expect(accepted, 1);
      await t.tap(find.text('Cancel'));
      expect(cancelled, 1);
    });

    testWidgets('later stages carry no Cancel', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          TripActionBar(
            primaryLabel: "I've arrived",
            onPrimary: () {},
            isLoading: false,
          ),
        ),
      );

      expect(find.text("I've arrived"), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('an in-flight action blocks BOTH buttons',
        (WidgetTester t) async {
      int accepted = 0;
      int cancelled = 0;
      await t.pumpWidget(
        _host(
          TripActionBar(
            primaryLabel: 'Accept',
            onPrimary: () => accepted++,
            isLoading: true,
            showCancel: true,
            cancelLabel: 'Cancel',
            onCancel: () => cancelled++,
          ),
        ),
      );

      await t.tap(find.text('Accept'));
      await t.tap(find.text('Cancel'));

      expect(accepted, 0);
      // The one that matters: Cancel emits `driverCancelDrive` before the
      // controller's guard runs, so a tap here during an in-flight Accept
      // would tell the passenger the trip was cancelled while the REST call
      // never happened. Until C3 the full-screen overlay prevented the tap.
      expect(cancelled, 0, reason: 'Cancel must be inert while loading');
    });

    testWidgets('Start ride uses the success fill (DD-12)',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          TripActionBar(
            primaryLabel: 'Start ride',
            onPrimary: () {},
            isLoading: false,
            primaryVariant: TButtonVariant.success,
          ),
        ),
      );

      final AnimatedContainer container = t.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(TButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final BoxDecoration decoration = container.decoration! as BoxDecoration;
      // Success is a solid fill; the primary variant would carry a gradient
      // instead (`t_button.dart::_styleFor`).
      expect(decoration.color, TaarraaColors.light.success);
      expect(decoration.gradient, isNull);
    });
  });

  group('TripMeterStrip', () {
    testWidgets('shows time, distance and an estimated fare (DD-14)',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          const TripMeterStrip(
            duration: '00:42',
            distance: '3.2 km',
            fare: '7,600',
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('00:42'), findsOneWidget);
      expect(find.text('3.2 km'), findsOneWidget);
      // The fare is an estimate: "≈" prefix, never the "Total price" label.
      expect(find.text('≈ ៛7,600'), findsOneWidget);
      expect(find.text('Est. fare'), findsOneWidget);
      expect(find.text('Total price'), findsNothing);
      // The estimate note travels with the strip.
      expect(find.text('DURATION'), findsNothing);
      expect(
        find.text('≈ estimated — final fare is confirmed after drop-off'),
        findsOneWidget,
      );
    });

    testWidgets('labels the estimate with the info icon',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          const TripMeterStrip(
            duration: '00:00',
            distance: '0.0 km',
            fare: '4,000',
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.byType(TIcon), findsOneWidget);
    });
  });
}
