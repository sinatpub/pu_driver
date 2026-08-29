import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/data/models/current_driver_info_model.dart';
import 'package:tara_driver_application/features/home/data/repository/home_repository.dart';

/// D-03 (docs/12) — the backend's `driver.status` field on
/// `get-current-drive-info`: 0 = pending, 1 = approved, 2 = rejected
/// (client-owner confirmed 2026-08-29, not yet in a backend-owned contract
/// doc — same unconfirmed-but-recorded footing as the booking-status
/// mapping in `docs/05`). `unknown` is the pre-fetch default and is treated
/// as not-approved so the gate fails closed instead of open.
enum DriverApprovalStatus { unknown, pending, approved, rejected }

DriverApprovalStatus driverApprovalStatusFromCode(int? code) {
  switch (code) {
    case 1:
      return DriverApprovalStatus.approved;
    case 2:
      return DriverApprovalStatus.rejected;
    case 0:
      return DriverApprovalStatus.pending;
    default:
      return DriverApprovalStatus.unknown;
  }
}

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

  /// D-03 — reinstates the driver-approval gate. Fed by `drawer_screen.dart`
  /// from the `get-current-drive-info` response it already fetches on init;
  /// the server independently enforces this too (Q-3, `docs/13`), so this is
  /// a client-side UX gate, not the only barrier.
  final approvalStatus = DriverApprovalStatus.unknown.obs;

  bool get isApproved => approvalStatus.value == DriverApprovalStatus.approved;

  void setApprovalStatus(int? code) {
    approvalStatus.value = driverApprovalStatusFromCode(code);
  }

  /// D-04 (docs/12) — replaces `CurrentDriverInfoBloc`. Fetched once from
  /// `drawer_screen.dart`'s `initState`, same trigger point the bloc had;
  /// `home_screen.dart` reacts to changes via `ever()` to redirect into an
  /// in-progress ride, and this also feeds the D-03 approval gate above —
  /// the bloc's driver-approval consumer and its ride-status consumer read
  /// the same API response, so one fetch now serves both instead of the
  /// approval half being wired separately in `drawer_screen.dart`.
  final currentDriveInfo = Rx<CurrentDriverInfoModel?>(null);

  Future<void> fetchCurrentDriveInfo() async {
    final result = await _repository.getCurrentDriveInfo();
    result.when(
      ok: (data) {
        setApprovalStatus(data.data?.driver?.status);
        currentDriveInfo.value = data;
      },
      err: (_) {},
    );
  }

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
    if (turnOn && !isApproved) return;
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
