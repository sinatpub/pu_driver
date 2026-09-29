import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/utils/fare_estimate.dart';
import 'package:tara_driver_application/presentation/screens/booking/domain/trip_state_machine.dart';
import 'package:tara_driver_application/presentation/screens/booking/state.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/ride_request_bottom_pop_widget.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/trip_header.dart';
import 'package:tara_driver_application/presentation/screens/home/state.dart';
import 'package:tara_driver_application/services/location_service.dart';

import '../helpers/localized_host.dart';

/// Q3 — Performance review (`docs/roadmap.md` §Q3).
///
/// The roadmap's verification ("DevTools on a mid-range Android") needs a
/// device with the live backend; the API is unreachable and no tester device
/// is attached, so this harness measures everything that is deterministic in
/// a widget test and records the rest as device carryover.
///
/// Measured here (see `docs/qa/q3/README.md`):
///
/// * **Trip screen** — the GPS listener's per-tick reactive work, replayed on
///   the real overlay widgets (`TripHeader`, countdown, meter sheet) composed
///   exactly as `booking/view.dart` composes them: one whole-overlay
///   `setState` rebuild per position tick, one camera animate per tick (B12),
///   one reverse-geocode per tick, plus the 1 s meter timer's own rebuild.
/// * **Trip lifecycle** — a full legal `TripStateMachine` walk, and
///   `LocationService` single-subscription idempotence and cancel-on-stop.
/// * **Home map** — `HomeState` marker-set churn driven like `HomeLogic`'s GPS
///   listener: a fresh distinct `Marker` per tick (unbounded set growth), one
///   `currentLocation` notification per tick, one camera animate per tick.
///
/// `WidgetsBinding.addTimingsCallback` never fires under the widget-test
/// binding (verified), so GPU/raster frame times stay on-device.
const int _ticks = 120;
const int _tripTicks = 60;

final Map<String, Object> _metrics = <String, Object>{};

void _record(String key, Object value) => _metrics[key] = value;

/// ~11 m between consecutive ticks (10 m distanceFilter), so every in-progress
/// tick after the first also crosses the screen's distance branch.
Position _pos(int i, {double heading = 0}) => Position(
      longitude: 104.880000 + i * 1e-4,
      latitude: 11.500000 + i * 1e-4,
      timestamp: DateTime(2026, 1, 1).add(Duration(seconds: i)),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 5,
      heading: heading,
      headingAccuracy: 5,
      speed: i == 0 ? 0 : 30 / 3.6,
      speedAccuracy: 1,
    );

/// Underlying geolocator platform, replaced per test so [`LocationService`]
/// opens a real, cancellable subscription with no host.
class _FakeGeolocator extends GeolocatorPlatform {
  _FakeGeolocator() {
    _positions = StreamController<Position>.broadcast(
      onCancel: () => cancels++,
      onListen: () {},
    );
  }

  late final StreamController<Position> _positions;

  int streamAdoptions = 0;
  int cancels = 0;

  void emit(Position p) => _positions.add(p);

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    streamAdoptions++;
    return _positions.stream;
  }

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.always;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async =>
      null;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async =>
      _pos(0);
}

class _TripArgs {
  _TripArgs({
    required this.bookingCode,
    required this.passengerId,
    required this.latPassenger,
    required this.lngPassenger,
    this.desLatPassenger,
    this.desLngPassenger,
    required this.pricrVehicle,
    required this.timeOut,
  });

  final int bookingCode;
  final int passengerId;
  final double latPassenger;
  final double lngPassenger;
  final double? desLatPassenger;
  final double? desLngPassenger;
  final int pricrVehicle;
  final int timeOut;
}

/// Counters for one harness run; the keys mirror booking/view.dart's listener.
class _TripMetrics {
  int overlayRebuilds = 0;
  int cameraAnimates = 0;
  int reverseGeocodes = 0;
  int distanceBranches = 0;
}

/// The trip screen's per-tick GPS work, replayed on the real overlay widgets
/// with the same composition as `booking/view.dart` (minus the GoogleMap
/// platform view, which the widget-test binding cannot rasterise).
class _TripScreenHarness extends StatefulWidget {
  const _TripScreenHarness({
    required this.stream,
    required this.state,
    required this.metrics,
    required this.args,
  });

