import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';
import 'package:tara_driver_application/core/utils/load_custom_marker.dart';
import 'package:tara_driver_application/presentation/screens/booking/booking/widgets/show_distand_and_price_widget.dart';

class MapHistoryDetailScreen extends StatefulWidget {
  double latStart;
  double lngStart;
  double latEnd;
  double lngEnd;
  String distand;
  String cost;
  String duration;
  int typeVehicleId;
  MapHistoryDetailScreen({super.key,required this.typeVehicleId,required this.cost,required this.distand,required this.duration,required this.latStart,required this.lngStart,required this.latEnd,required this.lngEnd});

  @override
  State<MapHistoryDetailScreen> createState() => _MapHistoryDetailScreenState();
}

class _MapHistoryDetailScreenState extends State<MapHistoryDetailScreen> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;
  late BitmapDescriptor driverMarker;
  late BitmapDescriptor passengerMarker;
  GoogleMapController? _mapController;


  void syncMarker() async {
    driverMarker = await loadCustomMarkerTukTuk(typeVehicleId: widget.typeVehicleId);
    passengerMarker = await loadCustomMarker();
      _markers
      ..add(Marker(
          markerId: const MarkerId('driverMarker'),
          position: LatLng(widget.latStart,widget.lngStart),
          icon: driverMarker,
        ))
        ..add(Marker(
          markerId: const MarkerId('passengerMarker'),
          position:LatLng(widget.latEnd, widget.lngEnd),
          icon: passengerMarker,
        )
      );
  }

  void _drawPolylines() async {
    List<Map<String, LatLng>> routes = [
      {
        'start': LatLng(widget.latStart, widget.lngStart,),
        'end': LatLng(widget.latEnd, widget.lngEnd),
      },
    ];
    for (int i = 0; i < routes.length; i++) {
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
      if (result.status == 'OK' && result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        _polylines.add(
          Polyline(
            polylineId: PolylineId("route_$i"),
            color: Colors.red, 
            points: polylineCoordinates,
            width: 5, 
          ),
        );
      }
      setState(() {});
    }
  }

  @override
  void initState() {
    polylinePoints = PolylinePoints();
    Future.delayed(Duration(seconds: 1),(){
      setState(() {
        polylinePoints = PolylinePoints();
        syncMarker();
        _drawPolylines();
      });
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light3,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(onPressed: (){
                    Navigator.of(context).pop();
                  }, icon: Icon(Icons.arrow_back_ios_new_rounded,size: 28,)),
                ],
              ),
            ),
            Expanded(
              child: Stack(
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
                      target: LatLng(widget.latStart, widget.lngStart),
                      tilt: 0.0,
                      zoom: 17.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                  ),
                  ShowDistandWidget(
                    distand: widget.distand,
                    cost: widget.cost.toString(),
                    duration: widget.duration.toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}