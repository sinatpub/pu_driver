import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MovingMarkerMap extends StatefulWidget {
  @override
  State<MovingMarkerMap> createState() => _MovingMarkerMapState();
}

class _MovingMarkerMapState extends State<MovingMarkerMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Location _location = Location();
  StreamSubscription<LocationData>? _locationSub;

  @override
  void initState() {
    super.initState();
    _listenLocation();
  }

  void _listenLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Request permissions
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    // Listen to location changes
    _locationSub = _location.onLocationChanged.listen((loc) {
      if (loc.latitude != null && loc.longitude != null) {
        _updateMarker(
          LatLng(loc.latitude!, loc.longitude!),
          loc.heading ?? 0, // heading in degrees (for rotation)
        );

        // Optionally move camera
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(loc.latitude!, loc.longitude!),
          ),
        );
      }
    });
  }

  void _updateMarker(LatLng position, double bearing) {
    final marker = Marker(
      markerId: const MarkerId("moving_marker"),
      position: position,
      icon: BitmapDescriptor.defaultMarker,
      rotation: bearing, // rotate in direction of heading
      anchor: const Offset(0.5, 0.5),
      flat: true,
    );

    setState(() {
      _markers = {marker};
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(11.5564, 104.9282),
          zoom: 19,
        ),
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}