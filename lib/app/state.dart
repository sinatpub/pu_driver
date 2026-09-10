import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/data/models/current_driver_info_model.dart';

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

class AppState {
  final RxBool isOnline = false.obs;
  final Rx<DriverApprovalStatus> approvalStatus =
      DriverApprovalStatus.unknown.obs;
  final Rx<CurrentDriverInfoModel?> currentDriveInfo =
      Rx<CurrentDriverInfoModel?>(null);
}
