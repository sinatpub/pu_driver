import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/contracts/booking_status.dart';
import 'package:tara_driver_application/core/network/api_client.dart';
import 'package:tara_driver_application/core/network/api_exception.dart';
import 'package:tara_driver_application/core/network/result.dart';
import 'package:tara_driver_application/data/models/vehical_model.dart';
import 'package:tara_driver_application/mock/mock_backend.dart';
import 'package:tara_driver_application/mock/mock_fixtures.dart';
import 'package:tara_driver_application/mock/mock_geo.dart';
import 'package:tara_driver_application/mock/mock_http_interceptor.dart';
import 'package:tara_driver_application/mock/mock_mode.dart';
import 'package:tara_driver_application/mock/mock_timings.dart';
import 'package:tara_driver_application/presentation/screens/announcement/data/datasource/notification_datasource.dart';
import 'package:tara_driver_application/presentation/screens/announcement/data/repository/notification_repository.dart';
import 'package:tara_driver_application/presentation/screens/booking/data/datasource/trip_datasource.dart';
import 'package:tara_driver_application/presentation/screens/booking/data/new_ride_payload_parser.dart';
import 'package:tara_driver_application/presentation/screens/booking/data/repository/trip_repository.dart';
import 'package:tara_driver_application/presentation/screens/booking/domain/trip_state_machine.dart';
import 'package:tara_driver_application/presentation/screens/booking/logic.dart';
import 'package:tara_driver_application/presentation/screens/booking/state.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/data/datasource/payment_datasource.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/data/repository/payment_repository.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/logic.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/state.dart';
import 'package:tara_driver_application/presentation/screens/history/data/datasource/history_datasource.dart';
import 'package:tara_driver_application/presentation/screens/history/data/repository/history_repository.dart';
import 'package:tara_driver_application/presentation/screens/home/data/datasource/home_datasource.dart';
import 'package:tara_driver_application/presentation/screens/home/data/datasource/version_check_datasource.dart';
import 'package:tara_driver_application/presentation/screens/home/data/repository/home_repository.dart';
import 'package:tara_driver_application/presentation/screens/home/data/repository/version_check_repository.dart';
import 'package:tara_driver_application/presentation/screens/login/data/datasource/auth_datasource.dart';
import 'package:tara_driver_application/presentation/screens/login/data/repository/auth_repository.dart';
import 'package:tara_driver_application/presentation/screens/profile/data/datasource/profile_datasource.dart';
import 'package:tara_driver_application/presentation/screens/profile/data/repository/profile_repository.dart';
import 'package:tara_driver_application/presentation/screens/wallet/data/datasource/wallet_datasource.dart';
import 'package:tara_driver_application/presentation/screens/wallet/data/repository/wallet_repository.dart';

