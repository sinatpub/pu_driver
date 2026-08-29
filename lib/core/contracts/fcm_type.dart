/// F-01 (docs/12) — relocated from `core/utils/status_util.dart` verbatim.
/// Only [request] is actually referenced today (as a local-notification
/// ID, not for FCM payload type dispatch); the rest are unverified against
/// any FCM payload this app currently sends or receives.
class FcmType {
  const FcmType._();

  static const int none = -1;
  static const int news = 0;
  static const int request = 1;

  static const int riding = 3;
  static const int completed = 9;
  static const int topUp = 10;
  static const int withdraw = 11;
  static const int passPay = 13;
  static const int otherAccept = 98;
  static const int acceptError = 99;
  static const int updateVersion = 100;
  static const int noMeter = 101;
  static const int vibrate = 102;
  static const int language = 103;
  static const int outTime = 30;

  static const int inActive = 2; // This number for admin
}
