import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/presentation/widgets/widge_update.dart';

import 'logic.dart';
import 'state.dart';

/// Drawer tab 0. Was `home_screen/home_screen.dart`, a 403-line
/// `StatefulWidget` that owned the GPS subscription, the marker set, the
/// version check and all ride-status routing — all of it now on [HomeLogic].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Resolved on each access, never cached: GetX owns this instance's
  // lifetime, and a `final` field would keep pointing at a disposed one
  // if the route is left and re-entered (hit on device 2026-09-06 —
  // "A TextEditingController was used after being disposed").
  HomeLogic get logic => Get.find<HomeLogic>();

  @override
  void initState() {
    super.initState();
    // Needs a mounted frame before the socket's dialogs can attach.
    WidgetsBinding.instance.addPostFrameCallback((_) => logic.registerSocket());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Obx(() => _buildGoogleMap(context)),
                Obx(
                  () => !logic.state.updateVersion.value
                      ? Container()
                      : Positioned.fill(
                          left: 0,
                          right: 0,
                          child: Container(
                            color: AppColors.dark1.withAlpha(60),
                            child: Center(child: WidgetUpdate()),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap(BuildContext context) {
    switch (logic.state.locationStatus.value) {
      case LocationLoadStatus.inProgress:
        return const Center(child: CircularProgressIndicator());
      case LocationLoadStatus.success:
        return GoogleMap(
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
          trafficEnabled: true,
          initialCameraPosition: CameraPosition(
            target: logic.state.currentLocation.value!,
            zoom: logic.state.currentZoom.value,
          ),
          markers: logic.state.markers.toSet(),
          onMapCreated: (controller) => logic.mapController = controller,
          onCameraMove: (position) =>
              logic.state.currentZoom.value = position.zoom,
        );
      case LocationLoadStatus.permissionDenied:
        return const Center(child: Text('Location permission denied'));
      case LocationLoadStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  'Failed to load location: ${logic.state.locationError.value ?? ''}'),
              MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: AppColors.info,
                onPressed: () async => openAppSettings(),
                child: Text(
                  'Open location permission',
                  style: ThemeConstands.font16SemiBold
                      .copyWith(color: AppColors.dark4),
                ),
              )
            ],
          ),
        );
    }
  }
}