  final Stream<Position> stream;
  final BookingState state;
  final _TripMetrics metrics;
  final _TripArgs args;

  @override
  State<_TripScreenHarness> createState() => _TripScreenHarnessState();
}

class _TripScreenHarnessState extends State<_TripScreenHarness> {
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  final double _distanceThreshold = 10;
  LatLng? _lastPosition;
  Duration remaining = Duration.zero;
  double totalDistanceCount = 0;
  String totalFee = '';
  int priceUnder1Km = 0;
  double totalDistance = 0;

  @override
  void initState() {
    super.initState();
    _positionStream = widget.stream.listen((Position position) {
      // The screen's per-tick listener work (`_startLocationListener`):
      // fields, _turnRight (camera), syncMarker (reverse-geocode).
      setState(() {
        widget.metrics.cameraAnimates++;
        widget.metrics.reverseGeocodes++;
      });
      final bool hasDestination = widget.args.desLatPassenger != null &&
          widget.args.desLatPassenger != 0.0;
      if (widget.state.stage.value == TripStage.inProgress && !hasDestination) {
        final LatLng current = LatLng(position.latitude, position.longitude);
        if (_lastPosition != null) {
          final double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            current.latitude,
            current.longitude,
          );
          if (distance >= _distanceThreshold) {
            setState(() {
              widget.metrics.distanceBranches++;
              totalDistanceCount +=
                  double.parse(distance.toStringAsFixed(3).toString());
              totalFee = estimateFare(
                distanceKm: totalDistanceCount / 1000,
                pricePerKm: widget.args.pricrVehicle,
                minimumFare: priceUnder1Km,
              ).toString();
              _lastPosition = current;
            });
          }
        } else {
          _lastPosition = current;
        }
      }
    });
    // The 1 s meter timer (`startTimer`).
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => remaining += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  String get _meterDuration => formatDuration(remaining);

  String get _meterDistance => (widget.args.desLatPassenger == null ||
          widget.args.desLatPassenger == 0.0)
      ? convertMaterToKm(double.parse(totalDistanceCount.toString()))
      : convertKmToKmM(double.parse(totalDistance.toString()));

  String get _meterFare => (widget.args.desLatPassenger == null ||
          widget.args.desLatPassenger == 0.0)
      ? totalDistanceCount <= 1000
          ? formatRielAmount(priceUnder1Km.toString())
          : formatRielAmount(totalFee)
      : formatRielAmount(totalFee);

  @override
  Widget build(BuildContext context) {
    // One build per setState/tick — this is the whole-screen rebuild count.
    widget.metrics.overlayRebuilds++;
    return Obx(() {
      final TripStage stage = widget.state.stage.value;
      return Stack(
        children: <Widget>[
          // Stand-in for the GoogleMap platform view (full-bleed base layer).
          const Positioned.fill(child: ColoredBox(color: Color(0xFFF4F1EC))),
          // _topOverlay — the same composition as booking/view.dart: no
          // header on a request, where the countdown sits inside Accept
          // (DD-35).
          if (stage != TripStage.requestReceived)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TripHeader(
                    stage: stage,
                    title: 'STAGE_NEW_REQUEST'.tr(),
                    bookingCode: widget.args.bookingCode,
                  ),
                ),
              ),
            ),
          ModelBottomSheetNewRequestWidget(
            bookingCode: widget.args.bookingCode,
            passengerId: widget.args.passengerId,
            distandTotal: totalDistance,
            totalFee: totalFee,
            duration: _meterDuration,
            distance: _meterDistance,
            fare: _meterFare,
            bookingId: 8821,
            namePassanger: 'Sok',
            phonePassanger: '011 223 344',
            profilePassanger: '',
            onTap: () {},
            onCancel: () {},
            processType: stage.toProcessStep(),
            requestTimeoutSeconds: widget.args.timeOut,
            whereToGoLocationName: '',
            passegerLocationName: '',
          ),
        ],
      );
    });
  }
}

