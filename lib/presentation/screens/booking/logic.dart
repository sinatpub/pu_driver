import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/screens/booking/data/repository/trip_repository.dart';
import 'package:tara_driver_application/presentation/screens/booking/domain/trip_state_machine.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';

import 'state.dart';

/// D-06 (`12`) — GetX front for [TripStateMachine]. Every method here is
/// what `booking_screen.dart`'s `BlocConsumer<BookingBloc, ...>` used to do
/// inline: call the API, and only on a real success advance the state
/// machine. [lastResult] and [lastError] replace the old sealed
/// `BookingState` — the screen still owns the socket triggers, map/polyline
/// work, and navigation (all of which need BuildContext or widget-local GPS
/// state this controller has no business holding), reacting to those two
/// via `ever()` the same way the rest of this migration's controllers do.
class BookingLogic extends GetxController {
  BookingLogic(
    this._repository, {
    required this.rideId,
    required TripStage initialStage,
  })  : _machine = TripStateMachine(initialStage),
        state = BookingState(initialStage);

  final TripRepository _repository;
  final int rideId;
  final TripStateMachine _machine;

  final BookingState state;

  bool get canCancel => _machine.canCancel;

  Future<void> accept() async {
    if (state.isLoading.value) return;
    state.isLoading.value = true;
    final result = await _repository.confirm(rideId);
    state.isLoading.value = false;

    result.when(
      ok: (model) {
        if (model.data != null) {
          _machine.accept();
          state.stage.value = _machine.stage;
          state.lastError.value = null;
          state.lastResult.value = TripAccepted(model);
          Taxi.shared.notifyBooking(
              title: 'ACCEPT'.tr(),
              description: 'DESACCEPT'.tr(),
              isSound: false);
        } else if (model.message == 'RIDE_ALREADY_ACCEPTED') {
          state.lastError.value = TripActionError.rideAlreadyAccepted;
        } else {
          state.lastError.value = TripActionError.confirmFailed;
        }
      },
      err: (_) => state.lastError.value = TripActionError.generic,
    );
  }

  Future<void> cancel() async {
    if (state.isLoading.value || !canCancel) return;
    state.isLoading.value = true;
    final result = await _repository.cancel(rideId);
    state.isLoading.value = false;

    result.when(
      ok: (_) {
        _machine.cancel();
        state.lastError.value = null;
        state.lastResult.value = TripCancelled();
      },
      err: (_) => state.lastError.value = TripActionError.generic,
    );
  }

  Future<void> arrive() async {
    if (state.isLoading.value) return;
    state.isLoading.value = true;
    final result = await _repository.arrive(rideId);
    state.isLoading.value = false;

    result.when(
      ok: (_) {
        _machine.arrive();
        state.stage.value = _machine.stage;
        state.lastError.value = null;
        state.lastResult.value = TripArrived();
        Taxi.shared.notifyBooking(
            title: 'ARRIVE'.tr(),
            description: 'DESARRIVED'.tr(),
            isSound: false);
      },
      err: (_) => state.lastError.value = TripActionError.generic,
    );
  }

  Future<void> start() async {
    if (state.isLoading.value) return;
    state.isLoading.value = true;
    final result = await _repository.start(rideId);
    state.isLoading.value = false;

    result.when(
      ok: (_) {
        _machine.start();
        state.stage.value = _machine.stage;
        state.lastError.value = null;
        state.lastResult.value = TripStarted();
        Taxi.shared.notifyBooking(
            title: 'START_RIDE'.tr(),
            description: 'DESSTART'.tr(),
            isSound: false);
      },
      err: (_) => state.lastError.value = TripActionError.generic,
    );
  }

  Future<void> complete({
    required double endLatitude,
    required double endLongitude,
    required String endAddress,
    required double distance,
  }) async {
    if (state.isLoading.value) return;
    state.isLoading.value = true;
    final result = await _repository.complete(
      rideId: rideId,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
      endAddress: endAddress,
      distance: distance,
    );
    state.isLoading.value = false;

    result.when(
      ok: (model) {
        if (model.data != null) {
          _machine.complete();
          state.stage.value = _machine.stage;
          state.lastError.value = null;
          state.lastResult.value = TripCompleted(model);
          Taxi.shared.notifyBooking(
              title: 'COMPLETE_RIDE'.tr(),
              description: 'DESCOMPLED'.tr(),
              isSound: false);
        } else {
          // Mirrors accept()'s null-data safety net: a 200 with no `data`
          // would otherwise reach booking_screen.dart's
          // `_navigateToCalculateFee`, which null-asserts `data.data!...`
          // and crashes right after what looked like a successful drop-off.
          state.lastError.value = TripActionError.generic;
        }
      },
      err: (_) => state.lastError.value = TripActionError.generic,
    );
  }
}