/// The whole driver flow, through the app's **real** datasources,
/// repositories, models and trip controller — the only substitution is the
/// mock interceptor on the Dio client, exactly as in a `USE_MOCK_DATA` build.
void main() {
  late DateTime now;
  late MockSettings settings;
  late MockBackend backend;
  late ApiClient api;

  T value<T>(Result<T> result) => result.when(
        ok: (v) => v,
        err: (e) => fail('expected success, got ${e.type}: ${e.message}'),
      );

  ApiException error<T>(Result<T> result) => result.when(
        ok: (v) => fail('expected an error, got $v'),
        err: (e) => e,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(
        {'session_token': MockData.token});
    now = DateTime(2026, 9, 17, 9, 0, 0);
    settings = const MockSettings(dispatch: MockDispatch.manual);
    backend = MockBackend(
      clock: () => now,
      settings: () => settings,
      scale: (d) => d,
      persist: false,
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.tara-taxi.com'))
      ..interceptors.add(MockHttpInterceptor(
        backend: backend,
        isActive: () => true,
        latency: (_) => Duration.zero,
      ));
    api = ApiClient(dio: dio);
  });

  tearDown(() => backend.dispose());

  test('complete driver flow: login → online → request → trip → payment',
      () async {
    // ---- Login ------------------------------------------------------------
    final auth = AuthRepository(AuthDatasource(apiClient: api));
    final phone = value(await auth.loginPhone('012345678'));
    expect(phone.status, isTrue);
    expect(phone.data.seconde, 60);
    final login =
        value(await auth.verifyOtp(phone: '012345678', otpCode: '1234'));
    expect(login.data?.token, MockData.token);
    expect(login.data?.driver?.name, 'Dara Sok');

    // ---- Home: profile, version, vehicle types, go online ------------------
    final profile = value(
        await ProfileRepository(ProfileDatasource(apiClient: api))
            .getProfile());
    expect(profile.data?.vehicle?.plateNumber, '2AB-1234');
    final version = value(
        await VersionCheckRepository(VersionCheckDatasource(apiClient: api))
            .getCurrentVersion());
    expect(version.data?.versionAndroid, '1.1.9');
    final vehicles = VehicalTypeEntities.fromJson((await backend.handle(
            const MockRequest(method: 'GET', path: '/taxi/get-type-vehicle')))
        .data as Map<String, dynamic>);
    expect(vehicles.data.map((v) => v.name), contains('Classic Car'));

    final home = HomeRepository(HomeDatasource(apiClient: api));
    final idle = value(await home.getCurrentDriveInfo());
    expect(idle.data?.status, isNull, reason: 'no ride → no redirect');
    expect(idle.data?.driver?.status, MockApproval.approved.code);
    expect(value(await home.setStatus(1)).data?.isAvailable, 1);
    expect(value(await home.getStatus()).data?.isAvailable, 1);

    // ---- A ride request arrives over the (mock) socket --------------------
    final events = <MockSocketEvent>[];
    final sub = backend.socketEvents.listen(events.add);
    backend.sendRideRequestNow();
    await pumpEventQueue();
    expect(events.single.name, 'newRide');
    final args = parseNewRideArgs(events.single.data);
    expect(args.bookingId, greaterThanOrEqualTo(MockData.firstRideId));
    expect(args.namePassanger, 'Sreymom Chan');
    expect(args.desLatPassenger, MockPlaces.destination.latitude);
    expect(args.timeOut, MockTimings.rideRequestTimeoutSeconds);

    // ---- The trip, driven by the real BookingLogic -------------------------
    final trip = BookingLogic(
      TripRepository(TripDatasource(apiClient: api)),
      rideId: args.bookingId,
      initialStage: TripStageProcessStep.fromProcessStep(args.processStepBook),
    );
    expect(trip.state.stage.value, TripStage.requestReceived);

    await trip.accept();
    expect(trip.state.lastError.value, isNull);
    expect(trip.state.stage.value, TripStage.enRouteToPickup);
    final accepted = trip.state.lastResult.value as TripAccepted;
    expect(accepted.confirmed.data?.driver?.id, MockData.driverId);
    expect(accepted.confirmed.data?.passenger?.id, MockData.passengerId);

    // The simulated car drives toward the pickup.
    final startFix = backend.driverFix().point;
    now = now.add(MockTimings.driveToPickup ~/ 2);
    final midFix = backend.driverFix().point;
    expect(distanceMeters(midFix, MockPlaces.pickup.latLng),
        lessThan(distanceMeters(startFix, MockPlaces.pickup.latLng)));
    now = now.add(MockTimings.driveToPickup);
    expect(distanceMeters(backend.driverFix().point, MockPlaces.pickup.latLng),
        lessThan(1));

    // Killing the app here resumes through get-current-drive-info.
    final resumed = value(await home.getCurrentDriveInfo()).data!;
    expect(resumed.status, BookingStatus.accepted);
    expect(double.parse(resumed.startLatitude.toString()),
        closeTo(MockPlaces.pickup.latitude, 1e-6));
    expect(double.parse(resumed.passenger!.lastLocation!.latitude.toString()),
        isNotNull);
    expect(resumed.driver!.vehicle!.typeVehicleId, MockData.vehicleTypeId);

    await trip.arrive();
    expect(trip.state.stage.value, TripStage.waitingAtPickup);
    await trip.start();
    expect(trip.state.stage.value, TripStage.inProgress);

    now = now.add(MockTimings.tripInProgress ~/ 2);
    final halfway = backend.driverFix();
    expect(halfway.speedMps, greaterThan(0));
    now = now.add(MockTimings.tripInProgress);

    await trip.complete(
      endLatitude: MockPlaces.destination.latitude,
      endLongitude: MockPlaces.destination.longitude,
      endAddress: MockPlaces.destination.name,
      distance: 10,
    );
    expect(trip.state.lastError.value, isNull);
    expect(trip.state.stage.value, TripStage.completing);
    final completed = (trip.state.lastResult.value as TripCompleted).completed;
    final payment = completed.data!.payment!;
    expect(double.parse(payment.amount!), greaterThan(MockData.minimumFare));
    expect(payment.distance, endsWith(' km'));
    expect(
        double.parse(payment.distance!.split(' ').first),
        closeTo(
            pathLengthMeters(mockRoute(
                    MockPlaces.pickup.latLng, MockPlaces.destination.latLng)) /
                1000,
            0.01));
    expect(payment.paymentMethod, 'Cash');
    // The receipt's own formatters accept what the mock sends.
    expect(convertTimeString(payment.duration!), contains('m'));
    expect(() => formatDateTime(payment.createdAt!), returnsNormally);

    // Killing the app on the receipt resumes to the fee screen (status 6).
    final pending = value(await home.getCurrentDriveInfo()).data!;
    expect(pending.status, BookingStatus.pendingPayment);
    expect(pending.payment?.amount, payment.amount);

    // ---- Payment, through the real CalculateFeeLogic -----------------------
    final fee = CalculateFeeLogic(
      PaymentRepository(PaymentDatasource(apiClient: api)),
      routFrom: 'FromDropBooking',
      dataComplete: completed,
      dataDriverInfo: null,
      startAddress: MockPlaces.pickup.name,
      endAddress: MockPlaces.destination.name,
    );
    await fee.acceptPayment();
    expect(fee.state.status.value, PaymentStatus.success);

    // ---- Back home: no ride, history and wallet reflect the trip ----------
    expect(value(await home.getCurrentDriveInfo()).data?.status, isNull);
    final history = value(
        await HistoryRepository(HistoryDatasource(apiClient: api))
            .getHistory(page: 1, status: BookingStatus.completed));
    expect(history.data!.first.id, args.bookingId);
    expect(history.data!.first.statusName?.toUpperCase(), 'COMPLETED');
    final cancelled = value(
        await HistoryRepository(HistoryDatasource(apiClient: api))
            .getHistory(page: 1, status: BookingStatus.cancel));
    expect(cancelled.data, isNotEmpty);
    expect(cancelled.data!.every((r) => r.payment != null), isTrue,
        reason: 'the history card reads payment! on every row');
    final wallet = value(
        await WalletRepository(WalletDatasource(apiClient: api)).getWallet());
    expect(wallet.data?.transactions?.last.typeName, 'Commission');
    final news = value(
        await NotificationRepository(NotificationDatasource(apiClient: api))
            .getAnnouncements(page: 1));
    expect(news.data, hasLength(3));

    await sub.cancel();
  });

  group('scenarios', () {
    Future<BookingLogic> pendingRequest() async {
      final events = <MockSocketEvent>[];
      final sub = backend.socketEvents.listen(events.add);
      backend.sendRideRequestNow();
      await pumpEventQueue();
      await sub.cancel();
      final args = parseNewRideArgs(events.single.data);
      return BookingLogic(TripRepository(TripDatasource(apiClient: api)),
          rideId: args.bookingId, initialStage: TripStage.requestReceived);
    }

    test('RIDE_ALREADY_TAKEN shows the already-accepted error', () async {
      settings = settings.copyWith(scenario: MockScenario.rideAlreadyTaken);
      final trip = await pendingRequest();
      await trip.accept();
      expect(trip.state.lastError.value, TripActionError.rideAlreadyAccepted);
      expect(trip.state.stage.value, TripStage.requestReceived);
    });

    test('BOOKING_FAILED shows confirm-failed and can be retried', () async {
      settings = settings.copyWith(scenario: MockScenario.bookingFailed);
      final trip = await pendingRequest();
      await trip.accept();
      expect(trip.state.lastError.value, TripActionError.confirmFailed);
      settings = settings.copyWith(scenario: MockScenario.normalFlow);
      await trip.accept();
      expect(trip.state.stage.value, TripStage.enRouteToPickup);
    });

    test('PASSENGER_CANCELLED pushes a cancel after accept', () async {
      backend.dispose();
      settings = settings.copyWith(scenario: MockScenario.passengerCancelled);
      backend = MockBackend(
        clock: () => now,
        settings: () => settings,
        scale: (_) => Duration.zero,
        persist: false,
      );
      final dio = Dio()
        ..interceptors.add(MockHttpInterceptor(
            backend: backend,
            isActive: () => true,
            latency: (_) => Duration.zero));
      api = ApiClient(dio: dio);
      final trip = await pendingRequest();
      final events = <MockSocketEvent>[];
      final sub = backend.socketEvents.listen(events.add);
      await trip.accept();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(events.map((e) => e.name), contains('onPassengerCancelDrive'));
      expect(backend.ride, isNull);
      await sub.cancel();
    });

    test('PAYMENT_FAILED leaves the fee screen in its error state', () async {
      final trip = await pendingRequest();
      await trip.accept();
      await trip.arrive();
      await trip.start();
      await trip.complete(
          endLatitude: 0, endLongitude: 0, endAddress: '', distance: 0);
      final completed =
          (trip.state.lastResult.value as TripCompleted).completed;
      settings = settings.copyWith(scenario: MockScenario.paymentFailed);
      final fee = CalculateFeeLogic(
        PaymentRepository(PaymentDatasource(apiClient: api)),
        routFrom: 'FromDropBooking',
        dataComplete: completed,
        dataDriverInfo: null,
        startAddress: '',
        endAddress: '',
      );
      await fee.acceptPayment();
      expect(fee.state.status.value, PaymentStatus.error);
      // Retry once the backend recovers.
      settings = settings.copyWith(scenario: MockScenario.normalFlow);
      await fee.acceptPayment();
      expect(fee.state.status.value, PaymentStatus.success);
    });

    test('NETWORK_ERROR is classified as a connection failure', () async {
      settings = settings.copyWith(scenario: MockScenario.networkError);
      final e = error(
          await HomeRepository(HomeDatasource(apiClient: api)).getStatus());
      expect(e.type, ApiErrorType.connection);
    });

    test('SESSION_EXPIRED 401s authenticated calls only', () async {
      settings = settings.copyWith(scenario: MockScenario.sessionExpired);
      final reply = await backend.handle(const MockRequest(
          method: 'GET',
          path: '/taxi-driver/check-status',
          authenticated: true));
      expect(reply.statusCode, 401);
      final login = await backend.handle(
          const MockRequest(method: 'POST', path: '/taxi-driver/login-phone'));
      expect(login.statusCode, 200);
    });

    test('OTP 9999 is rejected', () async {
      final auth = AuthRepository(AuthDatasource(apiClient: api));
      final result =
          value(await auth.verifyOtp(phone: '012345678', otpCode: '9999'));
      expect(result.status, isFalse);
      expect(result.data, isNull);
    });

    test('a pending driver cannot go online and is gated', () async {
      settings = settings.copyWith(approval: MockApproval.pending);
      final home = HomeRepository(HomeDatasource(apiClient: api));
      expect(value(await home.setStatus(1)).data?.isAvailable, 0);
      expect(value(await home.getCurrentDriveInfo()).data?.driver?.status,
          MockApproval.pending.code);
    });

    test('a ride without a destination has no end point until completed',
        () async {
      settings = settings.copyWith(rideHasDestination: false);
      final events = <MockSocketEvent>[];
      final sub = backend.socketEvents.listen(events.add);
      backend.sendRideRequestNow();
      await pumpEventQueue();
      await sub.cancel();
      expect(parseNewRideArgs(events.single.data).desLatPassenger, isNull);
    });

    test('auto dispatch sends a request after going online', () async {
      backend.dispose();
      settings = const MockSettings();
      backend = MockBackend(
        clock: () => now,
        settings: () => settings,
        scale: (_) => const Duration(milliseconds: 1),
        persist: false,
      );
      final events = <MockSocketEvent>[];
      final sub = backend.socketEvents.listen(events.add);
      await backend.handle(const MockRequest(
          method: 'POST',
          path: '/taxi-driver/set-status',
          body: {'status': 1}));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(events.map((e) => e.name), ['newRide']);
      await sub.cancel();
    });

    test('NO_RIDE_REQUEST never dispatches automatically', () async {
      backend.dispose();
      settings = const MockSettings(scenario: MockScenario.noRideRequest);
      backend = MockBackend(
        clock: () => now,
        settings: () => settings,
        scale: (_) => const Duration(milliseconds: 1),
        persist: false,
      );
      final events = <MockSocketEvent>[];
      final sub = backend.socketEvents.listen(events.add);
      await backend.handle(const MockRequest(
          method: 'POST',
          path: '/taxi-driver/set-status',
          body: {'status': 1}));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(events, isEmpty);
      await sub.cancel();
    });
  });

  test('state survives an app restart, dropping an unanswered request',
      () async {
    backend.dispose();
    backend = MockBackend(
        clock: () => now, settings: () => settings, scale: (d) => d);
    await backend.handle(const MockRequest(
        method: 'POST', path: '/taxi-driver/set-status', body: {'status': 1}));
    backend.sendRideRequestNow();
    final id = backend.ride!.id;
    await backend.handle(MockRequest(
        method: 'POST',
        path: '/taxi-driver/confirm-drive-request',
        body: {'ride_id': id}));
    await pumpEventQueue();

    final restarted = MockBackend(
        clock: () => now, settings: () => settings, scale: (d) => d);
    await restarted.restore();
    expect(restarted.online, isTrue);
    expect(restarted.ride?.id, id);
    expect(restarted.ride?.status, BookingStatus.accepted);

    // A request nobody answered does not come back.
    restarted.resetTrip();
    restarted.sendRideRequestNow();
    await pumpEventQueue();
    final again = MockBackend(
        clock: () => now, settings: () => settings, scale: (d) => d);
    await again.restore();
    expect(again.ride, isNull);

    restarted.dispose();
    again.dispose();
  });

  test('FormData bodies reach the backend as fields', () {
    final body = MockHttpInterceptor.bodyToMap(
        FormData.fromMap({'ride_id': 990001, 'distance': 1.5}));
    expect(body, {'ride_id': '990001', 'distance': '1.5'});
  });

  test('the mock route follows Russian Federation Blvd to the airport', () {
    final route =
        mockRoute(MockPlaces.pickup.latLng, MockPlaces.destination.latLng);
    final km = pathLengthMeters(route) / 1000;
    expect(km, inInclusiveRange(8, 12));
    expect(pointAlong(route, 0).point, MockPlaces.pickup.latLng);
    expect(pointAlong(route, 1).point, MockPlaces.destination.latLng);
    expect(MockPlaces.nameNear(const LatLng(11.5697, 104.9211)),
        MockPlaces.pickup.name);
  });

  group('invite and rewards (DD-45)', () {
    late MockBackend backend;

    setUp(() {
      backend = MockBackend(
        clock: () => DateTime(2026, 10, 1, 12),
        settings: () => const MockSettings(),
        scale: (_) => Duration.zero,
        persist: false,
      );
    });
    tearDown(() => backend.dispose());

    test('the referral payload adds up', () async {
      final response = await backend.handle(const MockRequest(
          method: 'GET', path: '/taxi-driver/referral', authenticated: true));
      final data = (response.data as Map)['data'] as Map<String, dynamic>;
      final rewards = (data['rewards'] as List).cast<Map<String, dynamic>>();
      final invitees = (data['invitees'] as List).cast<Map<String, dynamic>>();

      expect(data['code'], MockData.inviteCode);
      expect('${data['link']}', endsWith(MockData.inviteCode));
      // What each person earned the driver is the sum of their rewards.
      for (final invitee in invitees) {
        final sum = rewards
            .where((r) => r['invitee_id'] == invitee['id'])
            .fold<int>(0, (total, r) => total + (r['amount'] as int));
        expect(invitee['earned'], sum, reason: '${invitee['name']}');
      }
      // A driver reward is 1% of the top-up it came from.
      for (final r in rewards.where((r) => r['invitee_role'] == 'driver')) {
        expect(r['amount'], (r['base_amount'] as int) ~/ 100);
      }
    });

    test('rewards are paid into the wallet (DD-46)', () async {
      Future<Map<String, dynamic>> data(String path) async =>
          ((await backend.handle(
                  MockRequest(method: 'GET', path: path, authenticated: true)))
              .data as Map)['data'] as Map<String, dynamic>;

      final rewards = ((await data('/taxi-driver/referral'))['rewards'] as List)
          .cast<Map<String, dynamic>>();
      final wallet = await data('/taxi-driver/wallet');
      final transactions =
          (wallet['transactions'] as List).cast<Map<String, dynamic>>();
      final paid = transactions
          .where((tx) => tx['type_name'] == 'Referral Reward')
          .toList();

      // One wallet transaction per reward, for the same amount and time.
      expect(paid.map((tx) => tx['amount']), rewards.map((r) => r['amount']));
      expect(paid.map((tx) => tx['created_at']),
          rewards.map((r) => r['created_at']));
      // And the balance is the seeded 85,400 riel plus every reward.
      expect(
        wallet['balance'],
        85400 + rewards.fold<int>(0, (sum, r) => sum + (r['amount'] as int)),
      );
    });

    test('check-code knows its inviters and nobody else', () async {
      Future<Map> check(String code) async =>
          ((await backend.handle(MockRequest(
                  method: 'GET',
                  path: '/taxi-driver/referral/check-code',
                  query: {'code': code})))
              .data as Map)['data'] as Map;

      expect(await check('sokha88'),
          {'valid': true, 'inviter_name': 'Sokha Vann'});
      expect((await check('NOPE99'))['valid'], isFalse);
    });

    test('OTP 1111 is a new driver: no token, no driver', () async {
      final response = await backend.handle(const MockRequest(
          method: 'POST',
          path: '/taxi-driver/verify-phone-otp',
          body: {'phone': '012345678', 'otp_code': '1111'}));
      final body = response.data as Map;

      expect(body['status'], isTrue);
      expect((body['data'] as Map)['token'], isNull);
      expect((body['data'] as Map)['driver'], isNull);
    });
  });
}