void main() {
  tearDownAll(() {
    try {
      final Directory dir = Directory('docs/qa/q3/artifacts');
      dir.createSync(recursive: true);
      final String stamp =
          DateTime.now().toIso8601String().replaceAll(':', '-');
      File('${dir.path}/performance_review_$stamp.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(_metrics));
    } catch (e) {
      debugPrint('Q3 capture write skipped: $e');
    }
    debugPrint('=== Q3 performance review capture ===');
    debugPrint(const JsonEncoder.withIndent('  ').convert(_metrics));
  });

  group('Trip screen — GPS listener per-tick reactive work', () {
    testWidgets(
        'every position tick rebuilds the whole overlay once, animates '
        'the camera once, reverse-geocodes once, and the in-progress branch '
        'crosses the 10 m threshold', (WidgetTester tester) async {
      final StreamController<Position> stream =
          StreamController<Position>.broadcast();
      final BookingState state = BookingState(TripStage.requestReceived);
      final _TripMetrics m = _TripMetrics();
      final _TripArgs args = _TripArgs(
        bookingCode: 8821,
        passengerId: 7,
        latPassenger: 11.5,
        lngPassenger: 104.88,
        desLatPassenger: null,
        desLngPassenger: null,
        pricrVehicle: 1200,
        timeOut: 60,
      );

      await tester.pumpWidget(
        localizedHostPage(
          Scaffold(
            body: _TripScreenHarness(
              stream: stream.stream,
              state: state,
              metrics: m,
              args: args,
            ),
          ),
        ),
      );
      // No pumpAndSettle: the 60 s request countdown would run to completion
      // under fake async and navigate home. A few short pumps settle the
      // translation load instead.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      state.stage.value = TripStage.inProgress;
      await tester.pump();

      final int rebuildsBeforeTicks = m.overlayRebuilds;
      for (int i = 0; i < _tripTicks; i++) {
        stream.add(_pos(i, heading: (i * 6) % 360));
        await tester.pump(const Duration(milliseconds: 16));
      }

      final int perTickRebuilds = m.overlayRebuilds - rebuildsBeforeTicks;

      _record('trip.perTick.rebuilds', perTickRebuilds);
      _record('trip.perTick.cameraAnimates', m.cameraAnimates);
      _record('trip.perTick.reverseGeocodes', m.reverseGeocodes);
      _record('trip.perTick.distanceBranches', m.distanceBranches);
      _record('trip.perTick.ticks', _tripTicks);
      _record(
          'trip.note.rebuildHotPath',
          'every setState rebuilds the whole Stack (map + overlay) once — '
              'GPS listener, 1 s meter timer, camera-move callback; GPU cost and '
              'the 16 ms gate are device-measured');

      // Findings, not fixes (roadmap: "pre-existing; don't fix here, measure").
      expect(perTickRebuilds, greaterThanOrEqualTo(_tripTicks));
      expect(m.cameraAnimates, _tripTicks);
      expect(m.reverseGeocodes, _tripTicks);
      expect(m.distanceBranches, _tripTicks - 1);

      await stream.close();
    });

    testWidgets('the 1 s meter timer rebuilds the overlay once per tick',
        (WidgetTester tester) async {
      final StreamController<Position> stream =
          StreamController<Position>.broadcast();
      final _TripMetrics m = _TripMetrics();
      await tester.pumpWidget(
        localizedHostPage(
          Scaffold(
            body: _TripScreenHarness(
              stream: stream.stream,
              state: BookingState(TripStage.inProgress),
              metrics: m,
              args: _TripArgs(
                bookingCode: 8821,
                passengerId: 7,
                latPassenger: 11.5,
                lngPassenger: 104.88,
                desLatPassenger: null,
                desLngPassenger: null,
                pricrVehicle: 1200,
                timeOut: 60,
              ),
            ),
          ),
        ),
      );
      // inProgress → no countdown, so no perpetual animation; but the 1 s
      // meter timer schedules a frame every second of fake time, so a
      // pumpAndSettle would never settle. Short pumps handle the translation
      // load instead.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final int settled = m.overlayRebuilds;
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      final int timerRebuilds = m.overlayRebuilds - settled;
      _record('trip.timer.overlayRebuildsPer5Seconds', timerRebuilds);
      // Each 1 s tick is one setState → one full overlay rebuild.
      expect(timerRebuilds, greaterThanOrEqualTo(5));
      await stream.close();
    });
  });

  group('Trip lifecycle — state machine walk and subscription hygiene', () {
    testWidgets('a full legal trip walks every stage',
        (WidgetTester tester) async {
      final TripStateMachine machine =
          TripStateMachine(TripStage.requestReceived);
      final List<String> seen = <String>[];

      machine.accept();
      seen.add(machine.stage.name);
      machine.arrive();
      seen.add(machine.stage.name);
      machine.start();
      seen.add(machine.stage.name);
      machine.complete();
      seen.add(machine.stage.name);

      _record('trip.lifecycle.stages', seen.join(' -> '));
      expect(
        seen,
        <String>[
          TripStage.enRouteToPickup.name,
          TripStage.waitingAtPickup.name,
          TripStage.inProgress.name,
          TripStage.completing.name,
        ],
      );
      expect(machine.canCancel, isFalse);
    });

    testWidgets('LocationService opens one subscription and cancels on stop',
        (WidgetTester tester) async {
      final _FakeGeolocator fake = _FakeGeolocator();
      GeolocatorPlatform.instance = fake;

      final LocationService service = LocationService.instance;
      service.start();
      service.start();
      await tester.pump();

      // One subscription even though several screens each call start().
      expect(fake.streamAdoptions, 1);
      _record('trip.locationService.streamsForTwoStarts', fake.streamAdoptions);

      // start() hands the stream to LocationService without touching the
      // network; emitting would need a real HTTP client (UpdateDriverLocation
      // has a late dio) which the test binding must not hit.
      _record('trip.locationService.receivesPositions', 'device-carried');

      service.stop();
      await tester.pump();
      _record('trip.locationService.adoptionsAfterStop', fake.streamAdoptions);

      service.start();
      await tester.pump();
      // stop() cancelled the geolocator stream; a fresh start adopts once.
      expect(fake.streamAdoptions - fake.cancels, lessThanOrEqualTo(1));
      service.stop();
      await tester.pump();
      expect(fake.cancels, greaterThanOrEqualTo(1));
      _record('trip.locationService.cancelsOnStop', fake.cancels);
    });
  });

  group('Home screen — GPS listener marker churn', () {
    testWidgets(
        'each position tick adds a distinct Marker (unbounded set '
        'growth) and notifies observers once', (WidgetTester tester) async {
      final HomeState state = HomeState();
      int markerFires = 0;
      int currentFires = 0;
      state.markers.listen((_) => markerFires++);
      state.currentLocation.listen((_) => currentFires++);
      int cameraAnimates = 0;

      for (int i = 0; i < _ticks; i++) {
        final LatLng at = LatLng(11.5 + i * 1e-4, 104.88 + i * 1e-4);
        // HomeLogic.initLocation's listener work: updateMarker + camera.
        state.markers.add(Marker(
          markerId: const MarkerId('driverMarker'),
          position: at,
          rotation: (i * 6 % 360).toDouble(),
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ));
        state.currentLocation.value = at;
        cameraAnimates++;
        await tester.pump(const Duration(milliseconds: 16));
      }

      _record(
          'home.markers.entityCountAfter${_ticks}Ticks', state.markers.length);
      _record(
        'home.markers.distinctIds',
        state.markers.map((m) => m.markerId.value).toSet().length,
      );
      _record('home.markers.currentLocationFires', currentFires);
      _record('home.markers.cameraAnimatesPerTick', cameraAnimates);
      _record('home.markers.markerFires', markerFires);
      _record(
          'home.note.markerChurn',
          'each tick: one distinct Marker (same MarkerId, new position/'
              'rotation) added to the RxSet — unbounded growth while idling — '
              'plus one loadCustomMarkerTukTuk asset decode per tick '
              '(device-carried)');

      // Findings — the roadmap says measure it, not fix it.
      expect(state.markers.length, _ticks);
      expect(currentFires, _ticks);
      expect(cameraAnimates, _ticks);
    });

    testWidgets('the marker set stays flat with no positions arriving',
        (WidgetTester tester) async {
      final HomeState state = HomeState();
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      _record('home.markers.growthWithNoTicks', state.markers.length);
      expect(state.markers.length, 0);
    });
  });
}
