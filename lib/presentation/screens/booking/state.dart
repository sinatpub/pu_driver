import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/data/models/complete_driver_model.dart';
import 'package:tara_driver_application/data/models/confirm_booking_model.dart';
import 'package:tara_driver_application/presentation/screens/booking/domain/trip_state_machine.dart';

/// One successful trip-lifecycle action, for the screen's `ever()` listener
/// to react to (socket triggers, navigation) — the same shape as the
/// `BlocConsumer` listener branches `booking_screen.dart` used to have, now
/// carrying the response data instead of the screen digging it out of the
/// bloc's state.
///
/// Deliberately no `const` constructors here — these are events, not values.
/// A canonicalized `const TripArrived()` would be `identical()` to every
/// other `const TripArrived()`, and `ever()` only fires on change, so a
/// second occurrence within one screen's lifetime would silently not fire.
sealed class TripActionResult {}

class TripAccepted extends TripActionResult {
  TripAccepted(this.confirmed);
  final ConfirmBookingModel confirmed;
}

class TripArrived extends TripActionResult {}

class TripStarted extends TripActionResult {}

class TripCompleted extends TripActionResult {
  TripCompleted(this.completed);
  final CompleteDriverModel completed;
}

class TripCancelled extends TripActionResult {}

enum TripActionError {
  /// Any of the 5 actions failed outright (network/HTTP/exception) —
  /// "PLEASE_TRY_AGAIN" in the original.
  generic,

  /// accept() got a 200 with no booking data because someone else already
  /// took the ride.
  rideAlreadyAccepted,

  /// accept() got a 200 with no booking data for any other reason —
  /// "COMFIRM_ERROR"/"CAN_NOT_CONFIRM_BOOKING" in the original, distinct
  /// from [generic] because the HTTP call itself didn't fail.
  confirmFailed,
}

class BookingState {
  BookingState(TripStage initialStage) : stage = Rx<TripStage>(initialStage);

  final Rx<TripStage> stage;
  final RxBool isLoading = false.obs;
  final Rx<TripActionResult?> lastResult = Rx<TripActionResult?>(null);
  final Rx<TripActionError?> lastError = Rx<TripActionError?>(null);
}
