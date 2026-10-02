import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/repository/referral_repository.dart';
import 'package:tara_driver_application/presentation/screens/invite/invite_presentation.dart';

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

  void selectPeopleFilter(InviteeRole? role) => state.peopleFilter.value = role;

  List<Invitee> get visibleInvitees => inviteesOf(
        state.referral.value?.invitees ?? const <Invitee>[],
        state.peopleFilter.value,
      );

  List<ReferralReward> get rewards => sortedRewards(
        state.referral.value?.rewards ?? const <ReferralReward>[],
      );
}
