import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/data/models/complete_driver_model.dart';
import 'package:tara_driver_application/data/models/confirm_booking_model.dart';
import 'package:tara_driver_application/features/trip/data/repository/trip_repository.dart';
import 'package:tara_driver_application/features/trip/domain/trip_state_machine.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';

/// One successful trip-lifecycle action, for the screen's `ever()` listener
/// to react to (socket triggers, navigation) — the same shape as the
/// `BlocConsumer` listener branches `booking_screen.dart` used to have, now
/// carrying the response data instead of the screen digging it out of the
/// bloc's state.
/// Deliberately no `const` constructors here — these are events, not values.
/// A canonicalized `const TripArrived()` would be `identical()` to every
/// other `const TripArrived()`, and `ever()` only fires on change, so a
/// second occurrence within one screen's lifetime would silently not fire.
/// Not currently reachable (the state machine's own guards mean each of
/// these fires at most once per BookingScreen instance), but an event type
/// shouldn't rely on that to stay correct.
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

/// D-06 (docs/12) — GetX front for [TripStateMachine]. Every method here is
/// what `booking_screen.dart`'s `BlocConsumer<BookingBloc, ...>` used to do
/// inline: call the API, and only on a real success advance the state
/// machine. [lastResult] and [lastError] replace the old sealed
/// `BookingState` — the screen still owns the socket triggers, map/polyline
/// work, and navigation (all of which need BuildContext or widget-local GPS
/// state this controller has no business holding), reacting to those two
/// via `ever()` the same way the rest of this migration's controllers do.
class TripController extends GetxController {
  TripController(this._repository, {required this.rideId, required TripStage initialStage})
      : _machine = TripStateMachine(initialStage) {
    stage = Rx<TripStage>(_machine.stage);
  }

  final TripRepository _repository;
  final int rideId;
  final TripStateMachine _machine;

  late final Rx<TripStage> stage;
  final isLoading = false.obs;
  final lastResult = Rx<TripActionResult?>(null);
  final lastError = Rx<TripActionError?>(null);

  bool get canCancel => _machine.canCancel;

  Future<void> accept() async {
    if (isLoading.value) return;
    isLoading.value = true;
    final result = await _repository.confirm(rideId);
    isLoading.value = false;

    result.when(
      ok: (model) {
        if (model.data != null) {
          _machine.accept();
          stage.value = _machine.stage;
          lastError.value = null;
          lastResult.value = TripAccepted(model);
          Taxi.shared.notifyBooking(title: 'ACCEPT'.tr(), description: 'DESACCEPT'.tr(), isSound: false);
        } else if (model.message == 'RIDE_ALREADY_ACCEPTED') {
          lastError.value = TripActionError.rideAlreadyAccepted;
        } else {
          lastError.value = TripActionError.confirmFailed;
        }
      },
      err: (_) => lastError.value = TripActionError.generic,
    );
  }

  Future<void> cancel() async {
    if (isLoading.value || !canCancel) return;
    isLoading.value = true;
    final result = await _repository.cancel(rideId);
    isLoading.value = false;

    result.when(
      ok: (_) {
        _machine.cancel();
        lastError.value = null;
        lastResult.value = TripCancelled();
      },
      err: (_) => lastError.value = TripActionError.generic,
    );
  }

  Future<void> arrive() async {
    if (isLoading.value) return;
    isLoading.value = true;
    final result = await _repository.arrive(rideId);
    isLoading.value = false;

    result.when(
      ok: (_) {
        _machine.arrive();
        stage.value = _machine.stage;
        lastError.value = null;
        lastResult.value = TripArrived();
        Taxi.shared.notifyBooking(title: 'ARRIVE'.tr(), description: 'DESARRIVED'.tr(), isSound: false);
      },
      err: (_) => lastError.value = TripActionError.generic,
    );
  }

  Future<void> start() async {
    if (isLoading.value) return;
    isLoading.value = true;
    final result = await _repository.start(rideId);
    isLoading.value = false;

    result.when(
      ok: (_) {
        _machine.start();
        stage.value = _machine.stage;
        lastError.value = null;
        lastResult.value = TripStarted();
        Taxi.shared.notifyBooking(title: 'START_RIDE'.tr(), description: 'DESSTART'.tr(), isSound: false);
      },
      err: (_) => lastError.value = TripActionError.generic,
    );
  }

  Future<void> complete({
    required double endLatitude,
    required double endLongitude,
    required String endAddress,
    required double distance,
  }) async {
    if (isLoading.value) return;
    isLoading.value = true;
    final result = await _repository.complete(
      rideId: rideId,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
      endAddress: endAddress,
      distance: distance,
    );
    isLoading.value = false;

    result.when(
      ok: (model) {
        _machine.complete();
        stage.value = _machine.stage;
        lastError.value = null;
        lastResult.value = TripCompleted(model);
        Taxi.shared.notifyBooking(title: 'COMPLETE_RIDE'.tr(), description: 'DESCOMPLED'.tr(), isSound: false);
      },
      err: (_) => lastError.value = TripActionError.generic,
    );
  }
}
