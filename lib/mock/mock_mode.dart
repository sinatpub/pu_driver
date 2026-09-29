/// QA Mock/Demo Mode — the switch, and the runtime settings QA can change.
///
/// Mock mode replaces the backend, not the app: every screen, controller,
/// repository, datasource and model runs exactly as it does against the real
/// API. The fake backend sits underneath them at the transport boundaries —
/// the shared Dio client (REST), the driver socket (push events), the GPS
/// stream, and Google Directions — so nothing above those boundaries knows
/// which one it is talking to. See `docs/qa/MOCK_MODE.md`.
///
/// ## Why it cannot reach a production build
///
/// [MockMode.enabled] is a compile-time constant that needs **both**
/// `--dart-define=USE_MOCK_DATA=true` **and** a non-release build
/// (`kReleaseMode == false`). In a release build it folds to `false`, every
/// `if (MockMode.enabled)` branch is dead code, and the mock layer is
/// tree-shaken out of the binary. A developer who leaves the define in a
/// release command still gets the real backend.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tara_driver_application/mock/mock_backend.dart';
import 'package:tara_driver_application/mock/mock_location_source.dart';
import 'package:tara_driver_application/mock/mock_route_provider.dart';
import 'package:tara_driver_application/services/location_service.dart';
import 'package:tara_driver_application/services/route_service.dart';

/// Which backend behaviour to simulate. Driver-side equivalents of the
/// passenger-flow scenarios in the QA brief — see `docs/qa/MOCK_MODE.md`.
enum MockScenario {
  /// Every call succeeds; ride requests arrive while online.
  normalFlow('NORMAL_FLOW', 'Normal flow'),

  /// Online, but no ride request is ever dispatched (the driver-side
  /// "no driver available": nothing to do). The dev panel can still send one.
  noRideRequest('NO_RIDE_REQUEST', 'No ride request'),

  /// Accept returns `RIDE_ALREADY_ACCEPTED` — another driver was faster.
  rideAlreadyTaken('RIDE_ALREADY_TAKEN', 'Ride already taken'),

  /// Accept returns a 200 with no booking — the "can't confirm" error.
  bookingFailed('BOOKING_FAILED', 'Booking failed'),

  /// The passenger cancels over the socket shortly after the driver accepts.
  passengerCancelled('PASSENGER_CANCELLED', 'Passenger cancelled'),

  /// `accept-payment` fails with a server error.
  paymentFailed('PAYMENT_FAILED', 'Payment failed'),

  /// Every request fails as if the phone had no connection.
  networkError('NETWORK_ERROR', 'Network error'),

  /// Every authenticated request returns 401, which signs the driver out.
  sessionExpired('SESSION_EXPIRED', 'Session expired'),

  /// GPS never produces a fix.
  locationError('LOCATION_ERROR', 'Location error');

  const MockScenario(this.wireName, this.label);

  /// The `MOCK_SCENARIO` dart-define spelling.
  final String wireName;
  final String label;

  static MockScenario? parse(String? value) {
    for (final s in values) {
      if (s.wireName == value || s.name == value) return s;
    }
    return null;
  }
}

/// Whether ride requests arrive on their own or only from the dev panel.
enum MockDispatch { auto, manual }

/// The payment method the simulated passenger pays with. The driver app only
/// displays it on the receipt and in history; collecting is one button.
enum MockPaymentMethod {
  cash('Cash'),
  wallet('Wallet'),
  card('Card');

  const MockPaymentMethod(this.label);
  final String label;
}

/// The admin-approval state of the mock driver account (`driver.status`).
enum MockApproval {
  approved(1),
  pending(0),
  rejected(2);

  const MockApproval(this.code);
  final int code;
}

const List<double> mockSpeeds = [1, 2, 5, 10];

@immutable
class MockSettings {
  const MockSettings({
    this.useMock = true,
    this.scenario = MockScenario.normalFlow,
    this.speed = 1,
    this.dispatch = MockDispatch.auto,
    this.paymentMethod = MockPaymentMethod.cash,
    this.rideHasDestination = true,
    this.approval = MockApproval.approved,
  });

  /// Runtime kill switch inside a mock-capable build. Read once at launch —
  /// changing it takes effect after the app restarts.
  final bool useMock;
  final MockScenario scenario;

  /// Simulation speed multiplier: every delay in `MockTimings` is divided by
  /// this.
  final double speed;
  final MockDispatch dispatch;
  final MockPaymentMethod paymentMethod;

  /// With a destination the trip screen draws a route and shows a fixed
  /// estimate; without one it runs the live distance/fare meter.
  final bool rideHasDestination;
  final MockApproval approval;

