import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/data/models/complete_driver_model.dart';
import 'package:tara_driver_application/data/models/current_driver_info_model.dart';
import 'package:tara_driver_application/features/payment/data/repository/payment_repository.dart';
import 'package:tara_driver_application/presentation/screens/profile/logic.dart';
import 'package:tara_driver_application/presentation/widgets/error_dialog_widget.dart';
import 'package:tara_driver_application/taxi_single_ton/init_socket.dart';

import 'state.dart';

/// D-08 (`12`). Moved out of `features/payment/presentation/controller/` per
/// `14` §3.6, absorbing the four route-argument accessors and the navigation
/// worker that lived in `_CalculateFeeScreenState`.
///
/// The "PAYMENT_DONE" button used to call `BookingApi().completePayment(...)`
/// straight from `onPressed`, with only a `.then()` handling success — an
/// exception (no network, say) had nowhere to go, so the button stayed a
/// spinner forever. `ApiClient`/`Result<T>` can't throw past here
/// (DioExceptions become `Result.err` inside `ApiClient`), so that failure
/// mode is gone by construction, not by an added try/catch.
class CalculateFeeLogic extends GetxController {
  CalculateFeeLogic(
    this._repository, {
    required this.routFrom,
    required this.dataComplete,
    required this.dataDriverInfo,
    required this.startAddress,
    required this.endAddress,
  });

  final PaymentRepository _repository;

  /// "FromHome" or "FromDropBooking" — decides which of the two payload
  /// shapes below the screen reads from.
  final String routFrom;
  final CompleteDriverModel? dataComplete;
  final DataDriverInfo? dataDriverInfo;
  final String startAddress;
  final String endAddress;

  final CalculateFeeState state = CalculateFeeState();

  bool get isFromDropBooking => routFrom == "FromDropBooking";

  int get rideId => isFromDropBooking
      ? dataComplete!.data!.id!
      : int.parse(dataDriverInfo!.id.toString());

  String get passengerId => isFromDropBooking
      ? dataComplete!.data!.passenger!.id.toString()
      : dataDriverInfo!.passenger!.id.toString();

  String get bookingCode => isFromDropBooking
      ? dataComplete!.data!.bookingCode.toString()
      : dataDriverInfo!.bookingCode.toString();

  String get bookingId => isFromDropBooking
      ? dataComplete!.data!.id.toString()
      : dataDriverInfo!.id.toString();

  @override
  void onInit() {
    super.onInit();
    ever<PaymentStatus>(state.status, _onStatusChanged);
  }

  void _onStatusChanged(PaymentStatus status) {
    if (status == PaymentStatus.success) {
      // Trigger Accept Payment Done Socket
      DriverSocketService().acceptPayment(
        passengerId: passengerId,
        bookingCode: bookingCode,
        bookingId: bookingId,
      );
      Get.find<ProfileLogic>().fetchProfile();
      Get.offAllNamed(AppRoutes.home);
    } else if (status == PaymentStatus.error) {
      showErrorCustomDialog(Get.context!, "Please Try Again!",
          "Please try again. Something went wrong.", false);
    }
  }

  Future<void> acceptPayment() async {
    state.status.value = PaymentStatus.loading;
    final result = await _repository.acceptPayment(rideId);
    result.when(
      ok: (_) => state.status.value = PaymentStatus.success,
      err: (_) => state.status.value = PaymentStatus.error,
    );
  }
}
