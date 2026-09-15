import 'dart:async';

import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/helper/get_address_latlng_helper.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/core/storage/get_storages.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/calculate_distance.dart';
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
import 'package:tara_driver_application/presentation/widgets/count_down_widget.dart';
import 'package:tara_driver_application/presentation/widgets/error_dialog_widget.dart';
import 'package:tara_driver_application/services/location_service.dart';
import 'package:tara_driver_application/services/socket_service.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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
  late PolylinePoints polylinePoints;

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
    Position? position = await Geolocator.getCurrentPosition();
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
        _drawPolylines(
            dLocation: LatLng(currentLatDriver, currentLngDriver),
            pLocation: LatLng(args.latPassenger, args.lngPassenger));
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
            totalDistanceCount = (await AsyncDistance().calculateDistance(
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
    }
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
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: AppConstant.googleKeyApi,
        request: PolylineRequest(
          origin: PointLatLng(
              routes[i]['start']!.latitude, routes[i]['start']!.longitude),
          destination: PointLatLng(
              routes[i]['end']!.latitude, routes[i]['end']!.longitude),
          mode: TravelMode.driving,
        ),
      );

      // Check if the route was fetched successfully
      if (result.status == 'OK' && result.points.isNotEmpty) {
        // Extract polyline coordinates
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

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
          double distanceAsMeter = await AsyncDistance().calculateDistance(
              LatLng(currentLatDriver, currentLngDriver),
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
        tlog("Error drawing polyline $i: ${result.errorMessage}");
      }
    }
  }

  @override
  void initState() {
    latDriver = args.latDriver;
    lngDriver = args.lngDriver;
    refreshApp = refreshApp;
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
    polylinePoints = PolylinePoints();
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
    passengerMarker = await loadCustomMarker();
    final stage = tripController.state.stage.value;
    if (args.desLatPassenger != null && stage != TripStage.requestReceived) {
      _markers
        ..add(Marker(
          markerId: const MarkerId('driverMarker'),
          position: LatLng(latDriver!, lngDriver!),
          icon: driverMarker,
          rotation: bearing, // rotate in direction of heading
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ))
        ..add(Marker(
          markerId: const MarkerId('passengerMarker'),
          position: stage == TripStage.enRouteToPickup
              ? LatLng(args.latPassenger, args.lngPassenger)
              : LatLng(args.desLatPassenger!, args.desLngPassenger!),
          icon: passengerMarker,
        ));
    } else if (stage == TripStage.enRouteToPickup) {
      _markers
        ..add(Marker(
          markerId: const MarkerId('driverMarker'),
          position: LatLng(latDriver!, lngDriver!),
          icon: driverMarker,
          rotation: bearing, // rotate in direction of heading
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ))
        ..add(Marker(
          markerId: const MarkerId('passengerMarker'),
          position: LatLng(args.latPassenger, args.lngPassenger),
          icon: passengerMarker,
        ));
    } else if (stage == TripStage.idle || stage == TripStage.requestReceived) {
      _markers.removeWhere((m) => m.markerId.value == "driverMarker");
      _markers.add(Marker(
        markerId: const MarkerId('passengerMarker'),
        position: LatLng(args.latPassenger, args.lngPassenger),
        icon: passengerMarker,
      ));
    } else {
      _markers.removeWhere((m) => m.markerId.value == "passengerMarker");
      _markers.add(Marker(
        markerId: const MarkerId('driverMarker'),
        position: LatLng(latDriver!, lngDriver!),
        icon: driverMarker,
        rotation: bearing, // rotate in direction of heading
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }
    getAddressPlaceMarker();
    setState(() {});
  }

  _clearPolyline() {
    _polylines.clear();
  }

  // Move the camera to a static LatLng
  void _turnRight() {
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

  /// Everything floating over the top of the map: the stage header and the
  /// request countdown. The app bar used to provide the status-bar inset, so
  /// this claims it with a SafeArea.
  Widget _topOverlay(BuildContext context, TripStage stage) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
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
            if (stage == TripStage.requestReceived)
              Padding(
                padding: const EdgeInsets.only(top: Insets.s8),
                child: SmoothCircularCountdown(
                  countDuration: args.timeOut,
                  isPop: true,
                ),
              ),
          ],
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
                myLocationEnabled: false,
                indoorViewEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                mapToolbarEnabled: true,
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
                },
                onCameraMove: (CameraPosition position) {
                  setState(() {
                    _currentZoom = position.zoom;
                  });
                },
              ),
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
