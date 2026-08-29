/// F-01 (docs/12) — the server's booking/ride `status` integer, as
/// returned by `get-current-drive-info` and `history-drive-info`.
///
/// Client-owner-supplied mapping (Q-1, `docs/05` §2), not yet backend-
/// confirmed. Replaces the driver app's old `BookingStatus` in
/// `core/utils/status_util.dart`, which was unreferenced dead code with a
/// different, wrong mapping (a typo'd `acceted`, and `4` meaning
/// `driverCancel` instead of `completed`).
class BookingStatus {
  const BookingStatus._();

  static const int request = 1;
  static const int accepted = 2;
  static const int startRide = 3;
  static const int completed = 4;
  static const int cancel = 5;
  static const int pendingPayment = 6;

  /// Duplicates [completed] — the client owner gave both `4` and `7` as
  /// "completed" with no explanation (Q-1, `docs/05` §2, still open with
  /// the backend). Kept as a distinct value rather than folded into
  /// [completed] so existing call sites' behavior isn't silently widened
  /// to match both codes until that's actually confirmed.
  static const int completedAlt = 7;

  static const int arrived = 8;
}
