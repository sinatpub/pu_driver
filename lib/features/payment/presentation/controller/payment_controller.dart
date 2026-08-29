import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/payment/data/repository/payment_repository.dart';

enum PaymentStatus { initial, loading, success, error }

/// D-08 (docs/12) — the "PAYMENT_DONE" button on calculate_fee_screen.dart
/// used to call `BookingApi().completePayment(...)` directly from
/// `onPressed`, with only a `.then()` handling the success path — an
/// exception (no network, say) had nowhere to go, so `loadingCompletePay`
/// never got reset and the button stayed a spinner forever. ApiClient/
/// `Result<T>` can't throw past this controller (DioExceptions become
/// `Result.err` inside ApiClient itself), so that failure mode is gone by
/// construction, not by an added try/catch.
class PaymentController extends GetxController {
  PaymentController(this._repository);

  final PaymentRepository _repository;

  final status = Rx<PaymentStatus>(PaymentStatus.initial);

  Future<void> acceptPayment(int rideId) async {
    status.value = PaymentStatus.loading;
    final result = await _repository.acceptPayment(rideId);
    result.when(
      ok: (_) => status.value = PaymentStatus.success,
      err: (_) => status.value = PaymentStatus.error,
    );
  }
}
