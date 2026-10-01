import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/core/utils/load_custom_marker.dart';
import 'package:tara_driver_application/presentation/screens/history_detail/contact_window.dart'
    as contact_window;
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/services/route_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'state.dart';

/// Was `_MapHistoryDetailScreenState`. Marker loading and Directions-API
/// polyline fetching are I/O, so they move off the widget (`14` §3.3); the
/// map's own `GoogleMapController` stays in the view, since it is a Flutter
/// type and `14` §3.3 keeps those out of logic.
///
/// DD-42: holds the whole trip ([args]), marks the pickup and destination
/// with the trip screen's pins instead of a car and a person, and owns the
/// two ways to reach the passenger about a lost item.
class HistoryDetailLogic extends GetxController {
  HistoryDetailLogic(this.args, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final MapHistoryDetailArgs args;
  final DateTime Function() _now;

  final HistoryDetailState state = HistoryDetailState();

  Timer? _startupTimer;

  LatLng get start => LatLng(args.latStart, args.lngStart);
  LatLng get end => LatLng(args.latEnd, args.lngEnd);

  /// True for 24 hours after the trip ended, when there is a number to call.
  bool get canCallPassenger => contact_window.canCallPassenger(
        endedAt: args.endedAt,
        phone: args.passengerPhone,
        now: _now(),
      );

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
    final BitmapDescriptor pickup = await loadTripPin(TripPin.pickup);
    final BitmapDescriptor destination = await loadTripPin(TripPin.destination);
    state.markers.addAll(<Marker>{
      Marker(
        markerId: const MarkerId('pickupMarker'),
        position: start,
        icon: pickup,
        anchor: const Offset(0.5, 0.5),
      ),
      Marker(
        markerId: const MarkerId('destinationMarker'),
        position: end,
        icon: destination,
        anchor: const Offset(0.5, 0.5),
      ),
    });
  }

  Future<void> drawPolylines() async {
    final points = await RouteService.instance.route(start, end);
    if (points.isNotEmpty) {
      state.polylines.add(
        Polyline(
          polylineId: const PolylineId("route_0"),
          color: TaarraaColors.light.brandIdentity,
          points: points,
          width: 5,
        ),
      );
    }
  }

  /// Dials the passenger. Only offered while [canCallPassenger]; checked
  /// again here so a screen left open past the window cannot still call.
  Future<void> callPassenger() async {
    if (!canCallPassenger) return;
    await _dial(args.passengerPhone!.trim());
  }

  /// Dials one of the company's support lines.
  Future<void> callSupport(String phoneNumber) => _dial(phoneNumber);

  Future<void> _dial(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $phoneNumber');
    }
  }
}
