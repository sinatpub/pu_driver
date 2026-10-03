import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tara_driver_application/core/contracts/booking_status.dart';
import 'package:tara_driver_application/core/utils/fare_estimate.dart';
import 'package:tara_driver_application/mock/mock_fixtures.dart';
import 'package:tara_driver_application/mock/mock_geo.dart';
import 'package:tara_driver_application/mock/mock_mode.dart';
import 'package:tara_driver_application/mock/mock_timings.dart';

/// A request as the mock backend sees it — transport-neutral, so the backend
/// is testable without Dio.
class MockRequest {
  const MockRequest({
    required this.method,
    required this.path,
    this.query = const {},
    this.body = const {},
    this.authenticated = false,
  });

  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Map<String, dynamic> body;

  /// Whether the request carried an `Authorization` header.
  final bool authenticated;
}

class MockResponse {
  const MockResponse(this.statusCode, this.data);
  final int statusCode;
  final Object? data;
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Thrown for `NETWORK_ERROR`; the interceptor turns it into the same
/// `DioException` a dropped connection produces.
class MockConnectionFailure implements Exception {
  const MockConnectionFailure();
}

/// A server → driver socket push (`newRide`, `onPassengerCancelDrive`).
class MockSocketEvent {
  const MockSocketEvent(this.name, this.data);
  final String name;
  final Map<String, dynamic> data;
}

/// One mock ride. `status` uses the real server codes from
/// `core/contracts/booking_status.dart`.
class MockRide {
  MockRide({
    required this.id,
    required this.status,
    required this.driverStart,
    required this.destination,
    required this.createdAt,
    required this.paymentMethod,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.endPoint,
    this.distanceKm,
    this.fare,
  });

  final int id;
  int status;
  final LatLng driverStart;

  /// Null for a no-destination (metered) ride.
  final LatLng? destination;
  final DateTime createdAt;
  final String paymentMethod;
  DateTime? acceptedAt;
  DateTime? arrivedAt;
  DateTime? startedAt;
  DateTime? completedAt;
  LatLng? endPoint;
  double? distanceKm;
  int? fare;

  LatLng get pickup => MockPlaces.pickup.latLng;

  /// Where the simulated car drives once the trip starts. A metered ride has
  /// no destination the app knows about, but the car still goes somewhere.
  LatLng get driveTarget => destination ?? MockPlaces.destination.latLng;

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'driverStart': _latLngToJson(driverStart),
        'destination': destination == null ? null : _latLngToJson(destination!),
        'createdAt': createdAt.toIso8601String(),
        'paymentMethod': paymentMethod,
        'acceptedAt': acceptedAt?.toIso8601String(),
        'arrivedAt': arrivedAt?.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'endPoint': endPoint == null ? null : _latLngToJson(endPoint!),
        'distanceKm': distanceKm,
        'fare': fare,
      };

