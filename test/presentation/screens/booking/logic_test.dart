import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/api_exception.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/data/models/confirm_booking_model.dart';
import 'package:tara_driver_application/data/models/complete_driver_model.dart'
    as complete_model;
import 'package:tara_driver_application/features/trip/data/datasource/trip_datasource.dart';
import 'package:tara_driver_application/features/trip/data/repository/trip_repository.dart';
import 'package:tara_driver_application/features/trip/domain/trip_state_machine.dart';
import 'package:tara_driver_application/presentation/screens/booking/logic.dart';
import 'package:tara_driver_application/presentation/screens/booking/state.dart';

const _apiError = ApiException(type: ApiErrorType.unknown, message: 'boom');

/// Overrides every network call so no real HTTP request is ever made. The
/// `super()` datasource is unreachable dead weight required only to satisfy
/// [TripRepository]'s constructor — it's built with an explicit `Dio()` and
/// never touches `BaseHttpClient.dio` (a `late final` static that throws
/// unless `BaseHttpClient.init()` ran, which nothing in this test does).
class _FakeTripRepository extends TripRepository {
  _FakeTripRepository()
      : super(TripDatasource(apiClient: ApiClient(dio: Dio())));

  Result<ConfirmBookingModel>? confirmResult;
  Result<bool>? cancelResult;
  Result<ConfirmBookingModel>? arriveResult;
  Result<ConfirmBookingModel>? startResult;
  Result<complete_model.CompleteDriverModel>? completeResult;

  int confirmCalls = 0;
  int cancelCalls = 0;
  int arriveCalls = 0;
  int startCalls = 0;
  int completeCalls = 0;

  double? lastCompleteEndLat;
  double? lastCompleteEndLng;
  String? lastCompleteEndAddress;
  double? lastCompleteDistance;

  @override
  Future<Result<ConfirmBookingModel>> confirm(int rideId) async {
    confirmCalls++;
    return confirmResult!;
  }

  @override
  Future<Result<bool>> cancel(int rideId) async {
    cancelCalls++;
    return cancelResult!;
  }

  @override
  Future<Result<ConfirmBookingModel>> arrive(int rideId) async {
    arriveCalls++;
    return arriveResult!;
  }

  @override
  Future<Result<ConfirmBookingModel>> start(int rideId) async {
    startCalls++;
    return startResult!;
  }

  @override
  Future<Result<complete_model.CompleteDriverModel>> complete({
    required int rideId,
    required double endLatitude,
    required double endLongitude,
    required String endAddress,
    required double distance,
  }) async {
    completeCalls++;
    lastCompleteEndLat = endLatitude;
    lastCompleteEndLng = endLongitude;
    lastCompleteEndAddress = endAddress;
    lastCompleteDistance = distance;
    return completeResult!;
  }
}

BookingLogic _controller(_FakeTripRepository repo, TripStage stage) =>
    BookingLogic(repo, rideId: 42, initialStage: stage);

