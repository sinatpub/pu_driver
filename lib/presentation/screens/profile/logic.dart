import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/profile/data/repository/profile_repository.dart';

import 'state.dart';

/// D-12 (`12`). Moved out of `features/profile/presentation/controller/` per
/// `14` §3.6.
///
/// Unlike every other screen unit this one has **no `view.dart`** — driver has
/// no profile route. The shipped profile UI is [ProfileHeaderWidget], rendered
/// inside `DrawerScreen`'s header, and the same data is read by `home/` and
/// `calculate_fee/`. See `14` §6.3 for why that makes profile shared state
/// rather than a screen.
class ProfileLogic extends GetxController {
  ProfileLogic(this._repository);

  final ProfileRepository _repository;
  final ProfileState state = ProfileState();

  Future<void> fetchProfile() async {
    state.status.value = ProfileStatus.loading;
    final result = await _repository.getProfile();
    result.when(
      ok: (data) {
        state.profile.value = data;
        state.status.value = ProfileStatus.loaded;
      },
      err: (error) {
        state.errorMessage.value = error.message;
        state.status.value = ProfileStatus.error;
      },
    );
  }
}
