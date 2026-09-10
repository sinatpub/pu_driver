/// D-06 (docs/12, docs/10 §4/§5) — the trip lifecycle as a plain Dart state
/// machine, independent of Flutter, GetX, or Bloc, per docs/10 §2.4's
/// migration condition: "the trip state machine is extracted and tested
/// first... If that is done, the library choice becomes reversible and
/// low-stakes. If it is not, the migration will carry the current defects
/// into new syntax and nobody will be able to prove it didn't."
///
/// This encodes the transition graph `booking_screen.dart` currently
/// implements as an `int processStepBook` mutated by `setState` calls
/// scattered across the widget — some of them gated on a successful API
/// response, some (`Future.delayed(Duration(seconds: 1), () => setState(...
/// processStepBook = N))`) not gated on anything at all, just a timer.
/// [TripStateMachine] only ever advances when its caller calls the matching
/// method — there is no delayed, unconditional self-advance possible here.
///
/// Stage <-> the legacy `processStepBook` int, for interop while callers
/// still pass that int around (route arguments, `ride_request_bottom_pop_widget`'s
/// `processType`, `home_screen.dart`'s `getProcessStepBook`):
/// idle=0, requestReceived=1, enRouteToPickup=2, waitingAtPickup=3,
/// inProgress=4, completing=6 (5 is not used by the legacy int either).
enum TripStage {
  idle,
  requestReceived,
  enRouteToPickup,
  waitingAtPickup,
  inProgress,
  completing
}

extension TripStageProcessStep on TripStage {
  int toProcessStep() => switch (this) {
        TripStage.idle => 0,
        TripStage.requestReceived => 1,
        TripStage.enRouteToPickup => 2,
        TripStage.waitingAtPickup => 3,
        TripStage.inProgress => 4,
        TripStage.completing => 6,
      };

  static TripStage fromProcessStep(int step) => switch (step) {
        0 => TripStage.idle,
        1 => TripStage.requestReceived,
        2 => TripStage.enRouteToPickup,
        3 => TripStage.waitingAtPickup,
        4 => TripStage.inProgress,
        6 => TripStage.completing,
        _ => throw ArgumentError.value(step, 'step', 'not a known trip stage'),
      };
}

class InvalidTripTransition implements Exception {
  const InvalidTripTransition({required this.from, required this.action});

  final TripStage from;
  final String action;

  @override
  String toString() => 'TripStateMachine: cannot $action from $from';
}

/// One driver-side trip, from a ride request landing to the driver dropping
/// the passenger off. Every method here is a transition attempt: it either
/// returns the new stage or throws [InvalidTripTransition] — there is no
/// silent no-op, so a caller driving this from the wrong stage fails loudly
/// instead of drifting the UI out of sync with the server the way the
/// current widget can.
class TripStateMachine {
  TripStateMachine([TripStage initial = TripStage.idle]) : _stage = initial;

  TripStage _stage;
  TripStage get stage => _stage;

  bool get canCancel => _stage == TripStage.requestReceived;

  /// A new ride request lands (socket `newRide` event / FCM notification).
  TripStage receiveRequest() => _move(
      from: {TripStage.idle},
      to: TripStage.requestReceived,
      action: 'receive request');

  /// Driver accepted — call only after `confirm-drive-request` succeeds.
  TripStage accept() => _move(
      from: {TripStage.requestReceived},
      to: TripStage.enRouteToPickup,
      action: 'accept');

  /// Driver cancelled — only ever offered in the UI while a request is
  /// still pending (matches `ride_request_bottom_pop_widget`'s
  /// `processType == 1` gate on the cancel button). Cancelling doesn't
  /// produce a stage of its own; the caller tears the trip down.
  void cancel() {
    if (!canCancel) {
      throw InvalidTripTransition(from: _stage, action: 'cancel');
    }
  }

  /// Driver reached the pickup — call only after `drive-arrive` succeeds.
  TripStage arrive() => _move(
      from: {TripStage.enRouteToPickup},
      to: TripStage.waitingAtPickup,
      action: 'arrive');

  /// Trip starts — call only after `start-drive` succeeds.
  TripStage start() => _move(
      from: {TripStage.waitingAtPickup},
      to: TripStage.inProgress,
      action: 'start');

  /// Driver drops the passenger — call only after `complete-drive` succeeds.
  TripStage complete() => _move(
      from: {TripStage.inProgress},
      to: TripStage.completing,
      action: 'complete');

  TripStage _move(
      {required Set<TripStage> from,
      required TripStage to,
      required String action}) {
    if (!from.contains(_stage)) {
      throw InvalidTripTransition(from: _stage, action: action);
    }
    return _stage = to;
  }
}
