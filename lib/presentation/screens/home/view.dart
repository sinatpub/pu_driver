import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/home/widgets/driver_status_card.dart';
import 'package:tara_driver_application/presentation/screens/home/widgets/location_state_view.dart';
import 'package:tara_driver_application/presentation/widgets/widge_update.dart';

import 'logic.dart';
import 'state.dart';

/// Drawer tab 0. Was `home_screen/home_screen.dart`, a 403-line
/// `StatefulWidget` that owned the GPS subscription, the marker set, the
/// version check and all ride-status routing — all of it now on [HomeLogic].
///
/// UX-redesign C2 restyled it. [HomeLogic] was not touched: the camera still
/// follows every GPS tick, the socket still registers after the first frame,
/// and the ride-resume redirect still fires from the controller's `ever()`.
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

  /// Room reserved at the bottom of the map for [DriverStatusCard], so
  /// Google's logo and the map controls are not hidden underneath it — the
  /// logo being obscured breaks the Maps terms, and the controls being
  /// unreachable is just bad. An estimate of the card's height, which is
  /// content-sized; verify on a device with a long Khmer string.
  static const double _statusCardReserve = 112;

  @override
  void initState() {
    super.initState();
    // Needs a mounted frame before the socket's dialogs can attach.
    WidgetsBinding.instance.addPostFrameCallback((_) => logic.registerSocket());
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      body: Stack(
        children: <Widget>[
          Obx(() => _buildGoogleMap(context)),

          // Only meaningful once there is a map to float over.
          Obx(
            () => logic.state.locationStatus.value == LocationLoadStatus.success
                ? Positioned(
                    left: Insets.s16,
                    right: Insets.s16,
                    bottom: Insets.s16,
                    child: const SafeArea(
                      top: false,
                      child: DriverStatusCard(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          Obx(
            () => !logic.state.updateVersion.value
                ? const SizedBox.shrink()
                : Positioned.fill(
                    child: ColoredBox(
                      color: c.scrim,
                      child: const Center(child: WidgetUpdate()),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap(BuildContext context) {
    final LocationLoadStatus status = logic.state.locationStatus.value;

    if (status == LocationLoadStatus.success) {
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
        // C2: the only change to the map itself.
        padding: const EdgeInsets.only(bottom: _statusCardReserve),
        initialCameraPosition: CameraPosition(
          target: logic.state.currentLocation.value!,
          zoom: logic.state.currentZoom.value,
        ),
        markers: logic.state.markers.toSet(),
        onMapCreated: (controller) => logic.mapController = controller,
        onCameraMove: (position) =>
            logic.state.currentZoom.value = position.zoom,
      );
    }

    return LocationStateView(
      status: status,
      searchingLabel: 'LOCATION_FINDING'.tr(),
      deniedTitle: 'LOCATION_DENIED'.tr(),
      deniedMessage: 'LOCATION_DENIED_DES'.tr(),
      failedTitle: 'LOCATION_FAILED'.tr(),
      openSettingsLabel: 'OPEN_SETTINGS'.tr(),
      errorText: logic.state.locationError.value,
      onOpenSettings: () async => openAppSettings(),
    );
  }
}
