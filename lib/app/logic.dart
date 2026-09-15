import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/screens/home/data/repository/home_repository.dart';

import 'state.dart';

/// D-03/D-04 (`12`) — replaces `HomeBloc` and `CurrentDriverInfoBloc`.
///
/// App-lifetime driver state: online/offline, approval gate, and the current
/// in-progress ride. Every one of those is read by more than one screen —
/// `drawer/`'s approval banner and app-bar toggle, `home/`'s ride-status
/// redirect — so it belongs to the app, not to a screen (`14` §2, §3.5).
/// This is driver's counterpart to passenger's `AppLogic`, and it is
/// registered exactly once, in `app/service.dart`.
///
/// `HomeBloc`'s `GetCurrentLocationEvent`/`GenerateMarker` and their states
/// were dead — never dispatched, never consumed — and were not ported.
class AppLogic extends GetxController {
  AppLogic(this._repository);

  final HomeRepository _repository;
  final AppState state = AppState();

  bool get isApproved =>
      state.approvalStatus.value == DriverApprovalStatus.approved;

  void setApprovalStatus(int? code) {
    state.approvalStatus.value = driverApprovalStatusFromCode(code);
  }

  /// Fetched once from `DrawerLogic.onInit`, the same trigger point the bloc
  /// had. `home/logic.dart` reacts to changes via `ever()` to redirect into
  /// an in-progress ride, and this also feeds the D-03 approval gate — the
  /// bloc's driver-approval consumer and its ride-status consumer read the
  /// same API response, so one fetch serves both.
  Future<void> fetchCurrentDriveInfo() async {
    final result = await _repository.getCurrentDriveInfo();
    result.when(
      ok: (data) {
        setApprovalStatus(data.data?.driver?.status);
        state.currentDriveInfo.value = data;
      },
      err: (_) {},
    );
  }

  Future<void> checkStatus() async {
    final result = await _repository.getStatus();
    result.when(
      ok: (data) => state.isOnline.value = data.data?.isAvailable == 1,
      err: (_) {},
    );
  }

  /// The original (`HomeBloc._toggleDriverService`) set `isOnline`
  /// optimistically before the request resolved, same as here, but never
  /// rolled it back on failure and never dismissed its EasyLoading overlay
  /// outside the success path — a failed toggle left the switch showing the
  /// wrong state forever under a spinner that never went away. Fixed:
  /// rollback on error, dismiss in `finally`.
  Future<void> toggle(bool turnOn) async {
    if (turnOn && !isApproved) return;
    final previous = state.isOnline.value;
    state.isOnline.value = turnOn;
    EasyLoading.show();
    try {
      final result = await _repository.setStatus(turnOn ? 1 : 0);
      result.when(
        ok: (data) => state.isOnline.value = data.data?.isAvailable == 1,
        err: (_) => state.isOnline.value = previous,
      );
    } finally {
      EasyLoading.dismiss();
    }
  }
}
