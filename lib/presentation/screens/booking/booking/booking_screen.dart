import 'dart:async';

import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/helper/get_address_latlng_helper.dart';
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/routing/route_arguments.dart';
import 'package:tara_driver_application/core/storages/get_storages.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/calculate_distance.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:tara_driver_application/data/models/register_model.dart';
import 'package:tara_driver_application/presentation/blocs/vehical_bloc.dart';
import 'package:tara_driver_application/presentation/screens/booking/booking/bloc/booking_bloc.dart';
import 'package:tara_driver_application/presentation/screens/booking/booking/widgets/ride_request_bottom_pop_widget.dart';
import 'package:tara_driver_application/presentation/screens/booking/booking/widgets/show_distand_and_price_widget.dart';
import 'package:tara_driver_application/presentation/widgets/count_down_widget.dart';
import 'package:tara_driver_application/presentation/widgets/error_dialog_widget.dart';
import 'package:tara_driver_application/presentation/widgets/loading_widget.dart';
import 'package:tara_driver_application/services/location_service.dart';
import 'package:tara_driver_application/taxi_single_ton/init_socket.dart';
import 'package:tara_driver_application/taxi_single_ton/taxi.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingScreen extends StatefulWidget {
  final int bookingId;
  final int bookingCode;
  final int passengerId;
  double latPassenger;
  double lngPassenger;
  double? desLatPassenger;
  double? desLngPassenger;
  double? latDriver;
  double? lngDriver;
  int processStepBook;
  int timeOut;
  String namePassanger;
  String imagePassanger;
  String phonePassanger;
  int typeVehicleId;
  int pricrVehicle;
  bool refreshApp;

  double latStart;
  double lngStart;
  String startTime;

  BookingScreen({
    super.key,
    required this.startTime,
    required this.lngStart,
    required this.latStart,
    required this.typeVehicleId,
    required this.pricrVehicle,
    required this.bookingId,
    required this.bookingCode,
    required this.latPassenger,
    required this.lngPassenger,
    required this.processStepBook,
    required this.desLatPassenger,
    required this.desLngPassenger,
    this.latDriver,
    this.lngDriver,
    required this.timeOut,
    required this.passengerId,
    required this.namePassanger,
    required this.phonePassanger,
    required this.imagePassanger,
    required this.refreshApp,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
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
  // * Socket Class
  DriverSocketService driverSocket = DriverSocketService();
  // * Register Socket
  void registerSocket() async {
    RegisterModel? driverData = await StorageGet.getDriverData();
    if (driverData?.data?.driver?.id != null) {
      driverSocket.connectToSocket(
        AppConstant.socketBasedUrl,
        "${driverData?.data?.driver?.id}",
        "Driver",
        context: context,
      );
    }
  }

  Future<void> _launchLink(String url) async {
    if (await launchUrl(Uri.parse(url))) {
    } else {
      await launchUrl(
        Uri.parse(url),
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
    _positionStream =
        LocationService.instance.positionStream.listen((Position position) async {
      LatLng current = LatLng(position.latitude, position.longitude);
      setState(() {
        bearing = position.heading;
        currentLatDriver = position.latitude;
        currentLngDriver = position.longitude;
        widget.latDriver = position.latitude;
        widget.lngDriver = position.longitude;
        _turnRight();
        syncMarker();
      });
      if (widget.processStepBook == 4 &&
          (widget.desLatPassenger == null || widget.desLatPassenger == 0.0)) {
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
              totalFee = totalDistanceCount <= 1000
                  ? "$priceUnder1Km"
                  : "${(((totalDistanceCount / 1000) - 1.0) * widget.pricrVehicle) + priceUnder1Km}";
              _lastPosition = current;
            });
          }
        } else {
          _lastPosition = current;
        }
      }
    });
  }

  void getLocation(int processStep) async {
    // Type  0 = initScreen, 1 = accept ,2 = arrive, 3 = start, 4 = drop;
    Position? position = await Geolocator.getCurrentPosition();
    destinationPassengerPM =
        widget.desLatPassenger != null && widget.desLngPassenger != null
            ? await getAddressFromLatLng(
                widget.desLatPassenger!, widget.desLngPassenger!)
            : "";
    if (position != null) {
      if (processStep == 1) {
        setState(() {
          currentLatDriver = position.latitude;
          currentLngDriver = position.longitude;
          widget.latDriver = position.latitude;
          widget.lngDriver = position.longitude;
        });

        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            widget.processStepBook = 1;
          });
        });
      } else if (processStep == 2) {
        if (widget.refreshApp == true) {
          currentAddressDriver =
              await getAddressFromLatLng(widget.latDriver!, widget.lngDriver!);
        } else {
          currentAddressDriver =
              await getAddressFromLatLng(position.latitude, position.longitude);
        }
        setState(() {
          currentLatDriver = position.latitude;
          currentLngDriver = position.longitude;
          widget.latDriver = position.latitude;
          widget.lngDriver = position.longitude;
        });
        _drawPolylines(
            dLocation: LatLng(currentLatDriver, currentLngDriver),
            pLocation: LatLng(widget.latPassenger, widget.lngPassenger));
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            widget.processStepBook = 2;
          });
        });
      } else if (processStep == 3) {
        if (widget.refreshApp == true) {
          currentAddressDriver =
              await getAddressFromLatLng(widget.latDriver!, widget.lngDriver!);
        } else {
          currentAddressDriver =
              await getAddressFromLatLng(position.latitude, position.longitude);
        }
        setState(() {
          currentLatDriver = position.latitude;
          currentLngDriver = position.longitude;
          widget.latDriver = position.latitude;
          widget.lngDriver = position.longitude;
        });

        if (widget.desLngPassenger != null) {
          _drawPolylines(
              dLocation: LatLng(currentLatDriver, currentLngDriver),
              pLocation:
                  LatLng(widget.desLatPassenger!, widget.desLngPassenger!));
        } else {
          _clearPolyline();
        }
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            widget.processStepBook = 3;
          });
        });
      } else if (processStep == 4) {
        if (widget.refreshApp == true) {
          currentAddressDriver =
              await getAddressFromLatLng(widget.latDriver!, widget.lngDriver!);
          if (widget.latStart != 0.0) {
            totalDistanceCount = (await AsyncDistance().calculateDistance(
                    LatLng(position.latitude, position.longitude),
                    LatLng(widget.latStart, widget.lngStart)) *
                1000);
            totalFee = totalDistanceCount <= 1000
                ? "$priceUnder1Km"
                : "${(((totalDistanceCount / 1000) - 1.0) * widget.pricrVehicle) + priceUnder1Km}";
          }
        } else {
          currentAddressDriver =
              await getAddressFromLatLng(position.latitude, position.longitude);
        }
        setState(() {
          currentLatDriver = position.latitude;
          currentLngDriver = position.longitude;
          widget.latDriver = position.latitude;
          widget.lngDriver = position.longitude;
        });

        if (widget.desLngPassenger != null) {
          _drawPolylines(
              dLocation: LatLng(currentLatDriver, currentLngDriver),
              pLocation:
                  LatLng(widget.desLatPassenger!, widget.desLngPassenger!));
        }

        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            widget.processStepBook = 4;
          });
        });
      } else if (processStep == 6) {
        debugPrint("drop - total distance ${Taxi.shared.totalDistance}");
        dropAddressDriver =
            await getAddressFromLatLng(position.latitude, position.longitude);
        setState(() {
          dropLatDriver = position.latitude;
          dropLngDriver = position.longitude;
        });
        BlocProvider.of<BookingBloc>(context).add(CompletedTripEvent(
          distance: widget.desLatPassenger == null
              ? double.parse(
                  (totalDistanceCount / 1000).toStringAsFixed(3).toString())
              : totalDistance,
          rideId: widget.bookingId,
          endAddress: dropAddressDriver,
          endLatitude: dropLatDriver,
          endLongitude: dropLngDriver,
        ));
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
            color: Colors.red, // Set polyline color
            points: polylineCoordinates, // Use the actual route points
            width: 5, // Set polyline width
          ),
        );
        if ((widget.desLatPassenger != null ||
                widget.desLatPassenger != null) &&
            (widget.processStepBook == 3 || widget.processStepBook == 4)) {
          double distanceAsMeter = await AsyncDistance().calculateDistance(
              LatLng(currentLatDriver, currentLngDriver),
              LatLng(widget.desLatPassenger!, widget.desLngPassenger!));
          if (laodCalculateDistance == true) {
            setState(() {
              totalDistance =
                  double.parse(distanceAsMeter.toStringAsFixed(2).toString());
              totalFee = totalDistance <= 1.0
                  ? "$priceUnder1Km"
                  : "${((totalDistance - 1.0) * widget.pricrVehicle) + priceUnder1Km}";
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
    BlocProvider.of<VehicalBloc>(context).add(GetAllVehicalEvent());
    if (widget.processStepBook == 4) {
      if (widget.startTime != "" || widget.startTime != "null") {
        setState(() {
          remaining =
              Duration(seconds: calculateDuration(widget.startTime.toString()));
        });
      }
      startTimer();
    }
    _startLocationListener();
    getLocation(widget.processStepBook);
    registerSocket();
    super.initState();
    polylinePoints = PolylinePoints();
    syncMarker();
    // TaxiLocation.shared.updateCurrentLocationDriver();
    // Timer.periodic(const Duration(seconds: 10), (Timer t) => Taxi.shared.updateDriverLocation());
  }

  @override
  void dispose() {
    timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  // Sync markers for driver and passenger locations
  void syncMarker() async {
    driverMarker =
        await loadCustomMarkerTukTuk(typeVehicleId: widget.typeVehicleId);
    passengerMarker = await loadCustomMarker();
    if (widget.desLatPassenger != null && widget.processStepBook != 1) {
      _markers
        ..add(Marker(
          markerId: const MarkerId('driverMarker'),
          position: LatLng(widget.latDriver!, widget.lngDriver!),
          icon: driverMarker,
          rotation: bearing, // rotate in direction of heading
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ))
        ..add(Marker(
          markerId: const MarkerId('passengerMarker'),
          position: widget.processStepBook == 2
              ? LatLng(widget.latPassenger, widget.lngPassenger)
              : LatLng(widget.desLatPassenger!, widget.desLngPassenger!),
          icon: passengerMarker,
        ));
    } else if (widget.processStepBook == 2) {
      _markers
        ..add(Marker(
          markerId: const MarkerId('driverMarker'),
          position: LatLng(widget.latDriver!, widget.lngDriver!),
          icon: driverMarker,
          rotation: bearing, // rotate in direction of heading
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ))
        ..add(Marker(
          markerId: const MarkerId('passengerMarker'),
          position: LatLng(widget.latPassenger, widget.lngPassenger),
          icon: passengerMarker,
        ));
    } else if (widget.processStepBook == 0 || widget.processStepBook == 1) {
      _markers.removeWhere((m) => m.markerId.value == "driverMarker");
      _markers.add(Marker(
        markerId: const MarkerId('passengerMarker'),
        position: LatLng(widget.latPassenger, widget.lngPassenger),
        icon: passengerMarker,
      ));
    } else {
      _markers.removeWhere((m) => m.markerId.value == "passengerMarker");
      _markers.add(Marker(
        markerId: const MarkerId('driverMarker'),
        position: LatLng(widget.latDriver!, widget.lngDriver!),
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
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              widget.processStepBook == 1 || widget.processStepBook == 2
                  ? widget.latPassenger
                  : widget.latDriver!,
              widget.processStepBook == 1 || widget.processStepBook == 2
                  ? widget.lngPassenger
                  : widget.lngDriver!,
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
        await getAddressFromLatLng(widget.latPassenger, widget.lngPassenger);
    // destinationPassengerPM = await getAddressFromLatLng(pDesLat, pDesLng);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          widget.processStepBook == 1
              ? "NEW_RIDE_REQUEST".tr()
              : widget.processStepBook == 2
                  ? "GO_TO_PASSENGER".tr()
                  : widget.processStepBook == 3
                      ? "PREPAIR_TO_GO".tr()
                      : "CARRYING_PASSENGER".tr(),
        ),
      ),
      body: PopScope(
        canPop: false,
        child: BlocConsumer<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is BookingLoading) {
              tlog("Booking Loading");
            } else if (state is CancelBookingSuccess) {
              Get.offAllNamed(AppRoutes.home);
            } else if (state is ConfirmBookingSuccess) {
              var dataConfirmBooking = state.confirmBookingModel.data;
              if (dataConfirmBooking != null) {
                setState(() {
                  widget.processStepBook = 2;
                  widget.refreshApp = false;
                  getLocation(2);
                });
                Future.delayed(Duration(seconds: 1), () {
                  setState(() {
                    widget.processStepBook = 2;
                  });
                });
                socketService.acceptRide(
                    driverId: dataConfirmBooking.driver!.id.toString(),
                    bookingId: dataConfirmBooking.id.toString(),
                    passengerId: dataConfirmBooking.passenger!.id.toString(),
                    currentLat: currentLatDriver,
                    currentLng: currentLngDriver);
              } else if (state.confirmBookingModel.message ==
                  "RIDE_ALREADY_ACCEPTED") {
                showErrorCustomDialog(context, "RIDE_ALREADY_ACCEPTED".tr(),
                    "BOOKING_ALREADY_ACCEPTED".tr(), true);
              } else {
                showErrorCustomDialog(context, "COMFIRM_ERROR".tr(),
                    "CAN_NOT_CONFIRM_BOOKING".tr(), true);
              }
            } else if (state is StartTripSuccess) {
              setState(() {
                widget.processStepBook = 4;
                widget.refreshApp = false;
                getLocation(4);
                startTimer();
              });
              Future.delayed(Duration(seconds: 1), () {
                setState(() {
                  widget.processStepBook = 4;
                });
              });
              // Trigger event Start Ride to passenger
              socketService.startDrive(
                bookingCode: widget.bookingCode.toString(),
                bookingId: widget.bookingId.toString(),
                passengerId: widget.passengerId.toString(),
                currentLat: currentLatDriver,
                currentLng: currentLngDriver,
              );
            } else if (state is ArriveSuccess) {
              // Trigger event Arrival to passenger
              socketService.arrivedSocket(
                bookingCode: widget.bookingCode.toString(),
                passengerId: widget.passengerId.toString(),
                lat: currentLatDriver.toString(),
                lng: currentLngDriver.toString(),
              );
              setState(() {
                widget.processStepBook = 3;
                widget.refreshApp = false;
                getLocation(3);
              });
              Future.delayed(Duration(seconds: 1), () {
                setState(() {
                  widget.processStepBook = 3;
                });
              });
            } else if (state is CompletedTripSuccess) {
              setState(() {
                // widget.processStepBook = 6;
                widget.refreshApp = false;
                // getLocation(6);
              });
              // Future.delayed(Duration(seconds: 1),(){
              //   setState(() {
              //     widget.processStepBook = 6;
              //   });
              // });
              // Trigger event Drop Driver or End Ride to passenger
              socketService.dropDrive(
                bookingId: widget.bookingId.toString(),
                bookingCode: widget.bookingCode.toString(),
                passengerId: widget.passengerId.toString(),
                currentLat: currentLatDriver,
                currentLng: currentLatDriver,
              );
              setState(() async {
                var data = state.completeDriver;
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
              });
            } else {
              showErrorCustomDialog(context, "PLEASE_TRY_AGAIN".tr(),
                  "PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG".tr(), true);
            }
          },
          builder: (context, state) {
            bool isLoading = state is BookingLoading;
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
                    target: LatLng(widget.latPassenger, widget.lngPassenger),
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
                BlocListener<VehicalBloc, VehicalState>(
                  listener: (context, state) {
                    if (state is VehicalLoaded) {
                      var data = state.vehicalData;
                      var dataTypeVechical = data.data
                          .where(
                              (element) => element.id == widget.typeVehicleId)
                          .toList();
                      if (dataTypeVechical.isNotEmpty) {
                        setState(() {
                          priceUnder1Km = dataTypeVechical[0].minimumFare;
                        });
                      }
                    }
                  },
                  child: Container(
                    height: 0,
                  ),
                ),
                widget.processStepBook == 4
                    ? ShowDistandWidget(
                        distand: (widget.desLatPassenger == null ||
                                widget.desLatPassenger == 0.0)
                            ? convertMaterToKm(
                                double.parse(totalDistanceCount.toString()))
                            : convertKmToKmM(
                                double.parse(totalDistance.toString())),
                        cost: (widget.desLatPassenger == null ||
                                widget.desLatPassenger == 0.0)
                            ? totalDistanceCount <= 1000
                                ? formatToTwoDecimalPlaces(
                                    priceUnder1Km.toString())
                                : formatToTwoDecimalPlaces(totalFee)
                            : formatToTwoDecimalPlaces(totalFee),
                        duration: formatDuration(remaining),
                      )
                    : Container(
                        height: 0,
                      ),
                widget.processStepBook == 1
                    ? Positioned(
                        top: 60,
                        left: 0,
                        right: 0,
                        child: SmoothCircularCountdown(
                          countDuration: widget.timeOut,
                          isPop: true,
                        ),
                      )
                    : const SizedBox(),
                ModelBottomSheetNewRequestWidget(
                  totalFee: totalFee,
                  distandTotal: totalDistance,
                  bookingCode: widget.bookingCode,
                  passengerId: widget.passengerId,
                  bookingId: widget.bookingId,
                  namePassanger: widget.namePassanger,
                  phonePassanger: widget.phonePassanger,
                  profilePassanger: widget.imagePassanger,
                  currentLocationName: currentAddressDriver,
                  whereToGoLocationName: destinationPassengerPM,
                  passegerLocationName: currentPassengerPM,
                  processType: widget.processStepBook,
                  onTap: () {
                    if (widget.processStepBook == 1) {
                      setState(() {
                        BlocProvider.of<BookingBloc>(context).add(
                          ConfirmBookingEvent(
                            rideId: int.parse(widget.bookingId.toString()),
                          ),
                        );
                        debugPrint("accept and get positon");
                      });
                    } else if (widget.processStepBook == 2) {
                      BlocProvider.of<BookingBloc>(context).add(
                        ArrivedEvent(
                          rideId: widget.bookingId,
                        ),
                      );
                    } else if (widget.processStepBook == 3) {
                      BlocProvider.of<BookingBloc>(context).add(
                        StartTripEvent(
                          rideId: widget.bookingId,
                        ),
                      );
                    } else if (widget.processStepBook == 4) {
                      setState(() {
                        widget.processStepBook = 6;
                        getLocation(6);
                      });
                    } else {
                      setState(() {
                        isLoading = true;
                      });
                    }
                  },
                ),
                if (isLoading) const Positioned(child: LoadingWidget()),
              ],
            );
          },
        ),
      ),
    );
  }
}
