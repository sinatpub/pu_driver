import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/theme/app_theme.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/wallet_presentation.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/widgets/wallet_widgets.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

/// The wallet's pieces after DD-43 (`03 S11`, `DD-04`).
///
/// `wallet/view.dart` is not pumped: it reaches for a GetX controller and a
/// repository. The money rules themselves are covered by
/// `wallet_presentation_test.dart`.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(khmer: false),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('WalletBalanceCard', () {
    testWidgets('shows the balance and the commission note',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const WalletBalanceCard(
            label: 'Balance',
            amount: '៛85,400',
            note: 'Platform commission: 10% of each trip',
          ),
        ),
      );
      final BuildContext context = t.element(find.byType(WalletBalanceCard));

      expect(find.text('Balance'), findsOneWidget);
      expect(
          find.text('Platform commission: 10% of each trip'), findsOneWidget);
      final Text amount = t.widget<Text>(find.text('៛85,400'));
      // Neutral money, tabular (DD-04).
      expect(amount.style!.color, context.colors.textPrimary);
      expect(
        amount.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets('no note when the rate is not reported',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(const WalletBalanceCard(label: 'Balance', amount: '៛0')),
      );

      final Iterable<Text> texts = t.widgetList<Text>(
        find.descendant(
          of: find.byType(WalletBalanceCard),
          matching: find.byType(Text),
        ),
      );
      expect(texts.length, 2);
    });
  });

  group('WalletDebtCard', () {
    testWidgets('says how much is owed, in the warning colour, never red',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const WalletDebtCard(
            title: 'You owe ៛5,000',
            message: 'Unpaid commission from cash trips. Top up to clear it.',
          ),
        ),
      );
      final BuildContext context = t.element(find.byType(WalletDebtCard));

      final Text title = t.widget<Text>(find.text('You owe ៛5,000'));
      expect(title.style!.color, context.colors.warning);
      expect(title.style!.color, isNot(context.colors.danger));
      // No rewards to move: no hint, no button.
      expect(find.byType(TButton), findsNothing);
    });

    testWidgets('with rewards to move, offers the transfer (DD-48)',
        (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(
        _host(
          WalletDebtCard(
            title: 'You owe ៛5,000',
            message: 'Unpaid commission from cash trips. Top up to clear it.',
            hint: 'You have ៛5,160 in invite rewards. Transfer it to pay this.',
            actionLabel: 'Transfer to balance',
            onAction: () => taps++,
          ),
        ),
      );

      expect(
        find.text(
            'You have ៛5,160 in invite rewards. Transfer it to pay this.'),
        findsOneWidget,
      );
      await t.tap(find.text('Transfer to balance'));
      expect(taps, 1);
    });
  });

  group('TransactionRow', () {
    testWidgets('money in is green with its sign', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TransactionRow(
            title: 'Top up',
            kind: WalletTxKind.topUp,
            direction: WalletTxDirection.moneyIn,
            amount: '+៛100,000',
            time: '09:14',
          ),
        ),
      );
      final BuildContext context = t.element(find.byType(TransactionRow));

      expect(find.text('Top up'), findsOneWidget);
      expect(find.text('09:14'), findsOneWidget);
      expect(
        t.widget<Text>(find.text('+៛100,000')).style!.color,
        context.colors.success,
      );
    });

    testWidgets('money out is neutral, not red', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TransactionRow(
            title: 'Commission',
            kind: WalletTxKind.commission,
            direction: WalletTxDirection.moneyOut,
            amount: '−៛1,300',
            time: '09:14',
          ),
        ),
      );
      final BuildContext context = t.element(find.byType(TransactionRow));

      final Text amount = t.widget<Text>(find.text('−៛1,300'));
      expect(amount.style!.color, context.colors.textPrimary);
      expect(t.widget<TIcon>(find.byType(TIcon)).asset, DsIcons.doc);
    });

    testWidgets('a status is joined to the time only when one is passed',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TransactionRow(
            title: 'Top up',
            amount: '៛500',
            time: '09:14',
            status: 'Pending',
          ),
        ),
      );
      expect(find.text('09:14 · Pending'), findsOneWidget);
    });

    testWidgets('an unknown kind is unsigned and neutral; no title is a dash',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TransactionRow(title: null, amount: '៛500')),
      );
      final BuildContext context = t.element(find.byType(TransactionRow));

      expect(find.text('—'), findsOneWidget);
      expect(
        t.widget<Text>(find.text('៛500')).style!.color,
        context.colors.textPrimary,
      );
      expect(
        t.widget<TIcon>(find.byType(TIcon)).color,
        context.colors.textSecondary,
      );
    });
  });

  testWidgets('WalletSkeleton renders', (WidgetTester t) async {
    await t.pumpWidget(
        _host(const SingleChildScrollView(child: WalletSkeleton())));
    await t.pump();
    expect(find.byType(TSkeleton), findsWidgets);
  });
}
