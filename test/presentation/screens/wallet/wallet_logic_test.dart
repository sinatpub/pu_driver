import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pu_taxi_driver/core/network/api_client.dart';
import 'package:pu_taxi_driver/core/network/api_exception.dart';
import 'package:pu_taxi_driver/core/network/result.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/data/datasource/wallet_datasource.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/data/models/wallet_model.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/data/repository/wallet_repository.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/logic.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/state.dart';

/// The silent refresh used after a reward transfer (DD-48): the driver is
/// looking at the balance, so it must not blink away or turn into an error.
class _Wallet extends WalletRepository {
  _Wallet() : super(WalletDatasource(apiClient: ApiClient(dio: Dio())));

  bool fail = false;
  final List<WalletStatus> seenWhileFetching = <WalletStatus>[];
  late WalletLogic logic;

  @override
  Future<Result<WalletModel>> getWallet() async {
    seenWhileFetching.add(logic.state.status.value);
    if (fail) {
      return Result<WalletModel>.err(
        const ApiException(type: ApiErrorType.connection, message: 'offline'),
      );
    }
    return Result<WalletModel>.ok(WalletModel.fromJson(<String, dynamic>{
      'status': true,
      'data': <String, dynamic>{'balance': 85400, 'currency': 'KHR'},
    }));
  }
}

void main() {
  late _Wallet wallet;
  late WalletLogic logic;

  setUp(() {
    wallet = _Wallet();
    logic = WalletLogic(wallet);
    wallet.logic = logic;
  });

  test('a first fetch shows the skeleton, silent or not', () async {
    await logic.fetch(silent: true);

    expect(wallet.seenWhileFetching, <WalletStatus>[WalletStatus.loading]);
    expect(logic.state.status.value, WalletStatus.loaded);
  });

  test('a silent refresh keeps the loaded wallet on screen', () async {
    await logic.fetch();
    await logic.fetch(silent: true);

    expect(wallet.seenWhileFetching.last, WalletStatus.loaded);
  });

  test('a silent refresh that fails keeps the wallet, not an error', () async {
    await logic.fetch();
    wallet.fail = true;
    await logic.fetch(silent: true);

    expect(logic.state.status.value, WalletStatus.loaded);
    expect(logic.state.wallet.value, isNotNull);
  });

  test('a plain fetch that fails is still an error with a retry', () async {
    wallet.fail = true;
    await logic.fetch();

    expect(logic.state.status.value, WalletStatus.error);
  });
}
