import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/data/models/current_driver_info_model.dart';

/// D-03 (`12`) — the backend's `driver.status` field on
/// `get-current-drive-info`: 0 = pending, 1 = approved, 2 = rejected
/// (client-owner confirmed 2026-08-29, not yet in a backend-owned contract
/// doc — same unconfirmed-but-recorded footing as the booking-status mapping
/// in `05`). `unknown` is the pre-fetch default and is treated as
/// not-approved so the gate fails closed instead of open.
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

/// What the approval gate shows once `get-current-drive-info` has answered.
///
/// The driver's own status decides, when the answer carries one. The backend
/// answers `"data": null` for a driver with no trip — seen 2026-10-06 — and
/// that says nothing about approval. It is read as **free to work** (product
/// owner, same day): the gate opens and the driver can go online. This is
/// safe because the server refuses an unapproved driver on `set-status`
/// whatever the app shows (`docs/13` Q-3).
///
/// A call that fails does not reach here, so the gate keeps "checking" and
/// its retry button for that case.
DriverApprovalStatus approvalStatusForDriveInfo(CurrentDriverInfoModel info) {
  final int? code = info.data?.driver?.status;
  if (code == null) return DriverApprovalStatus.approved;
  return driverApprovalStatusFromCode(code);
}

class AppState {
  final RxBool isOnline = false.obs;
  final Rx<DriverApprovalStatus> approvalStatus =
      DriverApprovalStatus.unknown.obs;

  /// The approval check is on its way: the first one after sign-in, or a
  /// "Check again".
  final RxBool approvalChecking = false.obs;

  /// The last check gave no answer — the call failed, or it carried a status
  /// the app does not know — and no answer is known from before. Without
  /// this, "still checking" and "could not check" look the same (DD-52).
  final RxBool approvalCheckFailed = false.obs;

  /// `check-status` has answered (or failed) since sign-in, so
  /// [isOnline] is the server's word and not just the default.
  final RxBool statusChecked = false.obs;

  /// The home has a GPS fix. A driver who cannot be located is not put
  /// online without asking (DD-53).
  final RxBool locationReady = false.obs;

  final Rx<CurrentDriverInfoModel?> currentDriveInfo =
      Rx<CurrentDriverInfoModel?>(null);
}
