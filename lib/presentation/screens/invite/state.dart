import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/presentation/screens/invite/data/models/referral_model.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/invite_presentation.dart';

enum InviteStatus { initial, loading, loaded, error }

class InviteState {
  final Rx<InviteStatus> status = Rx<InviteStatus>(InviteStatus.initial);
  final Rxn<ReferralModel> referral = Rxn<ReferralModel>();

  /// The "People you invited" filter; null means everyone.
  final Rxn<InviteeRole> peopleFilter = Rxn<InviteeRole>();

  /// True while a transfer to the wallet balance is out (DD-48). The buttons
  /// that start one are disabled, so it cannot be sent twice.
  final RxBool transferring = false.obs;
}
