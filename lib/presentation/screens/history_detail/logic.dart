import 'dart:async';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/load_custom_marker.dart';

import 'state.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';

/// Was `_MapHistoryDetailScreenState`. Marker loading and Directions-API
/// polyline fetching are I/O, so they move off the widget (`14` §3.3); the
/// map's own `GoogleMapController` stays in the view, since it is a Flutter
/// type and `14` §3.3 keeps those out of logic.
class HistoryDetailLogic extends GetxController {
  HistoryDetailLogic({
    required this.typeVehicleId,
    required this.cost,
    required this.distand,
    required this.duration,
    required this.latStart,
    required this.lngStart,
    required this.latEnd,
    required this.lngEnd,
  });

  final int typeVehicleId;
  final String cost;
  final String distand;
  final String duration;
  final double latStart;
  final double lngStart;
  final double latEnd;
  final double lngEnd;

  final HistoryDetailState state = HistoryDetailState();
  final PolylinePoints _polylinePoints = PolylinePoints();

  Timer? _startupTimer;

  LatLng get start => LatLng(latStart, lngStart);
  LatLng get end => LatLng(latEnd, lngEnd);

  @override
  void onInit() {
    super.onInit();
    // The 1s delay is carried over from the old screen — the map platform
    // view needs to exist before markers land on it.
    _startupTimer = Timer(const Duration(seconds: 1), () {
      syncMarker();
      drawPolylines();
    });
  }

  @override
  void onClose() {
    _startupTimer?.cancel();
    super.onClose();
  }

  Future<void> syncMarker() async {
    final driverMarker =
        await loadCustomMarkerTukTuk(typeVehicleId: typeVehicleId);
    final passengerMarker = await loadCustomMarker();
    state.markers.addAll({
      Marker(
        markerId: const MarkerId('driverMarker'),
        position: start,
        icon: driverMarker,
      ),
      Marker(
        markerId: const MarkerId('passengerMarker'),
        position: end,
        icon: passengerMarker,
      ),
    });
  }

  Future<void> drawPolylines() async {
    final result = await _polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: AppConstant.googleKeyApi,
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        mode: TravelMode.driving,
      ),
    );
    if (result.status == 'OK' && result.points.isNotEmpty) {
      state.polylines.add(
        Polyline(
          polylineId: const PolylineId("route_0"),
          color: TaarraaColors.light.brandIdentity,
          points: result.points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
          width: 5,
        ),
      );
    }
  }
}
