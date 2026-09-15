import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/presentation/screens/booking/domain/trip_state_machine.dart';

void main() {
  group('TripStateMachine', () {
    test('defaults to idle', () {
      expect(TripStateMachine().stage, TripStage.idle);
    });

    test('can be constructed at any stage, for re-entering an ongoing trip',
        () {
      // home_screen.dart can open BookingScreen mid-trip (app restart,
      // navigating back from another screen) with processStepBook already
      // at 2/3/4 — the machine has to support starting there directly.
      expect(
          TripStateMachine(TripStage.inProgress).stage, TripStage.inProgress);
    });

    test('happy path traverses every stage in order', () {
      final machine = TripStateMachine();
      expect(machine.receiveRequest(), TripStage.requestReceived);
      expect(machine.accept(), TripStage.enRouteToPickup);
      expect(machine.arrive(), TripStage.waitingAtPickup);
      expect(machine.start(), TripStage.inProgress);
      expect(machine.complete(), TripStage.completing);
    });

    test('re-entering mid-trip can still complete the remaining stages', () {
      final machine = TripStateMachine(TripStage.waitingAtPickup);
      expect(machine.start(), TripStage.inProgress);
      expect(machine.complete(), TripStage.completing);
    });

    group('cancel', () {
      test('is only allowed while a request is pending', () {
        expect(TripStateMachine(TripStage.requestReceived).canCancel, isTrue);
        for (final stage in [
          TripStage.idle,
          TripStage.enRouteToPickup,
          TripStage.waitingAtPickup,
          TripStage.inProgress,
          TripStage.completing,
        ]) {
          expect(TripStateMachine(stage).canCancel, isFalse, reason: '$stage');
        }
      });

      test('succeeds without changing stage when pending', () {
        final machine = TripStateMachine(TripStage.requestReceived);
        machine.cancel();
        expect(machine.stage, TripStage.requestReceived);
      });

      test('throws once a ride has been accepted', () {
        final machine = TripStateMachine(TripStage.enRouteToPickup);
        expect(machine.cancel, throwsA(isA<InvalidTripTransition>()));
        expect(machine.stage, TripStage.enRouteToPickup,
            reason: 'a rejected transition must not mutate state');
      });
    });

    group('rejects out-of-order and skipped transitions', () {
      // Every (action, valid-from-stage) pair below must throw from every
      // OTHER stage — this is the direct fix for the bug docs/10 calls out:
      // `Future.delayed(Duration(seconds: 1), () => setState(() =>
      // processStepBook = 3))` advanced the old int stage on a timer,
      // whether or not the API call it followed actually succeeded, and
      // with nothing stopping a second, out-of-order call from firing.
      final actions = <String,
          ({TripStage validFrom, TripStage Function(TripStateMachine) call})>{
        'receiveRequest': (
          validFrom: TripStage.idle,
          call: (m) => m.receiveRequest()
        ),
        'accept': (
          validFrom: TripStage.requestReceived,
          call: (m) => m.accept()
        ),
        'arrive': (
          validFrom: TripStage.enRouteToPickup,
          call: (m) => m.arrive()
        ),
        'start': (validFrom: TripStage.waitingAtPickup, call: (m) => m.start()),
        'complete': (
          validFrom: TripStage.inProgress,
          call: (m) => m.complete()
        ),
      };

      for (final entry in actions.entries) {
        for (final stage in TripStage.values) {
          if (stage == entry.value.validFrom) continue;
          test('${entry.key}() throws from $stage', () {
            final machine = TripStateMachine(stage);
            expect(() => entry.value.call(machine),
                throwsA(isA<InvalidTripTransition>()));
            expect(machine.stage, stage,
                reason: 'a rejected transition must not mutate state');
          });
        }
      }
    });

    test('a rejected transition reports the stage it was rejected from', () {
      final machine = TripStateMachine(TripStage.inProgress);
      expect(
        () => machine.accept(),
        throwsA(isA<InvalidTripTransition>()
            .having((e) => e.from, 'from', TripStage.inProgress)),
      );
    });
  });

  group('TripStageProcessStep', () {
    test(
        'round-trips through the legacy processStepBook int for every reachable stage',
        () {
      const expected = {
        TripStage.idle: 0,
        TripStage.requestReceived: 1,
        TripStage.enRouteToPickup: 2,
        TripStage.waitingAtPickup: 3,
        TripStage.inProgress: 4,
        TripStage.completing: 6,
      };
      expected.forEach((stage, step) {
        expect(stage.toProcessStep(), step);
        expect(TripStageProcessStep.fromProcessStep(step), stage);
      });
    });

    test('fromProcessStep rejects ints the legacy code never produced', () {
      for (final unknown in [-1, 5, 7, 99]) {
        expect(() => TripStageProcessStep.fromProcessStep(unknown),
            throwsArgumentError);
      }
    });
  });
}
