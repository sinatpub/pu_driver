import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/helper/address_parts.dart';
import 'package:pu_taxi_driver/core/theme/app_theme.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/domain/trip_state_machine.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/widgets/passenger_row.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/widgets/show_distand_and_price_widget.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/widgets/trip_action_bar.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/widgets/trip_header.dart';
import 'package:pu_taxi_driver/presentation/screens/booking/widgets/trip_timeline.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

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

  group('TripProgressBar at pickup (DD-37)', () {
    testWidgets('two steps done, the third current', (WidgetTester t) async {
      const Color current = Color(0xFF1A579E);
      await t.pumpWidget(
        localizedHost(
          const TripProgressBar(processType: 3, currentColor: current),
        ),
      );
      await t.pumpAndSettle();

      expect(find.bySemanticsLabel('Step 3 of 4'), findsOneWidget);
    });
  });

  group('TripProgressBar (DD-36)', () {
    Color segment(WidgetTester t, int i) => (t
            .widgetList<Container>(find.descendant(
              of: find.byType(TripProgressBar),
              matching: find.byType(Container),
            ))
            .elementAt(i)
            .decoration! as BoxDecoration)
        .color!;

    testWidgets('going to pickup: one step done, the second current',
        (WidgetTester t) async {
      const Color current = Color(0xFF1A579E);
      await t.pumpWidget(
        localizedHost(
          const TripProgressBar(processType: 2, currentColor: current),
        ),
      );
      await t.pumpAndSettle();

      expect(segment(t, 0), TaarraaColors.light.success);
      expect(segment(t, 1), current);
      expect(segment(t, 2), TaarraaColors.light.borderDivider);
      expect(segment(t, 3), TaarraaColors.light.borderDivider);
      expect(find.bySemanticsLabel('Step 2 of 4'), findsOneWidget);
    });
  });

  group('PassengerRow', () {
    testWidgets('dense: a 32 px avatar and the call button, no phone line',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          PassengerRow(
            name: 'Mey Lin',
            phone: '012345678',
            callSemanticLabel: 'Phone Number',
            onCall: () {},
            dense: true,
          ),
        ),
      );

      expect(t.widget<TAvatar>(find.byType(TAvatar)).size, 32);
      expect(find.byType(TIconButton), findsOneWidget);
      expect(find.textContaining('012345678'), findsNothing);
    });

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

  group('TripActionBar on a request (DD-35)', () {
    Widget timedBar({required VoidCallback onAccept, bool isLoading = false}) =>
        localizedHost(
          TripActionBar(
            primaryLabel: 'Accept',
            onPrimary: onAccept,
            isLoading: isLoading,
            showCancel: true,
            cancelLabel: 'Decline',
            onCancel: () {},
            countdownSeconds: 30,
            countdownExpiresToHome: false,
          ),
        );

    testWidgets('carries the decision timer inside Accept',
        (WidgetTester t) async {
      int accepted = 0;
      await t.pumpWidget(timedBar(onAccept: () => accepted++));
      // Short pumps, not pumpAndSettle: the timer animates until it expires.
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 300));

      // The ticker starts on the frame after mount, so 0.3 s has elapsed.
      expect(find.text('29s'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      expect(find.text('24s'), findsOneWidget);

      // The timer's overlay takes no taps; Accept still does.
      await t.tap(find.text('Accept'));
      expect(accepted, 1);
    });

    testWidgets('accepting swaps to a plain primary cleanly',
        (WidgetTester t) async {
      // One host for both stages, so the element tree is kept across the
      // swap — as the sheet keeps it when the stage changes under Obx.
      final ValueNotifier<bool> accepted = ValueNotifier<bool>(false);
      await t.pumpWidget(
        localizedHost(
          ValueListenableBuilder<bool>(
            valueListenable: accepted,
            builder: (BuildContext context, bool isAccepted, _) =>
                TripActionBar(
              primaryLabel: isAccepted ? "I've arrived" : 'Accept',
              onPrimary: () {},
              isLoading: false,
              showCancel: !isAccepted,
              cancelLabel: 'Decline',
              onCancel: () {},
              countdownSeconds: isAccepted ? null : 30,
              countdownExpiresToHome: false,
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Accept'), findsOneWidget);

      // The next stage: no timer, no Decline. Decline's element must not be
      // reused for the primary — the tween between the two throws.
      accepted.value = true;
      await t.pump();
      // Mid-tween: a reused element would interpolate here and throw.
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 300));

      expect(t.takeException(), isNull);
      expect(find.text("I've arrived"), findsOneWidget);
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('hides the seconds while Accept is in flight',
        (WidgetTester t) async {
      await t.pumpWidget(timedBar(onAccept: () {}, isLoading: true));
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 300));

      expect(find.textContaining(RegExp(r'^\d+s$')), findsNothing);
    });
  });

  group('Drop off is hold-to-confirm (DD-38)', () {
    Widget holdBar({required VoidCallback onDrop, bool isLoading = false}) =>
        localizedHost(
          TripActionBar(
            primaryLabel: 'Hold to drop off',
            onPrimary: onDrop,
            isLoading: isLoading,
            holdToConfirm: true,
          ),
        );

    testWidgets('a tap does nothing', (WidgetTester t) async {
      int dropped = 0;
      await t.pumpWidget(holdBar(onDrop: () => dropped++));
      await t.pump(const Duration(milliseconds: 300));

      await t.tap(find.text('Hold to drop off'));
      await t.pump(const Duration(seconds: 2));
      expect(dropped, 0);
    });

    testWidgets('letting go early does nothing', (WidgetTester t) async {
      int dropped = 0;
      await t.pumpWidget(holdBar(onDrop: () => dropped++));
      await t.pump(const Duration(milliseconds: 300));

      final TestGesture press =
          await t.startGesture(t.getCenter(find.text('Hold to drop off')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      await press.up();
      await t.pump(const Duration(seconds: 2));
      expect(dropped, 0);
    });

    testWidgets('holding for a second drops off, once', (WidgetTester t) async {
      int dropped = 0;
      await t.pumpWidget(holdBar(onDrop: () => dropped++));
      await t.pump(const Duration(milliseconds: 300));

      final TestGesture press =
          await t.startGesture(t.getCenter(find.text('Hold to drop off')));
      // The fill's ticker takes its start time from the first frame.
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 600));
      await press.up();
      await t.pump(const Duration(seconds: 1));
      expect(dropped, 1);
    });

    testWidgets('dragging off cancels', (WidgetTester t) async {
      int dropped = 0;
      await t.pumpWidget(holdBar(onDrop: () => dropped++));
      await t.pump(const Duration(milliseconds: 300));

      final TestGesture press =
          await t.startGesture(t.getCenter(find.text('Hold to drop off')));
      await t.pump(const Duration(milliseconds: 300));
      await press.moveBy(const Offset(0, -60));
      await t.pump(const Duration(seconds: 2));
      await press.up();
      expect(dropped, 0);
    });

    testWidgets('an in-flight action cannot be held', (WidgetTester t) async {
      int dropped = 0;
      await t.pumpWidget(holdBar(onDrop: () => dropped++, isLoading: true));
      await t.pump(const Duration(milliseconds: 300));

      final TestGesture press =
          await t.startGesture(t.getCenter(find.byType(TripActionBar)));
      await t.pump(const Duration(seconds: 2));
      await press.up();
      expect(dropped, 0);
    });

    testWidgets("a screen reader's activate confirms directly",
        (WidgetTester t) async {
      int dropped = 0;
      final SemanticsHandle semantics = t.ensureSemantics();
      await t.pumpWidget(holdBar(onDrop: () => dropped++));
      await t.pump(const Duration(milliseconds: 300));

      t.semantics.tap(find.semantics.byLabel('Hold to drop off'));
      expect(dropped, 1);
      semantics.dispose();
    });
  });

  group('TripProgressBar on a trip (DD-38)', () {
    testWidgets('the current step fills with the trip', (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          const SizedBox(
            width: 403,
            child: TripProgressBar(
              processType: 4,
              currentColor: Color(0xFF10CF7C),
              currentFraction: 0.5,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      final double segment = t
          .getSize(find
              .descendant(
                of: find.byType(TripProgressBar),
                matching: find.byType(Container),
              )
              .last)
          .width;
      final double fill = t
          .getSize(find.descendant(
            of: find.byType(TripProgressBar),
            matching: find.byType(ColoredBox),
          ))
          .width;
      expect(fill, closeTo(segment / 2, 0.5));
      expect(find.bySemanticsLabel('Step 4 of 4'), findsOneWidget);
    });
  });

  group('splitAddress', () {
    test('puts the place over the area', () {
      expect(
        splitAddress('Central Market, Daun Penh, Phnom Penh'),
        ('Central Market', 'Daun Penh, Phnom Penh'),
      );
    });

    test('keeps an address with no comma whole', () {
      expect(splitAddress('Independence Monument'),
          ('Independence Monument', null));
      expect(splitAddress(''), ('', null));
    });

    test('drops the postcode and the country', () {
      expect(
        splitAddress('Street 13, Daun Penh, Phnom Penh, 12203, Cambodia'),
        ('Street 13', 'Daun Penh, Phnom Penh'),
      );
      expect(
        splitAddress('ផ្លូវ ១៣, ដូនពេញ, ភ្នំពេញ, ១២២០៣, កម្ពុជា'),
        ('ផ្លូវ ១៣', 'ដូនពេញ, ភ្នំពេញ'),
      );
    });

    test('never leads with a plus code', () {
      expect(
        splitAddress('8M5X+2Q, Street 13, Daun Penh'),
        ('Street 13', 'Daun Penh'),
      );
      expect(
        splitAddress('8M5X+2Q Phnom Penh, Cambodia'),
        ('Phnom Penh', null),
      );
    });

    test('joins a bare house number to its street', () {
      expect(
        splitAddress('12, Street 13, Daun Penh, Phnom Penh'),
        ('12 Street 13', 'Daun Penh, Phnom Penh'),
      );
      expect(splitAddress('#12B, Street 13'), ('#12B Street 13', null));
    });

    test('drops the repeated name/street part', () {
      expect(
        splitAddress('Street 13, Street 13, Daun Penh'),
        ('Street 13', 'Daun Penh'),
      );
    });

    test('keeps the input when nothing is left', () {
      expect(splitAddress('Cambodia'), ('Cambodia', null));
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
