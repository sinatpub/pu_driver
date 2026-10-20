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

    testWidgets('a screen reader hears the card as one stop (DD-61)',
        (WidgetTester t) async {
      final SemanticsHandle handle = t.ensureSemantics();
      await t.pumpWidget(
        _host(
          const WalletBalanceCard(
            label: 'Balance',
            amount: '៛85,400',
            note: 'Platform commission: 10% of each trip',
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          RegExp('Balance.*៛85,400.*Platform commission', dotAll: true),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('WalletBalanceCard owing (DD-62)', () {
    testWidgets('not owing: neutral, and the debt copy and action stay hidden',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          WalletBalanceCard(
            label: 'Balance',
            amount: '៛85,400',
            message: 'Unpaid commission from cash trips.',
            hint: 'Contact support to pay it.',
            actionLabel: 'Contact support',
            onAction: () {},
          ),
        ),
      );

      expect(t.widget<TCard>(find.byType(TCard)).variant, TCardVariant.flat);
      expect(find.text('Unpaid commission from cash trips.'), findsNothing);
      expect(find.text('Contact support to pay it.'), findsNothing);
      expect(find.byType(TButton), findsNothing);
      expect(t.widget<TIcon>(find.byType(TIcon)).asset, DsIcons.wallet);
    });

    testWidgets('owing: the net balance in amber on the tint, never red',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const WalletBalanceCard(
            label: 'Balance',
            amount: '−៛52',
            owing: true,
            message: 'Unpaid commission from cash trips.',
          ),
        ),
      );
      final BuildContext context = t.element(find.byType(WalletBalanceCard));

      final TCard card = t.widget<TCard>(find.byType(TCard));
      expect(card.variant, TCardVariant.tinted);
      expect(card.tintFill, context.colors.warningTint);
      final Text amount = t.widget<Text>(find.text('−៛52'));
      expect(amount.style!.color, context.colors.warning);
      expect(amount.style!.color, isNot(context.colors.danger));
      expect(
        t
            .widget<Text>(find.text('Unpaid commission from cash trips.'))
            .style!
            .color,
        context.colors.warning,
      );
      // A glyph as well as the colour (`02 §1.4`).
      expect(t.widget<TIcon>(find.byType(TIcon)).asset, DsIcons.warn);
      // No action passed: no button.
      expect(find.byType(TButton), findsNothing);
    });

    testWidgets('owing: the hint and the action (DD-48, DD-61)',
        (WidgetTester t) async {
      int taps = 0;
      await t.pumpWidget(
        _host(
          WalletBalanceCard(
            label: 'Balance',
            amount: '−៛5,000',
            owing: true,
            message: 'Unpaid commission from cash trips.',
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

    testWidgets('owing: the action stays its own screen-reader stop',
        (WidgetTester t) async {
      final SemanticsHandle handle = t.ensureSemantics();
      await t.pumpWidget(
        _host(
          WalletBalanceCard(
            label: 'Balance',
            amount: '−៛52',
            owing: true,
            message: 'Unpaid commission from cash trips.',
            hint: 'Contact support to pay it.',
            actionLabel: 'Contact support',
            onAction: () {},
          ),
        ),
      );

      final Finder text = find.bySemanticsLabel(RegExp(
        'Balance.*−៛52.*Unpaid commission.*Contact support to pay it',
        dotAll: true,
      ));
      expect(text, findsOneWidget);
      // The texts are one stop that is not a button; the button is another.
      expect(t.getSemantics(text), isSemantics(isButton: false));
      expect(
        t.getSemantics(find.byType(TButton)),
        isSemantics(isButton: true, hasTapAction: true),
      );
      handle.dispose();
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

    testWidgets('no badge without a status', (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TransactionRow(title: 'Top up', amount: '៛500', time: '09:14'),
        ),
      );
      expect(find.text('09:14'), findsOneWidget);
      expect(find.byType(TBadge), findsNothing);
    });

    testWidgets('pending is a badge with a glyph, and the amount is muted',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TransactionRow(
            title: 'Top up',
            kind: WalletTxKind.topUp,
            direction: WalletTxDirection.moneyIn,
            amount: '+៛500',
            time: '09:14',
            status: 'Pending',
            statusKind: WalletTxStatus.pending,
          ),
        ),
      );
      final BuildContext context = t.element(find.byType(TransactionRow));

      expect(find.text('09:14'), findsOneWidget);
      final TBadge badge = t.widget<TBadge>(find.byType(TBadge));
      expect(badge.label, 'Pending');
      expect(badge.tone, TBadgeTone.warning);
      // Never colour alone (`02 §1.4`).
      expect(badge.icon, DsIcons.clock);
      // Not settled: not the success green, even though it is money in.
      expect(
        t.widget<Text>(find.text('+៛500')).style!.color,
        context.colors.textSecondary,
      );
    });

    testWidgets(
        'a failed status is a danger badge; the amount keeps its colour',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TransactionRow(
            title: 'Commission',
            direction: WalletTxDirection.moneyOut,
            amount: '−៛1,300',
            status: 'Failed',
            statusKind: WalletTxStatus.failed,
          ),
        ),
      );
      final BuildContext context = t.element(find.byType(TransactionRow));

      final TBadge badge = t.widget<TBadge>(find.byType(TBadge));
      expect(badge.tone, TBadgeTone.danger);
      expect(badge.icon, DsIcons.warn);
      expect(
        t.widget<Text>(find.text('−៛1,300')).style!.color,
        context.colors.textPrimary,
      );
    });

    testWidgets('a screen reader hears the row as one sentence (DD-61)',
        (WidgetTester t) async {
      final SemanticsHandle handle = t.ensureSemantics();
      await t.pumpWidget(
        _host(
          const TransactionRow(
            title: 'Payment',
            kind: WalletTxKind.payment,
            direction: WalletTxDirection.moneyOut,
            amount: '−៛5',
            time: '20:15',
            status: 'Pending',
            statusKind: WalletTxStatus.pending,
            semanticLabel: 'Payment, Money out ៛5, 20:15, Pending',
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Payment, Money out ៛5, 20:15, Pending'),
        findsOneWidget,
      );
      // The row's own texts are not separate stops.
      expect(find.bySemanticsLabel('−៛5'), findsNothing);
      handle.dispose();
    });

    testWidgets('the row title and amount use the type scale',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TransactionRow(title: 'Top up', amount: '៛500')),
      );
      final BuildContext context = t.element(find.byType(TransactionRow));

      for (final String text in <String>['Top up', '៛500']) {
        final TextStyle style = t.widget<Text>(find.text(text)).style!;
        expect(style.fontSize, context.texts.bodySecondaryStrong.fontSize);
        expect(style.fontWeight, context.texts.bodySecondaryStrong.fontWeight);
      }
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
