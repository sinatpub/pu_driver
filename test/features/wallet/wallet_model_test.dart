import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/features/wallet/data/models/wallet_model.dart';

/// N-01 (docs/12) — the wallet read path, which had no tests at all.
void main() {
  group('WalletModel.fromJson', () {
    test('a full payload parses', () {
      final model = WalletModel.fromJson({
        'status': true,
        'message': 'ok',
        'data': {
          'id': 3,
          'balance': '125.50',
          'debted': 0,
          'commission_fare': '12.05',
          'currency': 'USD',
          'transactions': [
            {
              'id': 1,
              'type': 10,
              'type_name': 'Top up',
              'amount': '50.00',
              'currency': 'USD',
              'status': 1,
              'status_name': 'Completed',
              'reference_id': 'TXN-1',
              'created_by': 'admin',
              'created_at': '2026-09-01T10:00:00Z',
            },
          ],
        },
      });

      expect(model.status, isTrue);
      expect(model.data?.balanceAmount, 125.5);
      expect(model.data?.commissionFareAmount, 12.05);
      expect(model.data?.transactions, hasLength(1));
      expect(model.data?.transactions?.single.amountValue, 50.0);
    });

    test('a wallet with no transactions parses instead of crashing', () {
      // This is every newly approved driver. The old fromJson called
      // .map on a null `transactions` and threw NoSuchMethodError, so the
      // wallet screen could not open at all.
      final model = WalletModel.fromJson({
        'data': {'id': 1, 'balance': 0, 'transactions': null},
      });

      expect(model.data?.transactions, isEmpty);
      expect(model.data?.balanceAmount, 0);
    });

    test('an absent transactions key is also survivable', () {
      final model = WalletModel.fromJson({
        'data': {'id': 1, 'balance': 0},
      });

      expect(model.data?.transactions, isEmpty);
    });

    test('an empty transactions list is empty, not null', () {
      final model = WalletModel.fromJson({
        'data': {'id': 1, 'balance': 0, 'transactions': []},
      });

      expect(model.data?.transactions, isEmpty);
    });

    test('a null data block is tolerated', () {
      final model = WalletModel.fromJson({'data': null, 'status': false});
      expect(model.data, isNull);
      expect(model.status, isFalse);
    });

    test('a balance sent as a number and as a string agree', () {
      final asNumber = WalletModel.fromJson({
        'data': {'balance': 125.5, 'transactions': []},
      });
      final asString = WalletModel.fromJson({
        'data': {'balance': '125.50', 'transactions': []},
      });

      expect(asNumber.data?.balanceAmount, asString.data?.balanceAmount);
    });

    test('an unreported balance is null, so the UI can say so', () {
      final model = WalletModel.fromJson({
        'data': {'transactions': []},
      });
      expect(model.data?.balanceAmount, isNull);
    });
  });

  group('WalletModel.toJson', () {
    test('a wallet with no transactions serialises instead of crashing', () {
      // toJson force-unwrapped the nullable list.
      final data = Data(id: 1, balance: 0);
      expect(() => data.toJson(), returnsNormally);
      expect(data.toJson()['transactions'], isEmpty);
    });

    test('a round trip preserves the transaction list', () {
      final original = WalletModel.fromJson({
        'data': {
          'balance': '10',
          'transactions': [
            {'id': 1, 'amount': '5', 'type_name': 'Top up'},
          ],
        },
      });

      final round = WalletModel.fromJson(original.toJson());
      expect(round.data?.transactions, hasLength(1));
      expect(round.data?.transactions?.single.amountValue, 5);
    });
  });
}
