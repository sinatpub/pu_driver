import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/api_exception.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/datasource/referral_datasource.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/repository/referral_repository.dart';
import 'package:tara_driver_application/presentation/screens/invite/logic.dart';
import 'package:tara_driver_application/presentation/screens/invite/state.dart';

/// DD-48 — moving rewards into the wallet balance. It is the driver's money:
/// one confirmed transfer must be one request, and the screen must end up
/// showing what the server has.
class _Referral extends ReferralRepository {
  _Referral() : super(ReferralDatasource(apiClient: ApiClient(dio: Dio())));

  int fetches = 0;
  final List<String> transferIds = <String>[];
  final List<num> amounts = <num>[];
  num balance = 5160;

  /// Completed by a test to hold a transfer in flight.
  Completer<void>? gate;
  bool fail = false;

  @override
  Future<Result<ReferralModel>> getReferral() async {
    fetches++;
    return Result<ReferralModel>.ok(ReferralModel(rewardBalance: balance));
  }

  @override
  Future<Result<RewardTransferResult>> transferRewards({
    required num amount,
    required String requestId,
  }) async {
    transferIds.add(requestId);
    amounts.add(amount);
    await gate?.future;
    if (fail) {
      return Result<RewardTransferResult>.err(
        const ApiException(type: ApiErrorType.connection, message: 'offline'),
      );
    }
    balance -= amount;
    return Result<RewardTransferResult>.ok(
      RewardTransferResult(transferred: amount),
    );
  }
}

void main() {
  late _Referral referral;
  late InviteLogic logic;

  setUp(() async {
    referral = _Referral();
    logic = InviteLogic(referral);
    await logic.fetch();
  });

  test('a transfer sends the typed amount, returns what moved and refetches',
      () async {
    expect(await logic.transferRewards(2000), 2000);

    expect(referral.amounts, <num>[2000]);
    expect(referral.fetches, 2);
    expect(logic.state.referral.value!.rewardBalance, 3160);
    expect(logic.state.transferring.value, isFalse);
  });

  test('a second tap while one is out sends nothing', () async {
    referral.gate = Completer<void>();
    final Future<num?> first = logic.transferRewards(5160);
    expect(logic.state.transferring.value, isTrue);

    expect(await logic.transferRewards(5160), isNull);
    referral.gate!.complete();
    expect(await first, 5160);
    expect(referral.transferIds, hasLength(1));
  });

  test('a failed transfer returns null and keeps what is on screen', () async {
    referral.fail = true;

    expect(await logic.transferRewards(2000), isNull);
    expect(referral.fetches, 1);
    expect(logic.state.referral.value!.rewardBalance, 5160);
    expect(logic.state.status.value, InviteStatus.loaded);
    expect(logic.state.transferring.value, isFalse);
  });

  test('each confirmed transfer has its own request id', () async {
    await logic.transferRewards(1000);
    await logic.transferRewards(1000);

    expect(referral.transferIds.toSet(), hasLength(2));
  });
}
