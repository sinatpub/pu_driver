import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/version_check/data/models/version_app_model.dart';
import 'package:tara_driver_application/features/version_check/data/repository/version_check_repository.dart';

enum VersionCheckStatus { initial, loading, loaded, error }

class VersionCheckController extends GetxController {
  VersionCheckController(this._repository);

  final VersionCheckRepository _repository;

  final status = Rx<VersionCheckStatus>(VersionCheckStatus.initial);
  final versionData = Rxn<VersionAppModel>();

  Future<void> check() async {
    status.value = VersionCheckStatus.loading;
    final result = await _repository.getCurrentVersion();
    result.when(
      ok: (data) {
        versionData.value = data;
        status.value = VersionCheckStatus.loaded;
      },
      err: (_) => status.value = VersionCheckStatus.error,
    );
  }
}
