import 'dart:async';

import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/helper/get_address_latlng_helper.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/core/storage/get_storages.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/fare_estimate.dart';
import 'package:tara_driver_application/core/utils/load_custom_marker.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:tara_driver_application/data/models/complete_driver_model.dart';
import 'package:tara_driver_application/data/models/register_model.dart';
import 'package:tara_driver_application/presentation/screens/booking/domain/trip_state_machine.dart';

import 'package:tara_driver_application/presentation/controllers/vehicle_controller.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/ride_request_bottom_pop_widget.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/trip_header.dart';
import 'package:tara_driver_application/presentation/widgets/error_dialog_widget.dart';
import 'package:tara_driver_application/services/location_service.dart';
import 'package:tara_driver_application/services/route_service.dart';
import 'package:tara_driver_application/services/socket_service.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Trans;

import 'logic.dart';
import 'state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// D-06 (`12`). Route arguments used to be 21 **mutable** public fields on
/// this widget — the `must_be_immutable` warning `dart analyze` reported, and
/// two of them (`latDriver`/`lngDriver`) were reassigned on every GPS tick.
/// They now live on [BookingScreenArgs], resolved once by [BookingBinding]; the two
/// that genuinely change are screen-local fields on the State below.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Resolved on each access, never cached: GetX owns this instance's
  // lifetime, and a `final` field would keep pointing at a disposed one
  // if the route is left and re-entered (hit on device 2026-09-06 —
  // "A TextEditingController was used after being disposed").
  BookingLogic get tripController => Get.find<BookingLogic>();
  final VehicleController vehicleController = Get.find<VehicleController>();
  final BookingScreenArgs args = Get.arguments as BookingScreenArgs;

  /// The three route arguments that were ever reassigned: two track the
  /// driver's live position, and [refreshApp] is a one-shot flag the screen
  /// clears after its first use. Screen-local rather than pretending to be
  /// immutable arguments.
  double? latDriver;
  double? lngDriver;
  late bool refreshApp;

  late BitmapDescriptor driverMarker;
  late BitmapDescriptor passengerMarker;
  late BitmapDescriptor destinationPassengerMarker;
  GoogleMapController? _mapController;

  final double _distanceThreshold = 10; // meters
  StreamSubscription<Position>? _positionStream;
  LatLng? _lastPosition;

  //
  final DriverSocketService socketService = DriverSocketService();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];

  bool laodCalculateDistance = true;

  double bearing = 0.0;

  // PlaceMarker
  String currentPassengerPM = "";
  String destinationPassengerPM = "";

  double currentLatDriver = 0.0;
  double currentLngDriver = 0.0;
  String currentAddressDriver = "";

  double dropLatDriver = 0.0;
  double dropLngDriver = 0.0;
  String dropAddressDriver = "";

  double _currentZoom = 19.0;

  final double speed = 60.0; // 60 km/h

  // ========  distans descination ========
  double totalDistance = 0.0;
  double totalDistanceCount = 0.0;
  String totalFee = "";
  int priceUnder1Km = 0;

  /// C4 (`03 § dropping`): the drop-off's spinner starts at the tap rather
  /// than after the position + reverse-geocode round trip inside
  /// [getLocation]. View-local and never explicitly reset — a successful drop
  /// navigates away and a failed one pops the route, so it is always leaving
  /// the screen.
  bool _dropPending = false;

  /// DD-35 — the request stage's route to the pickup, fetched once when the
  /// screen opens on a request. It draws the polyline and gives the sheet its
  /// "4 min · 1.2 km" headline. Accepting reuses it (see [_reusePickupRoute])
  /// when the driver has not moved far, so only requests that are declined
  /// or expire cost an extra Directions call.
  RouteSummary? _pickupRoute;
  LatLng? _pickupRouteOrigin;
  bool _pickupRouteLoading = true;
  static const double _routeReuseMeters = 50;

  /// The pickup→destination driving distance, for the request sheet's trip
  /// figures. Null without a destination or a route.
  double? _tripDistanceKm;

  /// True once the vehicle list has given this request's minimum fare —
  /// the request sheet shows no fare estimate before that.
  bool _minimumFareKnown = false;

  /// The sheet's measured height; the map pads its camera by it, so a fitted
  /// route never ends up under the sheet.
  double _sheetHeight = 0;
  // * Register Socket
  void registerSocket() async {
    RegisterModel? driverData = await StorageGet.getDriverData();
    if (driverData?.data?.driver?.id != null) {
      socketService.connectToSocket(
        AppConstant.socketBasedUrl,
        "${driverData?.data?.driver?.id}",
        "Driver",
        context: context,
      );
    }
  }

  Duration remaining = Duration.zero;
  Timer? timer;

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        remaining += const Duration(seconds: 1);
      });
    });
  }

  void _startLocationListener() async {
    LocationService.instance.start();
    _positionStream = LocationService.instance.positionStream
        .listen((Position position) async {
      LatLng current = LatLng(position.latitude, position.longitude);
      setState(() {
        bearing = position.heading;
        currentLatDriver = position.latitude;
        currentLngDriver = position.longitude;
        latDriver = position.latitude;
        lngDriver = position.longitude;
        _turnRight();
        syncMarker();
      });
      if (tripController.state.stage.value == TripStage.inProgress &&
          (args.desLatPassenger == null || args.desLatPassenger == 0.0)) {
        if (_lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            current.latitude,
            current.longitude,
          );
          if (distance >= _distanceThreshold) {
            setState(() {
              totalDistanceCount +=
                  double.parse(distance.toStringAsFixed(3).toString());
              totalFee = estimateFare(
                distanceKm: totalDistanceCount / 1000,
                pricePerKm: args.pricrVehicle,
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
  }

  /// Fetches the driver's current position and updates the address/polyline
  /// state for [stage]. Unlike the old `getLocation(int processStep)`, this
  /// no longer also re-sets the trip stage on a delayed timer — the stage
  /// is already set by [tripController] by the time this runs (called only
  /// from `initState`, with the stage the controller was constructed with,
  /// or from the `ever()` listener below, right after a transition
  /// succeeds), so re-setting it here was pure redundancy.
  void getLocation(TripStage stage) async {
    // Through LocationService (F-05's single GPS owner), not Geolocator
    // directly, so the QA mock build's simulated position applies here too.
    Position? position = await LocationService.instance.getCurrentPosition();
    destinationPassengerPM =
        args.desLatPassenger != null && args.desLngPassenger != null
            ? await getAddressFromLatLng(
                args.desLatPassenger!, args.desLngPassenger!)
            : "";
    if (position != null) {
      if (stage == TripStage.requestReceived) {
        setState(() {
          currentLatDriver = position.latitude;
          currentLngDriver = position.longitude;
          latDriver = position.latitude;
          lngDriver = position.longitude;
        });
        _loadRequestRoute(LatLng(position.latitude, position.longitude));
      } else if (stage == TripStage.enRouteToPickup) {
        if (refreshApp == true) {
          currentAddressDriver =
              await getAddressFromLatLng(latDriver!, lngDriver!);
        } else {
          currentAddressDriver =
              await getAddressFromLatLng(position.latitude, position.longitude);
        }
        setState(() {
          currentLatDriver = position.latitude;
          currentLngDriver = position.longitude;
          latDriver = position.latitude;
          lngDriver = position.longitude;
        });
        if (!_reusePickupRoute(LatLng(currentLatDriver, currentLngDriver))) {
          _drawPolylines(
              dLocation: LatLng(currentLatDriver, currentLngDriver),
              pLocation: LatLng(args.latPassenger, args.lngPassenger));
        }
      } else if (stage == TripStage.waitingAtPickup) {
        if (refreshApp == true) {
          currentAddressDriver =
              await getAddressFromLatLng(latDriver!, lngDriver!);
        } else {
          currentAddressDriver =
              await getAddressFromLatLng(position.latitude, position.longitude);
        }
        setState(() {
          currentLatDriver = position.latitude;
          currentLngDriver = position.longitude;
          latDriver = position.latitude;
          lngDriver = position.longitude;
        });

        if (args.desLatPassenger != null && args.desLngPassenger != null) {
          _drawPolylines(
              dLocation: LatLng(currentLatDriver, currentLngDriver),
              pLocation: LatLng(args.desLatPassenger!, args.desLngPassenger!));
        } else {
          _clearPolyline();
        }
      } else if (stage == TripStage.inProgress) {
        if (refreshApp == true) {
          currentAddressDriver =
              await getAddressFromLatLng(latDriver!, lngDriver!);
          if (args.latStart != 0.0) {
            totalDistanceCount = (await RouteService.instance.drivingDistanceKm(
                    LatLng(position.latitude, position.longitude),
                    LatLng(args.latStart, args.lngStart)) *
                1000);
            totalFee = estimateFare(
              distanceKm: totalDistanceCount / 1000,
              pricePerKm: args.pricrVehicle,
              minimumFare: priceUnder1Km,
            ).toString();
          }
        } else {
          currentAddressDriver =
              await getAddressFromLatLng(position.latitude, position.longitude);
        }
        setState(() {
          currentLatDriver = position.latitude;
          currentLngDriver = position.longitude;
          latDriver = position.latitude;
          lngDriver = position.longitude;
        });

        if (args.desLatPassenger != null && args.desLngPassenger != null) {
          _drawPolylines(
              dLocation: LatLng(currentLatDriver, currentLngDriver),
              pLocation: LatLng(args.desLatPassenger!, args.desLngPassenger!));
        }
      } else if (stage == TripStage.completing) {
        debugPrint("drop - total distance ${Taxi.shared.totalDistance}");
        dropAddressDriver =
            await getAddressFromLatLng(position.latitude, position.longitude);
        setState(() {
          dropLatDriver = position.latitude;
          dropLngDriver = position.longitude;
        });
        tripController.complete(
          distance: args.desLatPassenger == null
              ? double.parse(
                  (totalDistanceCount / 1000).toStringAsFixed(3).toString())
              : totalDistance,
          endAddress: dropAddressDriver,
          endLatitude: dropLatDriver,
          endLongitude: dropLngDriver,
        );
      }
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _turnRight();
          syncMarker();
        });
      });
      // debugPrint("Lat: ${position.latitude}, Lng: ${position.longitude}");
    } else {
      debugPrint("Failed to get location.");
      // No fix, so no route: the request shows the pickup alone.
      if (stage == TripStage.requestReceived) {
        setState(() => _pickupRouteLoading = false);
        _fitRequestCamera();
      }
    }
  }

  /// DD-35: fetches the driver→pickup route for a request, draws it, and
  /// fits the camera to it. Then, when there is a destination, the trip's
  /// driving distance for the sheet's figures.
  Future<void> _loadRequestRoute(LatLng driver) async {
    final LatLng pickup = LatLng(args.latPassenger, args.lngPassenger);
    // The payload parser defaults a missing pickup to 0,0.
    if (pickup.latitude == 0.0 && pickup.longitude == 0.0) {
      setState(() => _pickupRouteLoading = false);
      return;
    }

    final RouteSummary? toPickup =
        await RouteService.instance.summary(driver, pickup);
    if (!mounted) return;
    final bool stillRequest =
        tripController.state.stage.value == TripStage.requestReceived;
    setState(() {
      _pickupRoute = toPickup;
      _pickupRouteOrigin = driver;
      _pickupRouteLoading = false;
      // Accepted while this was in flight: the pickup stage draws its own.
      if (toPickup != null && stillRequest) {
        _setRoutePolyline(toPickup.points);
      }
    });
    if (!stillRequest) return;
    _fitRequestCamera();

    final double? desLat = args.desLatPassenger;
    final double? desLng = args.desLngPassenger;
    if (desLat == null || desLng == null || desLat == 0.0) return;
    final RouteSummary? trip =
        await RouteService.instance.summary(pickup, LatLng(desLat, desLng));
    if (!mounted || trip == null) return;
    setState(() => _tripDistanceKm = trip.distanceMeters / 1000);
  }

  /// On accept, keeps the request's pickup route instead of fetching the
  /// same one again — as long as the driver is still within
  /// [_routeReuseMeters] of where it was fetched.
  bool _reusePickupRoute(LatLng driver) {
    final RouteSummary? route = _pickupRoute;
    final LatLng? origin = _pickupRouteOrigin;
    if (route == null || origin == null) return false;
    final double moved = Geolocator.distanceBetween(
        origin.latitude, origin.longitude, driver.latitude, driver.longitude);
    if (moved > _routeReuseMeters) return false;
    setState(() => _setRoutePolyline(route.points));
    return true;
  }

  void _setRoutePolyline(List<LatLng> points) {
    _polylines
      ..clear()
      ..add(Polyline(
        polylineId: const PolylineId("route_0"),
        color: TaarraaColors.light.brandIdentity,
        points: points,
        width: 5,
      ));
  }

  /// Frames the driver, the pickup and the route between them, inside the
  /// map's padding (so above the sheet). Request stage only — every other
  /// stage keeps the camera behaviour it had (DD-28).
  void _fitRequestCamera() {
    final GoogleMapController? controller = _mapController;
    if (controller == null ||
        tripController.state.stage.value != TripStage.requestReceived) {
      return;
    }
    final LatLng pickup = LatLng(args.latPassenger, args.lngPassenger);
    final List<LatLng> points = <LatLng>[
      pickup,
      if (latDriver != null && lngDriver != null && latDriver != 0.0)
        LatLng(latDriver!, lngDriver!),
      ...?_pickupRoute?.points,
    ];

    double south = pickup.latitude, north = pickup.latitude;
    double west = pickup.longitude, east = pickup.longitude;
    for (final LatLng p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    final CameraUpdate update =
        (north - south).abs() < 1e-5 && (east - west).abs() < 1e-5
            ? CameraUpdate.newLatLngZoom(pickup, 16)
            : CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(south, west),
                  northeast: LatLng(north, east),
                ),
                56,
              );
    controller
        .animateCamera(update)
        .catchError((Object e) => tlog("Request camera: $e"));
  }

  void _onSheetHeight(double height) {
    if (!mounted || (height - _sheetHeight).abs() < 1) return;
    setState(() => _sheetHeight = height);
    // Refit once the map has the new padding. `GoogleMap` sends padding
    // from a microtask after this rebuild, so a post-frame refit would reach
    // the platform first — and the padding change would then push the fitted
    // route up under the status bar by half the height difference.
    if (!_pickupRouteLoading) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _fitRequestCamera();
      });
    }
  }

  /// "4 min" — rounded, never below one minute.
  String _formatEta(int seconds) =>
      'UNIT_MIN'.tr(args: <String>['${(seconds / 60).round().clamp(1, 999)}']);

  /// "650 m" under a kilometre, "1.2 km" from there.
  String _formatKm(double km) => km < 1
      ? '${(km * 1000).round()} ${'m'.tr()}'
      : '${km.toStringAsFixed(1)} ${'km'.tr()}';

  /// The request's "≈" fare, with the same [estimateFare] the trip meter
  /// uses. Shown only once the vehicle's per-km price and minimum fare are
  /// both known.
  String? _requestFare() {
    final double? km = _tripDistanceKm;
    if (km == null || !_minimumFareKnown || args.pricrVehicle <= 0) {
      return null;
    }
    final double fare = estimateFare(
      distanceKm: km,
      pricePerKm: args.pricrVehicle,
      minimumFare: priceUnder1Km,
    );
    return formatRielAmount(fare.round().toString());
  }

  void _drawPolylines({
    required LatLng dLocation,
    required LatLng pLocation,
  }) async {
    // Clear existing polylines
    _polylines.clear();
    // Create route
    List<Map<String, LatLng>> routes = [
      {
        'start': dLocation, // Start location (driver's location)
        'end': pLocation, // End location (passenger's location)
      },
    ];
    for (int i = 0; i < routes.length; i++) {
      // Fetch route details
      final List<LatLng> polylineCoordinates = await RouteService.instance
          .route(routes[i]['start']!, routes[i]['end']!);

      // Check if the route was fetched successfully
      if (polylineCoordinates.isNotEmpty) {
        // Add the polyline
        _polylines.add(
          Polyline(
            polylineId: PolylineId("route_$i"),
            color: TaarraaColors.light.brandIdentity, // Set polyline color
            points: polylineCoordinates, // Use the actual route points
            width: 5, // Set polyline width
          ),
        );
        if ((args.desLatPassenger != null && args.desLngPassenger != null) &&
            (tripController.state.stage.value == TripStage.waitingAtPickup ||
                tripController.state.stage.value == TripStage.inProgress)) {
          double distanceAsMeter = await RouteService.instance
              .drivingDistanceKm(LatLng(currentLatDriver, currentLngDriver),
                  LatLng(args.desLatPassenger!, args.desLngPassenger!));
          if (laodCalculateDistance == true) {
            setState(() {
              totalDistance =
                  double.parse(distanceAsMeter.toStringAsFixed(2).toString());
              totalFee = estimateFare(
                distanceKm: totalDistance,
                pricePerKm: args.pricrVehicle,
                minimumFare: priceUnder1Km,
              ).toString();
              laodCalculateDistance = false;
            });
          }
        }
      } else {
        // Log error if route couldn't be fetched
        tlog("Error drawing polyline $i: no route found");
      }
    }
  }

  @override
  void initState() {
    latDriver = args.latDriver;
    lngDriver = args.lngDriver;
    // Was `refreshApp = refreshApp;` — a late field read before it was ever
    // set, which threw LateInitializationError on every trip screen open
    // (surfaced by the QA mock backend, 2026-09-17).
    refreshApp = args.refreshApp;
    // A request opens on the neighbourhood, not the curb; the route fit
    // follows once it is fetched.
    if (tripController.state.stage.value == TripStage.requestReceived) {
      _currentZoom = 16.0;
    }
    ever<TripActionResult?>(tripController.state.lastResult, _onTripAction);
    ever<TripActionError?>(tripController.state.lastError, _onTripError);
    ever<VehicleStatus>(vehicleController.status, _onVehicleStatus);
    vehicleController.getAllVehicles();
    if (tripController.state.stage.value == TripStage.inProgress) {
      if (args.startTime != "" || args.startTime != "null") {
        setState(() {
          remaining =
              Duration(seconds: calculateDuration(args.startTime.toString()));
        });
      }
      startTimer();
    }
    _startLocationListener();
    getLocation(tripController.state.stage.value);
    registerSocket();
    super.initState();
    syncMarker();
    // TaxiLocation.shared.updateCurrentLocationDriver();
    // Timer.periodic(const Duration(seconds: 10), (Timer t) => Taxi.shared.updateDriverLocation());
  }

  void _onVehicleStatus(VehicleStatus status) {
    if (status != VehicleStatus.loaded) return;
    final data = vehicleController.vehicalData.value;
    if (data == null) return;
    final dataTypeVechical =
        data.data.where((element) => element.id == args.typeVehicleId).toList();
    if (dataTypeVechical.isNotEmpty) {
      setState(() {
        priceUnder1Km = dataTypeVechical[0].minimumFare;
        _minimumFareKnown = true;
      });
    }
  }

  void _onTripAction(TripActionResult? result) {
    switch (result) {
      case null:
        break;
      case TripAccepted(:final confirmed):
        final data = confirmed.data!;
        setState(() {
          refreshApp = false;
          getLocation(TripStage.enRouteToPickup);
        });
        socketService.acceptRide(
          driverId: data.driver!.id.toString(),
          bookingId: data.id.toString(),
          passengerId: data.passenger!.id.toString(),
          currentLat: currentLatDriver,
          currentLng: currentLngDriver,
        );
      case TripArrived():
        // Trigger event Arrival to passenger
        socketService.arrivedSocket(
          bookingCode: args.bookingCode.toString(),
          passengerId: args.passengerId.toString(),
          lat: currentLatDriver.toString(),
          lng: currentLngDriver.toString(),
        );
        setState(() {
          refreshApp = false;
          getLocation(TripStage.waitingAtPickup);
        });
      case TripStarted():
        setState(() {
          refreshApp = false;
          getLocation(TripStage.inProgress);
          startTimer();
        });
        // Trigger event Start Ride to passenger
        socketService.startDrive(
          bookingCode: args.bookingCode.toString(),
          bookingId: args.bookingId.toString(),
          passengerId: args.passengerId.toString(),
          currentLat: currentLatDriver,
          currentLng: currentLngDriver,
        );
      case TripCompleted(:final completed):
        setState(() {
          refreshApp = false;
        });
        // Trigger event Drop Driver or End Ride to passenger
        socketService.dropDrive(
          bookingId: args.bookingId.toString(),
          bookingCode: args.bookingCode.toString(),
          passengerId: args.passengerId.toString(),
          currentLat: currentLatDriver,
          currentLng: currentLatDriver, // sic — same as the original
        );
        _navigateToCalculateFee(completed);
      case TripCancelled():
        Get.offAllNamed(AppRoutes.home);
    }
  }

  void _onTripError(TripActionError? error) {
    switch (error) {
      case null:
        break;
      case TripActionError.rideAlreadyAccepted:
        showErrorCustomDialog(context, "RIDE_ALREADY_ACCEPTED".tr(),
            "BOOKING_ALREADY_ACCEPTED".tr(), true);
      case TripActionError.confirmFailed:
        showErrorCustomDialog(context, "COMFIRM_ERROR".tr(),
            "CAN_NOT_CONFIRM_BOOKING".tr(), true);
      case TripActionError.generic:
        showErrorCustomDialog(context, "PLEASE_TRY_AGAIN".tr(),
            "PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG".tr(), true);
    }
  }

  Future<void> _navigateToCalculateFee(CompleteDriverModel data) async {
    String startAddress = await getAddressFromLatLng(
        double.parse(data.data!.startLatitude.toString()),
        double.parse(data.data!.startLongitude.toString()));
    String endAddress = await getAddressFromLatLng(
        double.parse(data.data!.endLatitude.toString()),
        double.parse(data.data!.endLongitude.toString()));
    Get.offNamed(
      AppRoutes.calculateFee,
      arguments: CalculateFeeScreenArgs(
        routFrom: "FromDropBooking",
        dataComplete: data,
        startAddress: startAddress,
        endAddress: endAddress,
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _positionStream?.cancel();
    tripController.dispose();
    super.dispose();
  }

  // Sync markers for driver and passenger locations
  void syncMarker() async {
    driverMarker =
        await loadCustomMarkerTukTuk(typeVehicleId: args.typeVehicleId);
    // DD-35: code-drawn pins — a brand circle at the pickup, a dark square
    // at the destination. `passengerMarker` keeps its MarkerId either way.
    passengerMarker = await loadTripPin(TripPin.pickup);
    destinationPassengerMarker = await loadTripPin(TripPin.destination);
    final stage = tripController.state.stage.value;
    final bool hasDriver = latDriver != null && lngDriver != null;
    final LatLng pickup = LatLng(args.latPassenger, args.lngPassenger);

    Marker driver() => Marker(
          markerId: const MarkerId('driverMarker'),
          position: LatLng(latDriver!, lngDriver!),
          icon: driverMarker,
          rotation: bearing, // rotate in direction of heading
          anchor: const Offset(0.5, 0.5),
          flat: true,
        );
    Marker pin(LatLng position, BitmapDescriptor icon) => Marker(
          markerId: const MarkerId('passengerMarker'),
          position: position,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
        );

    if (args.desLatPassenger != null && stage != TripStage.requestReceived) {
      _putMarker(driver());
      _putMarker(stage == TripStage.enRouteToPickup
          ? pin(pickup, passengerMarker)
          : pin(LatLng(args.desLatPassenger!, args.desLngPassenger!),
              destinationPassengerMarker));
    } else if (stage == TripStage.enRouteToPickup) {
      _putMarker(driver());
      _putMarker(pin(pickup, passengerMarker));
    } else if (stage == TripStage.idle || stage == TripStage.requestReceived) {
      // DD-35: a request shows the driver too, at the other end of the route.
      if (hasDriver && stage == TripStage.requestReceived) {
        _putMarker(driver());
      } else {
        _markers.removeWhere((m) => m.markerId.value == "driverMarker");
      }
      _putMarker(pin(pickup, passengerMarker));
    } else {
      _markers.removeWhere((m) => m.markerId.value == "passengerMarker");
      _putMarker(driver());
    }
    getAddressPlaceMarker();
    setState(() {});
  }

  /// Replaces the marker with the same id. `Set.add` alone kept every
  /// position a marker ever had, one per GPS tick.
  void _putMarker(Marker marker) {
    _markers
      ..removeWhere((Marker m) => m.markerId == marker.markerId)
      ..add(marker);
  }

  _clearPolyline() {
    _polylines.clear();
  }

  // Move the camera to a static LatLng
  void _turnRight() {
    // DD-35: a request's camera is framed once, by [_fitRequestCamera], and
    // not pulled back to the curb on every GPS tick.
    if (tripController.state.stage.value == TripStage.requestReceived) return;
    if (_mapController != null) {
      final stage = tripController.state.stage.value;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              stage == TripStage.requestReceived ||
                      stage == TripStage.enRouteToPickup
                  ? args.latPassenger
                  : latDriver!,
              stage == TripStage.requestReceived ||
                      stage == TripStage.enRouteToPickup
                  ? args.lngPassenger
                  : lngDriver!,
            ), // Use the provided LatLng for camera movement
            zoom: 19.0, // Set zoom level
          ),
        ),
      );
    }
  }

  // Get address for the place marker
  void getAddressPlaceMarker() async {
    currentPassengerPM =
        await getAddressFromLatLng(args.latPassenger, args.lngPassenger);
    // destinationPassengerPM = await getAddressFromLatLng(pDesLat, pDesLng);
    setState(() {});
  }

  /// The stage's name — the same four keys the app bar used before C3.
  String _stageTitle(TripStage stage) {
    switch (stage) {
      case TripStage.requestReceived:
        return "STAGE_NEW_REQUEST".tr();
      case TripStage.enRouteToPickup:
        return "STAGE_GO_TO_PICKUP".tr();
      case TripStage.waitingAtPickup:
        return "STAGE_AT_PICKUP".tr();
      default:
        return "STAGE_ON_TRIP".tr();
    }
  }

  /// The stage header floating over the top of the map. The app bar used to
  /// provide the status-bar inset, so this claims it with a SafeArea.
  ///
  /// DD-35: not shown on a request. The sheet names the stage, the decision
  /// timer moved into Accept, and the map above the sheet is left to the
  /// route.
  Widget _topOverlay(BuildContext context, TripStage stage) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.s16,
            vertical: Insets.s8,
          ),
          child: TripHeader(
            stage: stage,
            title: _stageTitle(stage),
            bookingCode: args.bookingCode,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // C3 / DD-10: no app bar. The map runs full-bleed and the stage title
      // moved into the floating header over it.
      body: PopScope(
        canPop: false,
        child: Obx(() {
          final stage = tripController.state.stage.value;
          bool isLoading = tripController.state.isLoading.value;

          // C4 / DD-14: the meter's values are the exact expressions the old
          // top-of-map strip used, moved unchanged into the sheet. The strip
          // itself only prefixes the "≈", so the fare logic cannot drift.
          final String meterDuration = formatDuration(remaining);
          final String meterDistance = (args.desLatPassenger == null ||
                  args.desLatPassenger == 0.0)
              ? convertMaterToKm(double.parse(totalDistanceCount.toString()))
              : convertKmToKmM(double.parse(totalDistance.toString()));
          final String meterFare =
              (args.desLatPassenger == null || args.desLatPassenger == 0.0)
                  ? totalDistanceCount <= 1000
                      ? formatRielAmount(priceUnder1Km.toString())
                      : formatRielAmount(totalFee)
                  : formatRielAmount(totalFee);
          return Stack(
            children: [
              GoogleMap(
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                mapType: MapType.normal,
                // DD-28/DD-35: the camera works inside the visible map —
                // below the status bar, above the sheet.
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                  bottom: _sheetHeight,
                ),
                myLocationEnabled: false,
                indoorViewEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                // A request is decided at a glance, not explored.
                zoomControlsEnabled: stage != TripStage.requestReceived,
                zoomGesturesEnabled: true,
                mapToolbarEnabled: stage != TripStage.requestReceived,
                polylines: _polylines,
                markers: _markers,
                initialCameraPosition: CameraPosition(
                  // bearing: 192.8334901395799,
                  target: LatLng(args.latPassenger, args.lngPassenger),
                  tilt: 0.0,
                  zoom: _currentZoom,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (!_pickupRouteLoading) _fitRequestCamera();
                },
                onCameraMove: (CameraPosition position) {
                  setState(() {
                    _currentZoom = position.zoom;
                  });
                },
              ),
              if (stage != TripStage.requestReceived)
                _topOverlay(context, stage),
              ModelBottomSheetNewRequestWidget(
                isLoading: isLoading || _dropPending,
                duration: meterDuration,
                distance: meterDistance,
                fare: meterFare,
                totalFee: totalFee,
                distandTotal: totalDistance,
                bookingCode: args.bookingCode,
                passengerId: args.passengerId,
                bookingId: args.bookingId,
                namePassanger: args.namePassanger,
                phonePassanger: args.phonePassanger,
                profilePassanger: args.imagePassanger,
                whereToGoLocationName: destinationPassengerPM,
                passegerLocationName: currentPassengerPM,
                processType: stage.toProcessStep(),
                pickupEta: _pickupRoute == null
                    ? null
                    : _formatEta(_pickupRoute!.durationSeconds),
                pickupDistance: _pickupRoute == null
                    ? null
                    : _formatKm(_pickupRoute!.distanceMeters / 1000),
                pickupRouteLoading: _pickupRouteLoading,
                tripDistance: _tripDistanceKm == null
                    ? null
                    : _formatKm(_tripDistanceKm!),
                tripFare: _requestFare(),
                requestTimeoutSeconds: args.timeOut,
                onHeightChanged: _onSheetHeight,
                onCancel: tripController.cancel,
                onTap: () {
                  if (stage == TripStage.requestReceived) {
                    tripController.accept();
                  } else if (stage == TripStage.enRouteToPickup) {
                    tripController.arrive();
                  } else if (stage == TripStage.waitingAtPickup) {
                    tripController.start();
                  } else if (stage == TripStage.inProgress) {
                    // C4: the spinner starts at the tap, not after the
                    // reverse-geocode round trip inside `getLocation`.
                    setState(() => _dropPending = true);
                    getLocation(TripStage.completing);
                  }
                },
              ),
              // C3 / DD-17: the full-screen LoadingWidget is gone. The tapped
              // action shows its own spinner and every other trip action is
              // disabled while `isLoading` — including Cancel, which emits
              // `driverCancelDrive` before the controller's guard runs and so
              // must never be tappable mid-accept.
            ],
          );
        }),
      ),
    );
  }
}
