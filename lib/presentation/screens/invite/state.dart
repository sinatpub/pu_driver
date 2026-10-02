import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';
import 'package:tara_driver_application/presentation/screens/invite/invite_presentation.dart';

enum InviteStatus { initial, loading, loaded, error }

class InviteState {
  final Rx<InviteStatus> status = Rx<InviteStatus>(InviteStatus.initial);
  final Rxn<ReferralModel> referral = Rxn<ReferralModel>();

  /// The "People you invited" filter; null means everyone.
  final Rxn<InviteeRole> peopleFilter = Rxn<InviteeRole>();
}
