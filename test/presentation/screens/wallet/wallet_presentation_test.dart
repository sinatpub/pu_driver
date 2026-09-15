import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/presentation/screens/wallet/data/models/wallet_model.dart';
import 'package:tara_driver_application/presentation/screens/wallet/wallet_presentation.dart';

/// N-01 (docs/12) — the wallet is the driver's money, which .agent/RULES.md
/// puts in mandatory-test territory.
void main() {
  Transaction txn({String? type, dynamic amount, dynamic createdAt}) =>
      Transaction(typeName: type, amount: amount, createdAt: createdAt);

  group('formatWalletAmount', () {
    test('USD keeps its cents', () {
      // The screen used the riel formatter for every currency, so a USD
      // balance of 125.50 rendered as "126" and 0.99 rendered as "1" —
      // the driver's own balance, rounded up.
      expect(formatWalletAmount(125.50, 'USD'), '125.50');
      expect(formatWalletAmount(0.99, 'USD'), '0.99');
      expect(formatWalletAmount('125.5', 'USD'), '125.50');
    });

    test('riel is written in whole units', () {
      expect(formatWalletAmount(125.5, 'KHR'), '126');
      expect(formatWalletAmount(20000, 'KHR'), '20,000');
    });

    test('thousands are grouped in both currencies', () {
      expect(formatWalletAmount(1200.5, 'USD'), '1,200.50');
      expect(formatWalletAmount(1200.5, 'KHR'), '1,201');
    });

    test('an unreported amount is an em dash, not zero', () {
      expect(formatWalletAmount(null, 'USD'), '—');
      expect(formatWalletAmount('', 'USD'), '—');
      expect(formatWalletAmount('nonsense', 'USD'), '—');
    });

    test('a negative balance is shown, not hidden', () {
      // `debted` is a real field; a driver in debt must see it.
      expect(formatWalletAmount(-40.25, 'USD'), '-40.25');
    });

    test('an unknown currency falls back to cents rather than rounding', () {
      expect(formatWalletAmount(1.005, null), '1.00');
      expect(formatWalletAmount(1.5, 'VND'), '1.50');
    });
  });

  group('currencySymbol', () {
    test('riel and dollar', () {
      expect(currencySymbol('KHR'), '៛');
      expect(currencySymbol('USD'), '\$');
    });

    test('an unknown currency falls back to the dollar sign, as before', () {
      expect(currencySymbol(null), '\$');
      expect(currencySymbol('VND'), '\$');
    });
  });

  group('sortedTransactions', () {
    test('newest first', () {
      final list = sortedTransactions([
        txn(type: 'old', createdAt: '2026-01-01T00:00:00Z'),
        txn(type: 'new', createdAt: '2026-09-01T00:00:00Z'),
        txn(type: 'mid', createdAt: '2026-05-01T00:00:00Z'),
      ]);

      expect(list.map((t) => t.typeName), ['new', 'mid', 'old']);
    });

    test('an unparseable or missing date sorts last rather than throwing', () {
      final list = sortedTransactions([
        txn(type: 'broken', createdAt: 'not-a-date'),
        txn(type: 'dated', createdAt: '2026-01-01T00:00:00Z'),
        txn(type: 'missing', createdAt: null),
      ]);

      expect(list.first.typeName, 'dated');
      expect(list.map((t) => t.typeName).skip(1),
          containsAll(['broken', 'missing']));
    });

    test('equal timestamps keep the order the backend sent', () {
      final list = sortedTransactions([
        txn(type: 'first', createdAt: '2026-09-01T00:00:00Z'),
        txn(type: 'second', createdAt: '2026-09-01T00:00:00Z'),
      ]);

      expect(list.map((t) => t.typeName), ['first', 'second']);
    });

    test('null and empty are handled', () {
      expect(sortedTransactions(null), isEmpty);
      expect(sortedTransactions([]), isEmpty);
    });

    test('the input list is not mutated', () {
      final original = [
        txn(type: 'a', createdAt: '2026-01-01T00:00:00Z'),
        txn(type: 'b', createdAt: '2026-09-01T00:00:00Z'),
      ];
      sortedTransactions(original);
      expect(original.map((t) => t.typeName), ['a', 'b']);
    });
  });

  group('transactionTypeNames', () {
    test('distinct names, sorted, for the filter row', () {
      final names = transactionTypeNames([
        txn(type: 'Top up'),
        txn(type: 'Commission'),
        txn(type: 'Top up'),
      ]);

      expect(names, ['Commission', 'Top up']);
    });

    test('blank and missing names are not offered as filters', () {
      expect(
        transactionTypeNames(
            [txn(type: null), txn(type: '  '), txn(type: 'Top up')]),
        ['Top up'],
      );
    });

    test('an empty wallet offers no filters', () {
      expect(transactionTypeNames(null), isEmpty);
      expect(transactionTypeNames([]), isEmpty);
    });
  });

  group('filterTransactionsByType', () {
    final all = [
      txn(type: 'Top up', amount: 10),
      txn(type: 'Commission', amount: 2),
      txn(type: 'Top up', amount: 30),
    ];

    test('null means all', () {
      expect(filterTransactionsByType(all, null), hasLength(3));
    });

    test('a selected type keeps only its own', () {
      final filtered = filterTransactionsByType(all, 'Top up');
      expect(filtered, hasLength(2));
      expect(filtered.map((t) => t.amountValue), [10, 30]);
    });

    test('a type nothing matches yields an empty list, not everything', () {
      expect(filterTransactionsByType(all, 'Withdraw'), isEmpty);
    });
  });

  group('formatTransactionDate', () {
    test('a parseable timestamp is rendered', () {
      expect(formatTransactionDate('2026-09-01T10:30:00Z'), isNotNull);
      expect(formatTransactionDate('2026-09-01T10:30:00Z'), contains('2026'));
    });

    test('an unusable timestamp yields null so the row can omit it', () {
      expect(formatTransactionDate(null), isNull);
      expect(formatTransactionDate('not-a-date'), isNull);
      expect(formatTransactionDate(42), isNull);
    });
  });
}
