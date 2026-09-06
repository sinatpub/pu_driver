import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/data/models/register_model.dart';

enum OtpStatus { initial, loading, loaded, newDriver, fail }

class OtpState {
  final Rx<OtpStatus> status = Rx<OtpStatus>(OtpStatus.initial);
  final Rxn<RegisterModel> registerModel = Rxn<RegisterModel>();

  /// Countdown until "resend" becomes tappable. These were plain
  /// `setState` fields on `_OtpPageState` sitting inside an `Obx` that read
  /// no observable at all — see `logic.dart`.
  final RxInt secondsRemaining = 0.obs;
  final RxBool isResendEnabled = false.obs;

  /// Why the last verify failed, straight from the server ("OTP not correct").
  /// Null falls back to the generic copy.
  final RxnString errorMessage = RxnString();
}
