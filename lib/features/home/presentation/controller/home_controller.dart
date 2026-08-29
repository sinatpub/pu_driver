import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/home/data/repository/home_repository.dart';

/// D-04 (docs/12) — replaces `HomeBloc`. `GetCurrentLocationEvent`/
/// `GenerateMarker` and their states were dead (never dispatched, never
/// consumed) and aren't ported. `isOnline` is shared across screens —
/// `drawer_screen.dart`'s SwitchOnlineWidget reads and toggles it,
/// `home_screen.dart` triggers the initial check — so, like
/// ProfileController, this is `Get.put(permanent: true)` in main.dart, not
/// owned by one screen.
class HomeController extends GetxController {
  HomeController(this._repository);

  final HomeRepository _repository;

  final isOnline = false.obs;

  Future<void> checkStatus() async {
    final result = await _repository.getStatus();
    result.when(
      ok: (data) => isOnline.value = data.data?.isAvailable == 1,
      err: (_) {},
    );
  }

  /// The original (`HomeBloc._toggleDriverService`) set `isOnline`
  /// optimistically before the request resolved, same as here, but never
  /// rolled it back on failure and never dismissed its EasyLoading overlay
  /// outside the success path — a failed toggle left the switch showing
  /// the wrong state forever under a spinner that never went away. Fixed:
  /// rollback on error, dismiss in `finally`.
  Future<void> toggle(bool turnOn) async {
    final previous = isOnline.value;
    isOnline.value = turnOn;
    EasyLoading.show();
    try {
      final result = await _repository.setStatus(turnOn ? 1 : 0);
      result.when(
        ok: (data) => isOnline.value = data.data?.isAvailable == 1,
        err: (_) => isOnline.value = previous,
      );
    } finally {
      EasyLoading.dismiss();
    }
  }
}
