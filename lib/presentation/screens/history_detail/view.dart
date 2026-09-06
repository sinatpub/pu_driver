import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/show_distand_and_price_widget.dart';

import 'logic.dart';

/// Was `map_history_detail_screen.dart`. The old widget carried nine mutable
/// public fields, which is why `dart analyze` flagged it `must_be_immutable`;
/// they are now constructor arguments on [HistoryDetailLogic], resolved from
/// typed route arguments in the binding.
class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<HistoryDetailLogic>();

    return Scaffold(
      backgroundColor: AppColors.light3,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Obx(
                    () => GoogleMap(
                      gestureRecognizers: <Factory<
                          OneSequenceGestureRecognizer>>{
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
                      polylines: logic.state.polylines.toSet(),
                      markers: logic.state.markers.toSet(),
                      initialCameraPosition: CameraPosition(
                        target: logic.start,
                        tilt: 0.0,
                        zoom: 17.0,
                      ),
                    ),
                  ),
                  ShowDistandWidget(
                    distand: logic.distand,
                    cost: logic.cost,
                    duration: logic.duration,
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