  factory MockRide.fromJson(Map<String, dynamic> json) => MockRide(
        id: json['id'] as int,
        status: json['status'] as int,
        driverStart: _latLngFromJson(json['driverStart'])!,
        destination: _latLngFromJson(json['destination']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        paymentMethod: json['paymentMethod'] as String,
        acceptedAt: _dateOrNull(json['acceptedAt']),
        arrivedAt: _dateOrNull(json['arrivedAt']),
        startedAt: _dateOrNull(json['startedAt']),
        completedAt: _dateOrNull(json['completedAt']),
        endPoint: _latLngFromJson(json['endPoint']),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        fare: json['fare'] as int?,
      );
}

Map<String, double> _latLngToJson(LatLng p) =>
    {'lat': p.latitude, 'lng': p.longitude};

LatLng? _latLngFromJson(Object? json) {
  if (json is! Map) return null;
  return LatLng(
      (json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
}

DateTime? _dateOrNull(Object? v) => v is String ? DateTime.parse(v) : null;

/// The fake server. Owns everything the real backend would: the driver's
/// online flag, the ride and its lifecycle, dispatching requests, the
/// passenger's behaviour, history and wallet. Its state survives an app
/// restart (SharedPreferences), which is what lets "kill the app mid-trip"
/// be tested through the app's real resume path (`get-current-drive-info`).
class MockBackend {
  MockBackend({
    DateTime Function()? clock,
    MockSettings Function()? settings,
    Duration Function(Duration)? scale,
    this.persist = true,
  })  : _now = clock ?? DateTime.now,
        _settings = settings ?? (() => MockMode.settings),
        _scale = scale ?? MockMode.scaled {
    _seedHistoryAndWallet();
  }

  static final MockBackend instance = MockBackend();

  static const _stateKey = 'qa_mock.backend_state';

  final DateTime Function() _now;
  final MockSettings Function() _settings;
  final Duration Function(Duration) _scale;
  final bool persist;

  final StreamController<MockSocketEvent> _socket =
      StreamController<MockSocketEvent>.broadcast();

  /// Server → driver socket pushes. `DriverSocketService` listens here in
  /// mock mode instead of on a real Socket.IO connection.
  Stream<MockSocketEvent> get socketEvents => _socket.stream;

  /// Bumped on every state change, for the dev panel's live summary.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  bool online = false;
  MockRide? ride;
  LatLng parkedAt = MockPlaces.driverStart.latLng;
  int _nextRideId = MockData.firstRideId;
  int _walletBalance = 0;
  final List<Map<String, dynamic>> _transactions = [];
  final List<Map<String, dynamic>> _history = [];

  /// DD-48: rewards the driver moved into the wallet balance, and the
  /// request ids that did it (request id → amount moved).
  final List<Map<String, dynamic>> _rewardTransfers = [];
  final Map<String, int> _transferRequests = {};

  Timer? _dispatchTimer;
  Timer? _expiryTimer;
  Timer? _passengerCancelTimer;

  MockSettings get settings => _settings();

  // ---------------------------------------------------------------------
  // Request handling
  // ---------------------------------------------------------------------

  Future<MockResponse> handle(MockRequest request) async {
    final scenario = settings.scenario;
    if (scenario == MockScenario.networkError) {
      throw const MockConnectionFailure();
    }
    if (scenario == MockScenario.sessionExpired && request.authenticated) {
      return const MockResponse(
          401, {'status': false, 'message': 'Unauthenticated.'});
    }

    final path = request.path;
    final announcementDetail =
        RegExp(r'/taxi-driver/announcement/(\d+)$').firstMatch(path);

    if (path.endsWith('/taxi-driver/login-phone')) return _loginPhone();
    if (path.endsWith('/taxi-driver/verify-phone-otp')) {
      return _verifyOtp(request);
    }
    if (path.endsWith('/taxi-driver/register')) return _ok(_authPayload());
    if (path.endsWith('/taxi/login')) return _debugLogin();
    if (path.endsWith('/taxi-driver/push-device-token')) {
      return _ok({'status': true, 'message': 'Device token saved'});
    }
    if (path.endsWith('/taxi-driver/update-driver-location')) {
      return _updateLocation(request);
    }
    if (path.endsWith('/taxi-driver/check-status')) {
      return _ok(_statusPayload());
    }
    if (path.endsWith('/taxi-driver/set-status')) return _setStatus(request);
    if (path.endsWith('/taxi-driver/get-current-drive-info')) {
      return _currentDrive();
    }
    if (path.endsWith('/taxi-driver/confirm-drive-request')) {
      return _confirm(request);
    }
    if (path.endsWith('/taxi-driver/cancel-drive')) return _cancel(request);
    if (path.endsWith('/taxi-driver/drive-arrive')) return _arrive(request);
    if (path.endsWith('/taxi-driver/start-drive')) return _start(request);
    if (path.endsWith('/taxi-driver/complete-drive')) return _complete(request);
    if (path.endsWith('/taxi-driver/accept-payment')) {
      return _acceptPayment(request);
    }
    if (path.endsWith('/taxi-driver/history-drive-info')) {
      return _historyPage(request);
    }
    if (path.endsWith('/taxi-driver/wallet')) return _wallet();
    if (path.endsWith('/taxi-driver/referral')) return _referral();
    if (path.endsWith('/taxi-driver/referral/transfer')) {
      return _transferRewards(request);
    }
    if (path.endsWith('/taxi-driver/referral/check-code')) {
      return _checkInviteCode(request);
    }
    if (path.endsWith('/taxi-driver/announcements')) {
      return _announcements(request);
    }
    if (announcementDetail != null) {
      return _announcement(int.parse(announcementDetail.group(1)!));
    }
    if (path.endsWith('/taxi/get-type-vehicle')) {
      return _ok({
        'status': true,
        'message': 'Success',
        'data': MockData.vehicleTypes(),
        'color': MockData.vehicleColors(),
      });
    }
    if (path.contains('/taxi/get-current-app-version')) {
      return _ok(MockData.version());
    }
    if (path.endsWith('/taxi-driver/get-profile')) {
      return _ok({'status': true, 'message': 'Success', 'data': _driverJson()});
    }

    debugPrint('[MockBackend] no handler for ${request.method} $path');
    return MockResponse(404, {
      'status': false,
      'message': 'Mock backend has no handler for ${request.method} $path',
    });
  }

  MockResponse _ok(Object data) => MockResponse(200, data);

  MockResponse _invalidState(String action) => MockResponse(422, {
        'status': false,
        'message': 'Cannot $action: ride is '
            '${ride == null ? 'not active' : _statusName(ride!.status)}',
      });

  // ---- Auth -------------------------------------------------------------

  MockResponse _loginPhone() => _ok({
        'status': true,
        'message': 'OTP code has been sent to your phone',
        'data': {'seconde': 60},
      });

  /// Any code signs in, except `9999`, which is rejected — so the OTP error
  /// state is testable too.
  MockResponse _verifyOtp(MockRequest request) {
    if (request.body['otp_code']?.toString() == '9999') {
      return _ok({'status': false, 'message': 'OTP not correct', 'data': null});
    }
    // A phone number the server has not seen: no driver and no token, which
    // sends the app to the sign-up form.
    if (request.body['otp_code']?.toString() == '1111') {
      return _ok({
        'status': true,
        'message': 'Driver not registered',
        'data': {'token': null, 'driver': null},
      });
    }
    return _ok(_authPayload());
  }

  Map<String, dynamic> _authPayload() => {
        'status': true,
        'message': 'Login successful',
        'data': {'token': MockData.token, 'driver': _driverJson()},
      };

  MockResponse _debugLogin() => _ok({
        'status': true,
        'data': {
          'token': MockData.token,
          'user': {'id': MockData.driverId, 'name': 'Dara Sok', 'role_id': 2},
        },
      });

  // ---- Driver status & location ------------------------------------------

  Map<String, dynamic> _statusPayload() {
    final now = MockData.timestamp(_now());
    return {
      'status': true,
      'message': 'Success',
      'data': {
        'id': 12,
        'user_id': MockData.driverId,
        'vehicle_id': 88,
        'license_number': 'PP-123456',
        'rating': 5,
        'is_available': online ? 1 : 0,
        'created_at': '2026-01-15 09:30:00',
        'updated_at': now,
      },
    };
  }

  MockResponse _setStatus(MockRequest request) {
    final wantsOnline = request.body['status']?.toString() == '1';
    if (wantsOnline && settings.approval != MockApproval.approved) {
      online = false;
      return _ok({
        ..._statusPayload(),
        'status': false,
        'message': 'Driver is not approved'
      });
    }
    online = wantsOnline;
    if (online) {
      _scheduleDispatch();
    } else {
      _dispatchTimer?.cancel();
      if (ride?.status == BookingStatus.request) _clearRide();
    }
    _changed();
    return _ok(_statusPayload());
  }

  MockResponse _updateLocation(MockRequest request) {
    final now = MockData.timestamp(_now());
    return _ok({
      'status': true,
      'message': 'Location updated',
      'data': {
        'id': 1,
        'user_id': MockData.driverId,
        'latitude': request.body['latitude']?.toString(),
        'longitude': request.body['longitude']?.toString(),
        'created_at': now,
        'updated_at': now,
      },
    });
  }

  // ---- Trip lifecycle ------------------------------------------------------

  /// A ride the driver has accepted and not yet been paid for — what the
  /// real endpoint returns so the app can resume it after a restart.
  static const _resumableStatuses = {
    BookingStatus.accepted,
    BookingStatus.arrived,
    BookingStatus.startRide,
    BookingStatus.pendingPayment,
  };

  MockResponse _currentDrive() {
    final current = ride;
    if (current != null && _resumableStatuses.contains(current.status)) {
      return _ok(
          {'status': true, 'message': 'Success', 'data': _rideJson(current)});
    }
    // No active ride still carries `driver` — its `status` is the approval
    // gate (D-03) — and a null ride `status`, which HomeLogic ignores.
    return _ok({
      'status': true,
      'message': 'No active ride',
      'data': {'id': null, 'status': null, 'driver': _driverJson()},
    });
  }

  bool _isCurrentRide(MockRequest request, int status) {
    final id = int.tryParse(request.body['ride_id']?.toString() ?? '');
    return ride != null && ride!.id == id && ride!.status == status;
  }

  MockResponse _confirm(MockRequest request) {
    if (!_isCurrentRide(request, BookingStatus.request)) {
      return _ok(
          {'status': false, 'message': 'RIDE_NOT_AVAILABLE', 'data': null});
    }
    switch (settings.scenario) {
      case MockScenario.rideAlreadyTaken:
        _clearRide();
        _scheduleDispatch();
        _changed();
        return _ok({
          'status': false,
          'message': 'RIDE_ALREADY_ACCEPTED',
          'data': null
        });
      case MockScenario.bookingFailed:
        // The request stays open, so "try again" can be exercised until the
        // countdown runs out.
        return _ok({
          'status': false,
          'message': 'CAN_NOT_CONFIRM_BOOKING',
          'data': null
        });
      default:
        break;
    }
    final current = ride!
      ..status = BookingStatus.accepted
      ..acceptedAt = _now();
    _expiryTimer?.cancel();
    if (settings.scenario == MockScenario.passengerCancelled) {
      _passengerCancelTimer = Timer(
          _scale(MockTimings.passengerCancelsAfterAccept), passengerCancelNow);
    }
    _changed();
    return _ok({
      'status': true,
      'message': 'Ride accepted',
      'data': _rideJson(current)
    });
  }

  MockResponse _cancel(MockRequest request) {
    final id = int.tryParse(request.body['ride_id']?.toString() ?? '');
    if (ride == null || ride!.id != id) return _invalidState('cancel');
    _archive(ride!..status = BookingStatus.cancel);
    _clearRide();
    _scheduleDispatch();
    _changed();
    return _ok({'status': true, 'message': 'Ride cancelled'});
  }

  MockResponse _arrive(MockRequest request) {
    if (!_isCurrentRide(request, BookingStatus.accepted)) {
      return _invalidState('arrive');
    }
    final current = ride!
      ..status = BookingStatus.arrived
      ..arrivedAt = _now();
    _passengerCancelTimer?.cancel();
    _changed();
    return _ok({
      'status': true,
      'message': 'Driver arrived',
      'data': _rideJson(current)
    });
  }

  MockResponse _start(MockRequest request) {
    if (!_isCurrentRide(request, BookingStatus.arrived)) {
      return _invalidState('start');
    }
    final current = ride!
      ..status = BookingStatus.startRide
      ..startedAt = _now();
    _changed();
    return _ok({
      'status': true,
      'message': 'Ride started',
      'data': _rideJson(current)
    });
  }

  MockResponse _complete(MockRequest request) {
    if (!_isCurrentRide(request, BookingStatus.startRide)) {
      return _invalidState('complete');
    }
    final current = ride!;
    final position = driverFix().point;
    final route = mockRoute(current.pickup, current.driveTarget);
    final travelledKm = pathLengthMeters(route) / 1000 * _tripProgress(current);
    final distanceKm = travelledKm < 0.4 ? 0.4 : travelledKm;

    final endLat =
        double.tryParse(request.body['end_latitude']?.toString() ?? '');
    final endLng =
        double.tryParse(request.body['end_longitude']?.toString() ?? '');
    current
      ..status = BookingStatus.pendingPayment
      ..completedAt = _now()
      ..endPoint = (endLat != null && endLng != null && endLat != 0)
          ? LatLng(endLat, endLng)
          : position
      ..distanceKm = distanceKm
      ..fare = _roundToHundred(estimateFare(
        distanceKm: distanceKm,
        pricePerKm: MockData.pricePerKm,
        minimumFare: MockData.minimumFare,
      ));
    _changed();
    return _ok({
      'status': true,
      'message': 'Ride completed',
      'data': _rideJson(current)
    });
  }

  MockResponse _acceptPayment(MockRequest request) {
    if (!_isCurrentRide(request, BookingStatus.pendingPayment)) {
      return _invalidState('accept payment');
    }
    if (settings.scenario == MockScenario.paymentFailed) {
      return const MockResponse(500, {
        'status': false,
        'message': 'Payment could not be confirmed. Please try again.',
      });
    }
    final current = ride!..status = BookingStatus.completed;
    _recordEarnings(current);
    _archive(current);
    parkedAt = current.endPoint ?? current.driveTarget;
    _clearRide();
    _scheduleDispatch();
    _changed();
    return _ok({'status': true, 'message': 'Payment accepted'});
  }

  // ---- History, wallet, announcements ---------------------------------------

  MockResponse _historyPage(MockRequest request) {
    final page = int.tryParse('${request.query['page'] ?? 1}') ?? 1;
    final status = int.tryParse('${request.query['status'] ?? ''}');
    final matching = [
      for (final item in _history)
        if (status == null || item['status'] == status) item,
    ];
    return _ok({
      'status': true,
      'message': 'Success',
      // One page: the list controller stops at the first empty page.
      'data': page == 1 ? matching : <dynamic>[],
      'current_page': page,
      'per_page': 10,
      'total': matching.length,
    });
  }

  MockResponse _wallet() => _ok({
        'status': true,
        'message': 'Success',
        'data': MockData.wallet(
            balance: _walletBalance, transactions: _transactions),
      });

  // DD-45, DD-48: the real backend has no referral endpoints yet; these are
  // the shape the app proposes.
  MockResponse _referral() => _ok({
        'status': true,
        'message': 'Success',
        'data': MockData.referral(now: _now(), transfers: _rewardTransfers),
      });

  /// DD-48, DD-49: moves the asked amount from the reward balance into the
  /// wallet balance. An amount that is not above zero, or is more than the
  /// reward balance, is refused. A request id seen before is answered again
  /// without moving anything twice.
  MockResponse _transferRewards(MockRequest request) {
    final requestId = '${request.body['request_id'] ?? ''}';
    final available = MockData.referral(
        now: _now(), transfers: _rewardTransfers)['reward_balance'] as int;
    final repeated = _transferRequests[requestId];
    if (repeated != null) {
      return _ok({
        'status': true,
        'message': 'Already transferred',
        'data': {'transferred': repeated, 'reward_balance': available},
      });
    }
    final asked = num.tryParse('${request.body['amount'] ?? ''}');
    if (asked == null || asked <= 0 || asked != asked.roundToDouble()) {
      return const MockResponse(
          422, {'status': false, 'message': 'Invalid amount'});
    }
    final amount = asked.round();
    if (amount > available) {
      return const MockResponse(
          422, {'status': false, 'message': 'More than the reward balance'});
    }
    _rewardTransfers.add({
      'id': _rewardTransfers.length + 1,
      'amount': amount,
      'created_at': MockData.timestamp(_now()),
    });
    if (requestId.isNotEmpty) _transferRequests[requestId] = amount;
    _walletBalance += amount;
    _transactions.add(MockData.transaction(
        id: _transactions.length + 1,
        typeName: 'Reward Transfer',
        amount: amount,
        at: _now()));
    _changed();
    return _ok({
      'status': true,
      'message': 'Transferred',
      'data': {
        'transferred': amount,
        'reward_balance': available - amount,
        'wallet_balance': _walletBalance,
      },
    });
  }

  MockResponse _checkInviteCode(MockRequest request) {
    final code = '${request.query['code'] ?? ''}'.trim().toUpperCase();
    final inviter = MockData.inviters[code];
    return _ok({
      'status': true,
      'message': 'Success',
      'data': {'valid': inviter != null, 'inviter_name': inviter},
    });
  }

  MockResponse _announcements(MockRequest request) {
    final page = int.tryParse('${request.query['page'] ?? 1}') ?? 1;
    final items = MockData.announcements();
    return _ok({
      'status': true,
      'data': page == 1 ? items : <dynamic>[],
      'current_page': page,
      'last_page': 1,
      'per_page': 10,
      'total': items.length,
    });
  }

  MockResponse _announcement(int id) {
    for (final item in MockData.announcements()) {
      if (item['id'] == id) return _ok({'status': true, 'data': item});
    }
    return const MockResponse(
        404, {'status': false, 'message': 'Announcement not found'});
  }

  // ---------------------------------------------------------------------
  // Simulation
  // ---------------------------------------------------------------------

  /// Where the simulated car is right now, derived from the ride's phase
  /// and how long it has been in it — so it is correct after a restart too.
  ({LatLng point, double heading, double speedMps}) driverFix() {
    final current = ride;
    ({LatLng point, double heading, double speedMps}) along(
        List<LatLng> route, double progress, Duration phase) {
      final p = pointAlong(route, progress);
      final moving = progress < 1;
      final speed = moving
          ? pathLengthMeters(route) / (_scale(phase).inMilliseconds / 1000)
          : 0.0;
      return (point: p.point, heading: p.heading, speedMps: speed);
    }

    if (current == null) return (point: parkedAt, heading: 0, speedMps: 0);
    switch (current.status) {
      case BookingStatus.accepted:
        return along(
          mockRoute(current.driverStart, current.pickup),
          _progress(current.acceptedAt, MockTimings.driveToPickup),
          MockTimings.driveToPickup,
        );
      case BookingStatus.arrived:
        return (point: current.pickup, heading: 0, speedMps: 0);
      case BookingStatus.startRide:
        return along(
          mockRoute(current.pickup, current.driveTarget),
          _tripProgress(current),
          MockTimings.tripInProgress,
        );
      case BookingStatus.pendingPayment:
      case BookingStatus.completed:
        return (
          point: current.endPoint ?? current.driveTarget,
          heading: 0,
          speedMps: 0
        );
      default:
        return (point: current.driverStart, heading: 0, speedMps: 0);
    }
  }

  double _tripProgress(MockRide r) =>
      _progress(r.startedAt, MockTimings.tripInProgress);

  double _progress(DateTime? since, Duration phase) {
    if (since == null) return 0;
    final total = _scale(phase).inMilliseconds;
    if (total <= 0) return 1;
    return (_now().difference(since).inMilliseconds / total).clamp(0.0, 1.0);
  }

  void _scheduleDispatch() {
    _dispatchTimer?.cancel();
    if (!online ||
        ride != null ||
        settings.dispatch == MockDispatch.manual ||
        settings.scenario == MockScenario.noRideRequest ||
        settings.approval != MockApproval.approved) {
      return;
    }
    _dispatchTimer =
        Timer(_scale(MockTimings.rideRequestAfterOnline), _autoDispatch);
  }

  /// Like a real server, only dispatch to a driver whose socket is connected:
  /// right after launch the app has not subscribed yet, and a request pushed
  /// then would be lost.
  void _autoDispatch() {
    if (!_socket.hasListener) {
      _dispatchTimer = Timer(const Duration(seconds: 1), _autoDispatch);
      return;
    }
    sendRideRequestNow();
  }

  /// Dispatches a ride request to the driver now. Replaces a pending request,
  /// but never interrupts an accepted trip.
  void sendRideRequestNow() {
    final current = ride;
    if (current != null && current.status != BookingStatus.request) {
      debugPrint('[MockBackend] not dispatching: ride ${current.id} is '
          '${_statusName(current.status)}');
      return;
    }
    _dispatchTimer?.cancel();
    _expiryTimer?.cancel();
    final next = MockRide(
      id: _nextRideId++,
      status: BookingStatus.request,
      driverStart: driverFix().point,
      destination:
          settings.rideHasDestination ? MockPlaces.destination.latLng : null,
      createdAt: _now(),
      paymentMethod: settings.paymentMethod.label,
    );
    ride = next;

    final pickup = next.pickup;
    _socket.add(MockSocketEvent('newRide', {
      'booking_id': next.id,
      'booking_code': next.id,
      'passengerId': MockData.passengerId,
      'vehicleType': MockData.vehicleTypeId,
      'vehiclePrice': MockData.pricePerKm,
      'timeout': MockTimings.rideRequestTimeoutSeconds,
      'passenger': {
        'name': 'Sreymom Chan',
        'phone': '098765432',
        'profile': ''
      },
      'location': {'latitude': pickup.latitude, 'longitude': pickup.longitude},
      'destination': next.destination == null
          ? null
          : {
              'latitude': next.destination!.latitude,
              'longitude': next.destination!.longitude
            },
    }));

    // Unanswered requests expire shortly after the on-screen countdown.
    _expiryTimer = Timer(
      const Duration(seconds: MockTimings.rideRequestTimeoutSeconds + 2),
      () {
        if (ride?.id == next.id && ride?.status == BookingStatus.request) {
          _clearRide();
          _scheduleDispatch();
          _changed();
        }
      },
    );
    _changed();
  }

  /// The passenger cancels the current ride (before the trip starts).
  void passengerCancelNow() {
    final current = ride;
    if (current == null ||
        current.status == BookingStatus.startRide ||
        current.status == BookingStatus.pendingPayment) {
      debugPrint('[MockBackend] nothing the passenger can cancel');
      return;
    }
    _socket.add(MockSocketEvent('onPassengerCancelDrive', {
      'booking_id': current.id,
      'booking_code': '${current.id}',
      'passengerId': MockData.passengerId,
    }));
    _archive(current..status = BookingStatus.cancel);
    _clearRide();
    _scheduleDispatch();
    _changed();
  }

  /// Drops the current ride, keeping history, wallet and the online flag.
  void resetTrip() {
    _clearRide();
    parkedAt = MockPlaces.driverStart.latLng;
    _scheduleDispatch();
    _changed();
  }

  /// Back to first-launch state: offline, no ride, seeded history and wallet.
  void resetAll() {
    _clearRide();
    _dispatchTimer?.cancel();
    online = false;
    parkedAt = MockPlaces.driverStart.latLng;
    _nextRideId = MockData.firstRideId;
    _seedHistoryAndWallet();
    _changed();
  }

  void onSettingsChanged() {
    _scheduleDispatch();
    _changed();
  }

  void _clearRide() {
    _expiryTimer?.cancel();
    _passengerCancelTimer?.cancel();
    ride = null;
  }

  /// A one-line state description for the dev panel.
  String get summary {
    final current = ride;
    final rideText = current == null
        ? 'no ride'
        : 'ride #${current.id} · ${_statusName(current.status)}';
    return '${online ? 'Online' : 'Offline'} · $rideText';
  }

  // ---------------------------------------------------------------------
  // JSON
  // ---------------------------------------------------------------------

  Map<String, dynamic> _driverJson() => MockData.driver(
        approvalCode: settings.approval.code,
        position: driverFix().point,
      );

  static String _statusName(int status) => switch (status) {
        BookingStatus.request => 'Request',
        BookingStatus.accepted => 'Accepted',
        BookingStatus.arrived => 'Arrived',
        BookingStatus.startRide => 'Start Ride',
        BookingStatus.pendingPayment => 'Pending Payment',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancel => 'Cancelled',
        _ => 'Unknown',
      };

  static int _roundToHundred(double riel) => (riel / 100).round() * 100;

  /// One shape for every ride payload (`DataDriverInfo`, confirm/complete
  /// `Data`, `DataHistory`) — the models read the same keys.
  Map<String, dynamic> _rideJson(MockRide r, {LatLng? driverPosition}) {
    final pickup = r.pickup;
    final end = r.destination ?? r.endPoint;
    String? placeName(LatLng? p) =>
        p == null ? null : (MockPlaces.nameNear(p) ?? 'Street 271, Phnom Penh');
    return {
      'id': r.id,
      'booking_code': '${r.id}',
      'start_latitude': pickup.latitude.toStringAsFixed(6),
      'start_longitude': pickup.longitude.toStringAsFixed(6),
      'end_latitude': end?.latitude.toStringAsFixed(6),
      'end_longitude': end?.longitude.toStringAsFixed(6),
      'start_time':
          r.startedAt == null ? null : MockData.timestamp(r.startedAt!),
      'end_time':
          r.completedAt == null ? null : MockData.timestamp(r.completedAt!),
      'start_address': placeName(pickup),
      'end_address': placeName(end),
      'fare': r.fare,
      'status': r.status,
      'status_name': _statusName(r.status),
      'passenger': MockData.passenger(position: pickup),
      'driver': MockData.driver(
        approvalCode: settings.approval.code,
        position: driverPosition ?? driverFix().point,
      ),
      // Cancelled rides carry a zero payment: the history card reads
      // `payment!` for every row, cancelled ones included.
      'payment': r.fare == null && r.status != BookingStatus.cancel
          ? null
          : _paymentJson(r),
      'created_at': MockData.timestamp(r.createdAt),
      'updated_at':
          MockData.timestamp(r.completedAt ?? r.startedAt ?? r.createdAt),
    };
  }

  Map<String, dynamic> _paymentJson(MockRide r) {
    final km = r.distanceKm ?? 0;
    final seconds = (km / MockTimings.assumedCitySpeedKmh * 3600).round();
    final paid = r.status == BookingStatus.completed;
    final cancelled = r.status == BookingStatus.cancel;
    return {
      'id': r.id - MockData.firstRideId + 1,
      'invoice_id': 70000 + r.id - MockData.firstRideId,
      'ride_id': r.id,
      'distance': '${km.toStringAsFixed(2)} km',
      'duration': seconds >= 3600
          ? '${seconds ~/ 3600} hours ${(seconds % 3600) ~/ 60} mins'
          : '${seconds ~/ 60} mins ${seconds % 60} seconds',
      'amount': '${r.fare ?? 0}',
      'payment_method': r.paymentMethod,
      'status': paid ? 1 : (cancelled ? 2 : 0),
      'status_name': paid ? 'Paid' : (cancelled ? 'Cancelled' : 'Pending'),
      'created_at': MockData.timestamp(r.startedAt ?? r.createdAt),
      'updated_at': MockData.timestamp(r.completedAt ?? r.createdAt),
    };
  }

  void _archive(MockRide r) {
    _history.insert(
        0, _rideJson(r, driverPosition: r.endPoint ?? r.driverStart));
  }

  void _recordEarnings(MockRide r) {
    final fare = r.fare ?? 0;
    final commission = (fare * 0.10).round();
    final id = _transactions.length + 1;
    if (r.paymentMethod == MockPaymentMethod.cash.label) {
      // Cash stays with the driver; the platform takes its commission.
      _walletBalance -= commission;
      _transactions.add(MockData.transaction(
          id: id,
          typeName: 'Commission',
          amount: -commission,
          at: _now(),
          referenceId: r.id));
    } else {
      _walletBalance += fare - commission;
      _transactions.add(MockData.transaction(
          id: id,
          typeName: 'Trip Earning',
          amount: fare - commission,
          at: _now(),
          referenceId: r.id));
    }
  }

  void _seedHistoryAndWallet() {
    _history.clear();
    _transactions.clear();
    _rewardTransfers.clear();
    _transferRequests.clear();
    final now = _now();
    var seedId = 980001;
    MockRide past({
      required int daysAgo,
      required int status,
      required double km,
      required String method,
      LatLng? destination,
    }) {
      final started = now.subtract(Duration(days: daysAgo, hours: 2));
      final r = MockRide(
        id: seedId++,
        status: status,
        driverStart: MockPlaces.watPhnom.latLng,
        destination: destination,
        createdAt: started.subtract(const Duration(minutes: 6)),
        paymentMethod: method,
        startedAt: status == BookingStatus.cancel ? null : started,
        completedAt: status == BookingStatus.cancel
            ? null
            : started.add(Duration(
                minutes: (km / MockTimings.assumedCitySpeedKmh * 60).round())),
        endPoint: destination,
      );
      if (status == BookingStatus.completed) {
        r
          ..distanceKm = km
          ..fare = _roundToHundred(estimateFare(
              distanceKm: km,
              pricePerKm: MockData.pricePerKm,
              minimumFare: MockData.minimumFare));
      }
      return r;
    }

    for (final r in [
      past(
          daysAgo: 0,
          status: BookingStatus.completed,
          km: 3.4,
          method: 'Cash',
          destination: MockPlaces.russianMarket.latLng),
      past(
          daysAgo: 1,
          status: BookingStatus.completed,
          km: 10.6,
          method: 'Wallet',
          destination: MockPlaces.airport.latLng),
      past(
          daysAgo: 1,
          status: BookingStatus.cancel,
          km: 0,
          method: 'Cash',
          destination: MockPlaces.aeonMall.latLng),
      past(
          daysAgo: 3,
          status: BookingStatus.completed,
          km: 0.8,
          method: 'Card',
          destination: MockPlaces.royalPalace.latLng),
      past(
          daysAgo: 6,
          status: BookingStatus.completed,
          km: 2.9,
          method: 'Cash',
          destination: MockPlaces.independenceMonument.latLng),
    ]) {
      _history.add(_rideJson(r, driverPosition: r.endPoint));
    }

    _walletBalance = 85400;
    _transactions.addAll([
      MockData.transaction(
          id: 1,
          typeName: 'Top Up',
          amount: 100000,
          at: now.subtract(const Duration(days: 7))),
      MockData.transaction(
          id: 2,
          typeName: 'Commission',
          amount: -1100,
          at: now.subtract(const Duration(days: 6)),
          referenceId: 980005),
      MockData.transaction(
          id: 3,
          typeName: 'Commission',
          amount: -1300,
          at: now.subtract(const Duration(days: 3)),
          referenceId: 980004),
      MockData.transaction(
          id: 4,
          typeName: 'Trip Earning',
          amount: 18200,
          at: now.subtract(const Duration(days: 1)),
          referenceId: 980002),
    ]);
  }

  // ---------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------

  void _changed() {
    revision.value++;
    if (persist) unawaited(_save());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _stateKey,
        jsonEncode({
          'online': online,
          'ride': ride?.toJson(),
          'parkedAt': _latLngToJson(parkedAt),
          'nextRideId': _nextRideId,
          'walletBalance': _walletBalance,
          'transactions': _transactions,
          'history': _history,
          'rewardTransfers': _rewardTransfers,
        }));
  }

  /// Restores the state saved before the app was killed. A ride request that
  /// was never answered is dropped — it would have expired server-side.
  Future<void> restore() async {
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      online = json['online'] as bool? ?? false;
      final savedRide = json['ride'];
      ride = savedRide is Map<String, dynamic>
          ? MockRide.fromJson(savedRide)
          : null;
      if (ride?.status == BookingStatus.request) ride = null;
      parkedAt = _latLngFromJson(json['parkedAt']) ?? parkedAt;
      _nextRideId = json['nextRideId'] as int? ?? _nextRideId;
      _walletBalance = json['walletBalance'] as int? ?? _walletBalance;
      _transactions
        ..clear()
        ..addAll((json['transactions'] as List).cast<Map<String, dynamic>>());
      _history
        ..clear()
        ..addAll((json['history'] as List).cast<Map<String, dynamic>>());
      // Absent in a state saved before DD-48.
      _rewardTransfers
        ..clear()
        ..addAll((json['rewardTransfers'] as List? ?? const [])
            .cast<Map<String, dynamic>>());
    } catch (e) {
      debugPrint('[MockBackend] discarding unreadable saved state: $e');
      resetAll();
      return;
    }
    _scheduleDispatch();
    revision.value++;
  }

  @visibleForTesting
  void dispose() {
    _dispatchTimer?.cancel();
    _expiryTimer?.cancel();
    _passengerCancelTimer?.cancel();
    _socket.close();
  }
}
