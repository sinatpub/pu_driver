import 'dart:math';

import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/presentation/screens/invite/data/models/referral_model.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/repository/referral_repository.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/invite_presentation.dart';

import 'state.dart';

/// DD-45 — the driver's invite code, rewards and invited people. One fetch
/// serves the QR sheet and the two screens behind it.
class InviteLogic extends GetxController {
  InviteLogic(this._repository);

  final ReferralRepository _repository;
  final InviteState state = InviteState();

  Future<void> fetch() async {
    // A refresh keeps what is on screen; only the first load shows a skeleton.
    if (state.referral.value == null) {
      state.status.value = InviteStatus.loading;
    }
    final result = await _repository.getReferral();
    result.when(
      ok: (ReferralModel data) {
        state.referral.value = data;
        state.status.value = InviteStatus.loaded;
      },
      err: (_) {
        if (state.referral.value == null) {
          state.status.value = InviteStatus.error;
        }
      },
    );
  }

  /// Moves [amount] of the reward balance into the wallet balance (DD-48,
  /// DD-49).
  ///
  /// Returns what the server moved, or null when it failed or one is already
  /// out. The referral is fetched again on success, so the reward balance
  /// and the history on screen are the server's. One request id serves the
  /// attempt, so a retry the network layer makes is not a second transfer.
  Future<num?> transferRewards(num amount) async {
    if (state.transferring.value) return null;
    state.transferring.value = true;
    try {
      final result = await _repository.transferRewards(
        amount: amount,
        requestId: _newRequestId(),
      );
      final num? moved = result.when(
        ok: (RewardTransferResult r) => r.transferred ?? amount,
        err: (_) => null,
      );
      if (moved != null) await fetch();
      return moved;
    } finally {
      state.transferring.value = false;
    }
  }

  static final Random _random = Random();

  static String _newRequestId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  void selectPeopleFilter(InviteeRole? role) => state.peopleFilter.value = role;

  List<Invitee> get visibleInvitees => inviteesOf(
        state.referral.value?.invitees ?? const <Invitee>[],
        state.peopleFilter.value,
      );

  /// Rewards and transfers, newest first.
  List<RewardEntry> get history => rewardEntries(
        state.referral.value?.rewards ?? const <ReferralReward>[],
        state.referral.value?.transfers ?? const <RewardTransfer>[],
      );
}
