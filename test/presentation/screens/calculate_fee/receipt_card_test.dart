import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/passenger_row.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/widgets/receipt_card.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import '../../../helpers/localized_host.dart';

/// UX-redesign C6, reworked by DD-39 — the payment screen's pieces.
///
/// `calculate_fee/view.dart` itself is not pumped: it reaches for a GetX
/// controller. Its behaviour (both entry payloads, emit-after-REST order,
/// immediate navigation) is covered by `test/mock/mock_flow_test.dart` and
/// on a device.
///
/// The assertions that matter: the server amount is the one hero figure with
/// no estimate (`DD-18`), the wording follows the payment method, and there
/// is no call button.
Widget _hero(String? method) => localizedHost(
      PaymentHero(
        method: method,
        amount: '៛9,100',
        distance: '3.1 km',
        duration: '8:24',
        time: '17:36',
      ),
    );

void main() {
  group('PaymentKind', () {
    test('matches the method loosely', () {
      expect(PaymentKind.of('Cash'), PaymentKind.cash);
      expect(PaymentKind.of('CASH '), PaymentKind.cash);
      expect(PaymentKind.of('Wallet'), PaymentKind.wallet);
      expect(PaymentKind.of('ABA card'), PaymentKind.card);
      expect(PaymentKind.of('KHQR'), PaymentKind.unknown);
      expect(PaymentKind.of(null), PaymentKind.unknown);
    });
  });

  group('PaymentHero', () {
    testWidgets('cash: collect the server amount, no estimate',
        (WidgetTester t) async {
      await t.pumpWidget(_hero('Cash'));
      await t.pumpAndSettle();

      expect(find.text('Collect in cash'), findsOneWidget);
      expect(find.text('៛9,100'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Nothing to collect'), findsNothing);
      expect(find.textContaining('≈'), findsNothing);
      for (final String fact in <String>['3.1 km', '8:24', '17:36']) {
        expect(find.text(fact), findsOneWidget);
      }
    });

    testWidgets('wallet: paid in the app, nothing to collect',
        (WidgetTester t) async {
      await t.pumpWidget(_hero('Wallet'));
      await t.pumpAndSettle();

      expect(find.text('Paid by wallet'), findsOneWidget);
      expect(find.text('Nothing to collect'), findsOneWidget);
      expect(find.text('៛9,100'), findsOneWidget);
    });

    testWidgets('an unknown method keeps the old wording and its own text',
        (WidgetTester t) async {
      await t.pumpWidget(_hero('KHQR'));
      await t.pumpAndSettle();

      expect(find.text('Total to collect'), findsOneWidget);
      expect(find.text('KHQR'), findsOneWidget);
    });

    testWidgets('no method: no badge (DD-18)', (WidgetTester t) async {
      await t.pumpWidget(_hero(null));
      await t.pumpAndSettle();

      expect(find.byType(TBadge), findsNothing);
      expect(find.textContaining('Unknown Payment'), findsNothing);
    });
  });

  group('PaymentHero at 320 px and 1.3 text scale', () {
    for (final Locale locale in const <Locale>[Locale('en'), Locale('km')]) {
      testWidgets('no figure is cut short (${locale.languageCode})',
          (WidgetTester t) async {
        t.view.physicalSize = const Size(320, 800);
        t.view.devicePixelRatio = 1;
        // Through the platform, so the MaterialApp's own MediaQuery has it.
        t.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(
          localizedHost(
            Builder(builder: (BuildContext context) {
              expect(MediaQuery.textScalerOf(context).scale(10), 13);
              return const Padding(
                padding: EdgeInsets.all(16),
                child: PaymentHero(
                  method: 'Cash',
                  amount: '៛129,100',
                  distance: '13.1 km',
                  duration: '1:08:24',
                  time: '30/09 17:36',
                ),
              );
            }),
            locale: locale,
          ),
        );
        await t.pumpAndSettle();

        final List<String> cut = <String>[
          for (final RenderParagraph p
              in t.renderObjectList<RenderParagraph>(find.byType(RichText)))
            if (p.didExceedMaxLines) p.text.toPlainText(),
        ];
        expect(cut, isEmpty);
      });
    }
  });

  group('PaymentKind copy', () {
    testWidgets('hint and action follow the method', (WidgetTester t) async {
      late String cashHint, cashAction, appHint, appAction, oldAction;
      await t.pumpWidget(localizedHost(Builder(builder: (_) {
        cashHint = PaymentKind.cash.hint('៛9,100');
        cashAction = PaymentKind.cash.action;
        appHint = PaymentKind.card.hint('៛9,100');
        appAction = PaymentKind.wallet.action;
        oldAction = PaymentKind.unknown.action;
        return const SizedBox();
      })));
      await t.pumpAndSettle();

      expect(cashHint, 'Take ៛9,100 in cash, then confirm.');
      expect(cashAction, 'Cash received');
      expect(appHint, 'Paid in the app. Confirm to finish the trip.');
      expect(appAction, 'Finish trip');
      expect(oldAction, 'Payment done');
    });
  });

  group('PaymentRoute', () {
    testWidgets('splits the addresses and shows the passenger, no call',
        (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(
          const PaymentRoute(
            passengerName: 'Mey Lin',
            startAddress: 'Central Market, Daun Penh, Phnom Penh',
            endAddress: 'Sisowath Quay',
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Central Market'), findsOneWidget);
      expect(find.text('Daun Penh, Phnom Penh'), findsOneWidget);
      expect(find.text('Sisowath Quay'), findsOneWidget);
      expect(find.byType(PassengerRow), findsOneWidget);
      expect(find.byType(TIconButton), findsNothing);
    });
  });

  group('PaymentHeader', () {
    testWidgets('trip complete, with the booking', (WidgetTester t) async {
      await t.pumpWidget(
        localizedHost(const PaymentHeader(bookingCode: '990014')),
      );
      await t.pumpAndSettle();

      expect(find.text('Trip complete'), findsOneWidget);
      expect(find.text('#990014'), findsOneWidget);
    });
  });
}
