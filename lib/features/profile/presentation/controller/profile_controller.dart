import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/profile/data/models/profile_model.dart';
import 'package:tara_driver_application/features/profile/data/repository/profile_repository.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileController extends GetxController {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  final status = Rx<ProfileStatus>(ProfileStatus.initial);
  final profile = Rxn<ProfileModel>();
  final errorMessage = RxnString();

  Future<void> fetchProfile() async {
    status.value = ProfileStatus.loading;
    final result = await _repository.getProfile();
    result.when(
      ok: (data) {
        profile.value = data;
        status.value = ProfileStatus.loaded;
      },
      err: (error) {
        errorMessage.value = error.message;
        status.value = ProfileStatus.error;
      },
    );
  }
}
