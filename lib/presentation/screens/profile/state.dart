import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/profile/data/models/profile_model.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState {
  final Rx<ProfileStatus> status = Rx<ProfileStatus>(ProfileStatus.initial);
  final Rxn<ProfileModel> profile = Rxn<ProfileModel>();
  final RxnString errorMessage = RxnString();
}
