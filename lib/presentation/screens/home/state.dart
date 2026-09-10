import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationLoadStatus { inProgress, success, permissionDenied, failure }

class HomeState {
  final Rx<LocationLoadStatus> locationStatus =
      Rx<LocationLoadStatus>(LocationLoadStatus.inProgress);
  final RxnString locationError = RxnString();
  final Rxn<LatLng> currentLocation = Rxn<LatLng>();

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxDouble currentZoom = 19.0.obs;

  /// The driver's vehicle type, learned from the profile fetch — decides
  /// which marker bitmap is drawn.
  final RxInt typeVehicleId = 0.obs;

  /// True when the installed build is behind the server's published version.
  final RxBool updateVersion = false.obs;
}