  MockSettings copyWith({
    bool? useMock,
    MockScenario? scenario,
    double? speed,
    MockDispatch? dispatch,
    MockPaymentMethod? paymentMethod,
    bool? rideHasDestination,
    MockApproval? approval,
  }) =>
      MockSettings(
        useMock: useMock ?? this.useMock,
        scenario: scenario ?? this.scenario,
        speed: speed ?? this.speed,
        dispatch: dispatch ?? this.dispatch,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        rideHasDestination: rideHasDestination ?? this.rideHasDestination,
        approval: approval ?? this.approval,
      );
}

class MockMode {
  MockMode._();

  static const bool _requested = bool.fromEnvironment('USE_MOCK_DATA');
  static const String _scenarioDefine = String.fromEnvironment('MOCK_SCENARIO');
  static const String _speedDefine = String.fromEnvironment('MOCK_SPEED');

  /// Compile-time: can this build use the mock backend at all? Must stay a
  /// `const` expression over `kReleaseMode` so release builds shake it out.
  static const bool enabled = _requested && !kReleaseMode;

  static const _prefix = 'qa_mock.';

  static MockSettings _settings = const MockSettings();
  static bool _activeThisLaunch = false;

  /// Is the mock backend serving this run of the app?
  static bool get isActive => enabled && _activeThisLaunch;

  static MockSettings get settings => _settings;

  /// Fires whenever the dev panel changes a setting.
  static final ValueNotifier<MockSettings> changes =
      ValueNotifier<MockSettings>(_settings);

  /// Loads persisted settings, applies `MOCK_SCENARIO` / `MOCK_SPEED` if the
  /// build passed them, and restores the mock backend's saved trip. A no-op
  /// outside a mock-capable build.
  static Future<void> init() async {
    if (!enabled) return;
    final prefs = await SharedPreferences.getInstance();
    var loaded = MockSettings(
      useMock: prefs.getBool('${_prefix}useMock') ?? true,
      scenario: MockScenario.parse(prefs.getString('${_prefix}scenario')) ??
          MockScenario.normalFlow,
      speed: prefs.getDouble('${_prefix}speed') ?? 1,
      dispatch:
          _byName(MockDispatch.values, prefs.getString('${_prefix}dispatch')) ??
              MockDispatch.auto,
      paymentMethod: _byName(MockPaymentMethod.values,
              prefs.getString('${_prefix}paymentMethod')) ??
          MockPaymentMethod.cash,
      rideHasDestination: prefs.getBool('${_prefix}rideHasDestination') ?? true,
      approval:
          _byName(MockApproval.values, prefs.getString('${_prefix}approval')) ??
              MockApproval.approved,
    );
    // A define passed on the command line wins over what the panel saved, so
    // `flutter run --dart-define=MOCK_SCENARIO=PAYMENT_FAILED` does what it says.
    final defineScenario = MockScenario.parse(_scenarioDefine);
    if (defineScenario != null) {
      loaded = loaded.copyWith(scenario: defineScenario);
    }
    final defineSpeed = double.tryParse(_speedDefine);
    if (defineSpeed != null && defineSpeed > 0) {
      loaded = loaded.copyWith(speed: defineSpeed);
    }

    _settings = loaded;
    changes.value = loaded;
    _activeThisLaunch = loaded.useMock;
    if (isActive) {
      debugPrint('[MockMode] ACTIVE — scenario=${loaded.scenario.wireName} '
          'speed=${loaded.speed}x. No request reaches the real backend.');
      LocationService.instance.source = MockLocationSource.instance;
      RouteService.instance.provider = const MockRouteProvider();
      await MockBackend.instance.restore();
    }
  }

  static Future<void> update(MockSettings next) async {
    if (!enabled) return;
    _settings = next;
    changes.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}useMock', next.useMock);
    await prefs.setString('${_prefix}scenario', next.scenario.wireName);
    await prefs.setDouble('${_prefix}speed', next.speed);
    await prefs.setString('${_prefix}dispatch', next.dispatch.name);
    await prefs.setString('${_prefix}paymentMethod', next.paymentMethod.name);
    await prefs.setBool(
        '${_prefix}rideHasDestination', next.rideHasDestination);
    await prefs.setString('${_prefix}approval', next.approval.name);
    if (isActive) MockBackend.instance.onSettingsChanged();
  }

  /// [duration] at the current simulation speed.
  static Duration scaled(Duration duration) => Duration(
      microseconds: (duration.inMicroseconds / _settings.speed).round());

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
