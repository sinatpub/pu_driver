import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/theme/app_theme.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/wallet/wallet_presentation.dart';
import 'package:tara_driver_application/presentation/screens/wallet/widgets/wallet_widgets.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign S2 — the wallet's balance card and transaction row
/// (`03 S11`, `DD-21`, `DD-04`).
///
/// `wallet/view.dart` is not pumped: it reaches for a GetX controller and a
/// repository. Loaded / empty / error states, every filter chip and a USD
/// balance are verified on a device (roadmap S2 Verification). The money
/// rules themselves are covered by `test/presentation/screens/wallet/`.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(khmer: false),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('WalletBalanceCard', () {
    testWidgets('shows the label and a USD amount with its decimals',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          WalletBalanceCard(
            label: 'Wallet',
            amount: formatWalletAmountWithSymbol('125.50', 'USD'),
            tone: WalletBalanceTone.wallet,
          ),
        ),
      );

      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('125.50 \$'), findsOneWidget);
      // DD-21: the existing label only — no invented sub-label.
      final Iterable<Text> texts = t.widgetList<Text>(
        find.descendant(
          of: find.byType(WalletBalanceCard),
          matching: find.byType(Text),
        ),
      );
      expect(texts.length, 2);
    });

    testWidgets('amount is neutral and tabular in both tones',
        (WidgetTester t) async {
      for (final WalletBalanceTone tone in WalletBalanceTone.values) {
        await t.pumpWidget(
          _host(
            WalletBalanceCard(label: 'L', amount: '7,600 ៛', tone: tone),
          ),
        );
        final BuildContext context = t.element(find.byType(WalletBalanceCard));
        final Text amount = t.widget<Text>(find.text('7,600 ៛'));
        expect(amount.style!.color, context.colors.textPrimary);
        expect(
          amount.style!.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });
  });

  group('TransactionRow', () {
    testWidgets('joins date and status into one caption',
        (WidgetTester t) async {
      await t.pumpWidget(
        _host(
          const TransactionRow(
            typeName: 'Commission',
            amount: '1,200 ៛',
            date: '12 Sep 2026 · 09:30',
            status: 'Success',
          ),
        ),
      );

      expect(find.text('Commission'), findsOneWidget);
      expect(find.text('12 Sep 2026 · 09:30 · Success'), findsOneWidget);
      expect(find.text('1,200 ៛'), findsOneWidget);
    });

    testWidgets('never colours or signs the amount', (WidgetTester t) async {
      await t.pumpWidget(
        _host(const TransactionRow(typeName: null, amount: '-3.00 \$')),
      );
      final BuildContext context = t.element(find.byType(TransactionRow));

      expect(find.text('—'), findsOneWidget); // null type name
      final Text amount = t.widget<Text>(find.text('-3.00 \$'));
      expect(amount.style!.color, context.colors.textPrimary);
      final TIcon icon = t.widget<TIcon>(find.byType(TIcon));
      expect(icon.color, context.colors.textSecondary);
    });
  });

  testWidgets('WalletSkeleton renders', (WidgetTester t) async {
    await t.pumpWidget(
        _host(const SingleChildScrollView(child: WalletSkeleton())));
    await t.pump();
    expect(find.byType(TSkeleton), findsWidgets);
  });
}
