import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'logic.dart';

/// Was `map_history_detail_screen.dart`. The old widget carried nine mutable
/// public fields, which is why `dart analyze` flagged it `must_be_immutable`;
/// they are now constructor arguments on [HistoryDetailLogic], resolved from
/// typed route arguments in the binding.
///
/// UX-redesign S1 (`03 S10`, `DD-20`): `TAppBar` "Trip details", the map in the
/// top ~55%, and a key-value card below that replaces `ShowDistandWidget`. It
/// shows only what `MapHistoryDetailArgs` carry — no invoice, passenger or
/// date, and no replay. The map's properties, markers and Directions call are
/// unchanged; the route is drawn in the brand colour (set in the logic).
class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<HistoryDetailLogic>();
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      appBar: TAppBar(title: 'TRIP_DETAILS'.tr()),
      body: SafeArea(
        bottom: false,
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 55,
              child: Obx(
                () => GoogleMap(
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
                  polylines: logic.state.polylines.toSet(),
                  markers: logic.state.markers.toSet(),
                  initialCameraPosition: CameraPosition(
                    target: logic.start,
                    tilt: 0.0,
                    zoom: 17.0,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 45,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Insets.s16,
                  Insets.s16,
                  Insets.s16,
                  Insets.s24,
                ),
                child: TripDetailCard(
                  distance: logic.distand,
                  duration: logic.duration,
                  amount: '៛${logic.cost}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The history detail's facts — only what the route args carry (`DD-20`).
class TripDetailCard extends StatelessWidget {
  const TripDetailCard({
    super.key,
    required this.distance,
    required this.duration,
    required this.amount,
  });

  /// Pre-formatted by the history card before navigation.
  final String distance;
  final String duration;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return TCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TBadge(
            label: 'COMPLETED'.tr(),
            tone: TBadgeTone.success,
            icon: DsIcons.check,
          ),
          const SizedBox(height: Insets.s8),
          TKeyValueRow(label: 'DISTANCE'.tr(), value: distance),
          TKeyValueRow(label: 'DURATION'.tr(), value: duration),
          TKeyValueRow(label: 'TOTAL_PRICE'.tr(), value: amount),
        ],
      ),
    );
  }
}