void main() {
  late _FakeTripRepository repo;

  setUp(() {
    repo = _FakeTripRepository();
  });

  group('accept()', () {
    test('on success: enRouteToPickup, TripAccepted, error cleared', () async {
      final controller = _controller(repo, TripStage.requestReceived);
      repo.confirmResult = Result.ok(ConfirmBookingModel(data: Data(id: 42)));

      await controller.accept();

      expect(controller.state.stage.value, TripStage.enRouteToPickup);
      expect(controller.state.lastResult.value, isA<TripAccepted>());
      expect(controller.state.lastError.value, isNull);
      expect(controller.state.isLoading.value, isFalse);
      expect(repo.confirmCalls, 1);
    });

    test(
        'ok with null data + RIDE_ALREADY_ACCEPTED: rideAlreadyAccepted error, no advance',
        () async {
      final controller = _controller(repo, TripStage.requestReceived);
      repo.confirmResult = Result.ok(
          ConfirmBookingModel(data: null, message: 'RIDE_ALREADY_ACCEPTED'));

      await controller.accept();

      expect(controller.state.stage.value, TripStage.requestReceived);
      expect(controller.state.lastError.value,
          TripActionError.rideAlreadyAccepted);
      expect(controller.state.lastResult.value, isNull);
    });

    test(
        'ok with null data + any other message: confirmFailed error, no advance',
        () async {
      final controller = _controller(repo, TripStage.requestReceived);
      repo.confirmResult =
          Result.ok(ConfirmBookingModel(data: null, message: 'nope'));

      await controller.accept();

      expect(controller.state.stage.value, TripStage.requestReceived);
      expect(controller.state.lastError.value, TripActionError.confirmFailed);
    });

    test('on API error: generic error, no advance', () async {
      final controller = _controller(repo, TripStage.requestReceived);
      repo.confirmResult = Result.err(_apiError);

      await controller.accept();

      expect(controller.state.stage.value, TripStage.requestReceived);
      expect(controller.state.lastError.value, TripActionError.generic);
      expect(controller.state.isLoading.value, isFalse);
    });

    test('a concurrent call is a no-op while one is in flight', () async {
      final controller = _controller(repo, TripStage.requestReceived);
      repo.confirmResult = Result.ok(ConfirmBookingModel(data: Data(id: 42)));

      final first = controller.accept();
      final second = controller.accept();
      await Future.wait([first, second]);

      expect(repo.confirmCalls, 1);
    });

    test(
        'a stage other than requestReceived fails loudly instead of silently drifting',
        () async {
      final controller = _controller(repo, TripStage.waitingAtPickup);
      repo.confirmResult = Result.ok(ConfirmBookingModel(data: Data(id: 42)));

      expect(() => controller.accept(), throwsA(isA<InvalidTripTransition>()));
    });
  });

  group('cancel()', () {
    test('on success: TripCancelled, error cleared', () async {
      final controller = _controller(repo, TripStage.requestReceived);
      repo.cancelResult = Result.ok(true);

      await controller.cancel();

      expect(controller.state.lastResult.value, isA<TripCancelled>());
      expect(controller.state.lastError.value, isNull);
      expect(repo.cancelCalls, 1);
    });

    test('on API error: generic error', () async {
      final controller = _controller(repo, TripStage.requestReceived);
      repo.cancelResult = Result.err(_apiError);

      await controller.cancel();

      expect(controller.state.lastError.value, TripActionError.generic);
    });

    test('outside requestReceived: no-op, never calls the API', () async {
      final controller = _controller(repo, TripStage.enRouteToPickup);

      await controller.cancel();

      expect(repo.cancelCalls, 0);
      expect(controller.state.lastResult.value, isNull);
      expect(controller.state.lastError.value, isNull);
    });

    test('a concurrent call is a no-op while one is in flight', () async {
      final controller = _controller(repo, TripStage.requestReceived);
      repo.cancelResult = Result.ok(true);

      final first = controller.cancel();
      final second = controller.cancel();
      await Future.wait([first, second]);

      expect(repo.cancelCalls, 1);
    });
  });

  group('arrive()', () {
    test('on success: waitingAtPickup, TripArrived, error cleared', () async {
      final controller = _controller(repo, TripStage.enRouteToPickup);
      repo.arriveResult = Result.ok(ConfirmBookingModel(data: Data(id: 42)));

      await controller.arrive();

      expect(controller.state.stage.value, TripStage.waitingAtPickup);
      expect(controller.state.lastResult.value, isA<TripArrived>());
      expect(controller.state.lastError.value, isNull);
      expect(repo.arriveCalls, 1);
    });

    test('on API error: generic error, no advance', () async {
      final controller = _controller(repo, TripStage.enRouteToPickup);
      repo.arriveResult = Result.err(_apiError);

      await controller.arrive();

      expect(controller.state.stage.value, TripStage.enRouteToPickup);
      expect(controller.state.lastError.value, TripActionError.generic);
    });

    test(
        'a stage other than enRouteToPickup fails loudly instead of silently drifting',
        () async {
      final controller = _controller(repo, TripStage.requestReceived);
      repo.arriveResult = Result.ok(ConfirmBookingModel(data: Data(id: 42)));

      expect(() => controller.arrive(), throwsA(isA<InvalidTripTransition>()));
    });

    test('a concurrent call is a no-op while one is in flight', () async {
      final controller = _controller(repo, TripStage.enRouteToPickup);
      repo.arriveResult = Result.ok(ConfirmBookingModel(data: Data(id: 42)));

      final first = controller.arrive();
      final second = controller.arrive();
      await Future.wait([first, second]);

      expect(repo.arriveCalls, 1);
    });
  });

  group('start()', () {
    test('on success: inProgress, TripStarted, error cleared', () async {
      final controller = _controller(repo, TripStage.waitingAtPickup);
      repo.startResult = Result.ok(ConfirmBookingModel(data: Data(id: 42)));

      await controller.start();

      expect(controller.state.stage.value, TripStage.inProgress);
      expect(controller.state.lastResult.value, isA<TripStarted>());
      expect(controller.state.lastError.value, isNull);
      expect(repo.startCalls, 1);
    });

    test('on API error: generic error, no advance', () async {
      final controller = _controller(repo, TripStage.waitingAtPickup);
      repo.startResult = Result.err(_apiError);

      await controller.start();

      expect(controller.state.stage.value, TripStage.waitingAtPickup);
      expect(controller.state.lastError.value, TripActionError.generic);
    });

    test(
        'a stage other than waitingAtPickup fails loudly instead of silently drifting',
        () async {
      final controller = _controller(repo, TripStage.enRouteToPickup);
      repo.startResult = Result.ok(ConfirmBookingModel(data: Data(id: 42)));

      expect(() => controller.start(), throwsA(isA<InvalidTripTransition>()));
    });

    test('a concurrent call is a no-op while one is in flight', () async {
      final controller = _controller(repo, TripStage.waitingAtPickup);
      repo.startResult = Result.ok(ConfirmBookingModel(data: Data(id: 42)));

      final first = controller.start();
      final second = controller.start();
      await Future.wait([first, second]);

      expect(repo.startCalls, 1);
    });
  });

  group('complete()', () {
    Future<void> callComplete(BookingLogic controller) => controller.complete(
          endLatitude: 11.55,
          endLongitude: 104.91,
          endAddress: 'Phnom Penh',
          distance: 3.4,
        );

    test('on success: completing, TripCompleted, error cleared, args forwarded',
        () async {
      final controller = _controller(repo, TripStage.inProgress);
      repo.completeResult = Result.ok(complete_model.CompleteDriverModel(
        data: complete_model.Data(id: 42),
      ));

      await callComplete(controller);

      expect(controller.state.stage.value, TripStage.completing);
      expect(controller.state.lastResult.value, isA<TripCompleted>());
      expect(controller.state.lastError.value, isNull);
      expect(repo.completeCalls, 1);
      expect(repo.lastCompleteEndLat, 11.55);
      expect(repo.lastCompleteEndLng, 104.91);
      expect(repo.lastCompleteEndAddress, 'Phnom Penh');
      expect(repo.lastCompleteDistance, 3.4);
    });

    test('on API error: generic error, no advance', () async {
      final controller = _controller(repo, TripStage.inProgress);
      repo.completeResult = Result.err(_apiError);

      await callComplete(controller);

      expect(controller.state.stage.value, TripStage.inProgress);
      expect(controller.state.lastError.value, TripActionError.generic);
    });

    test('ok with null data: generic error, no advance, no TripCompleted',
        () async {
      final controller = _controller(repo, TripStage.inProgress);
      repo.completeResult =
          Result.ok(complete_model.CompleteDriverModel(data: null));

      await callComplete(controller);

      expect(controller.state.stage.value, TripStage.inProgress);
      expect(controller.state.lastError.value, TripActionError.generic);
      expect(controller.state.lastResult.value, isNull);
    });

    test(
        'a stage other than inProgress fails loudly instead of silently drifting',
        () async {
      final controller = _controller(repo, TripStage.waitingAtPickup);
      repo.completeResult = Result.ok(complete_model.CompleteDriverModel(
          data: complete_model.Data(id: 42)));

      expect(() => callComplete(controller),
          throwsA(isA<InvalidTripTransition>()));
    });

    test('a concurrent call is a no-op while one is in flight', () async {
      final controller = _controller(repo, TripStage.inProgress);
      repo.completeResult = Result.ok(complete_model.CompleteDriverModel(
          data: complete_model.Data(id: 42)));

      final first = callComplete(controller);
      final second = callComplete(controller);
      await Future.wait([first, second]);

      expect(repo.completeCalls, 1);
    });
  });
}
