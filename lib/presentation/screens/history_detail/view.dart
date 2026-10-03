import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/screens/calculate_fee/widgets/receipt_card.dart';
import 'package:pu_taxi_driver/presentation/screens/contact_us/logic.dart';
import 'package:pu_taxi_driver/presentation/screens/contact_us/state.dart';
import 'package:pu_taxi_driver/presentation/screens/contact_us/view.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';
import 'package:pu_taxi_driver/routes/route_arguments.dart';

import 'logic.dart';

/// Was `map_history_detail_screen.dart`. The old widget carried nine mutable
/// public fields, which is why `dart analyze` flagged it `must_be_immutable`;
/// they are now typed route arguments held by [HistoryDetailLogic].
///
/// UX-redesign S1 (`03 S10`) gave it `TAppBar` "Trip details" over a map and a
/// figures card. DD-42 (superseding DD-20) shows the whole trip, with the
/// payment screen's pieces so the two read alike: the amount and method, the
/// distance / duration / time, both addresses, and the passenger with the
/// invoice. The map is framed on the whole route, once. Below it all, the
/// lost-item card: call the passenger within 24 hours of the trip, or contact
/// support.
class HistoryDetailPage extends StatefulWidget {
  const HistoryDetailPage({super.key});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  HistoryDetailLogic get logic => Get.find<HistoryDetailLogic>();

  GoogleMapController? _map;
  Worker? _routeWorker;

  @override
  void initState() {
    super.initState();
    // The route arrives after the map: frame it when it does.
    _routeWorker = ever(logic.state.polylines, (_) => _fitRoute());
  }

  @override
  void dispose() {
    _routeWorker?.dispose();
    super.dispose();
  }

  /// Frames the pickup, the destination and the route between them — never
  /// tighter than ~170 m, so a very short trip is not shown at the curb.
  void _fitRoute() {
    final GoogleMapController? map = _map;
    if (map == null) return;
    final List<LatLng> points = <LatLng>[
      logic.start,
      logic.end,
      for (final Polyline line in logic.state.polylines) ...line.points,
    ];
    double south = points.first.latitude, north = south;
    double west = points.first.longitude, east = west;
    for (final LatLng p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    const double minSpan = 0.0015;
    if (north - south < minSpan) {
      final double mid = (north + south) / 2;
      south = mid - minSpan / 2;
      north = mid + minSpan / 2;
    }
    if (east - west < minSpan) {
      final double mid = (east + west) / 2;
      west = mid - minSpan / 2;
      east = mid + minSpan / 2;
    }
    map
        .animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          ),
          48,
        ))
        .catchError((Object e) => debugPrint('History detail camera: $e'));
  }

  void _showSupport() {
    final ContactUsState contact = ContactUsState();
    showTSheet<void>(
      context: context,
      title: 'CONTACT_SUPPORT'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final (String carrier, String number) in <(String, String)>[
            ('Smart', contact.smartPhone),
            ('Cellcard', contact.cellcardPhone),
          ]) ...<Widget>[
            ContactRow(
              icon: DsIcons.phone,
              label: '$carrier: ${formatLocalPhone(number)}',
              onTap: () => logic.callSupport(number.replaceAll(' ', '')),
            ),
            const SizedBox(height: Insets.s8),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final MapHistoryDetailArgs trip = logic.args;

    return Scaffold(
      backgroundColor: c.bgPage,
      appBar: TAppBar(title: 'TRIP_DETAILS'.tr()),
      body: SafeArea(
        bottom: false,
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 36,
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
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: true,
                  mapToolbarEnabled: false,
                  polylines: logic.state.polylines.toSet(),
                  markers: logic.state.markers.toSet(),
                  initialCameraPosition: CameraPosition(
                    target: logic.start,
                    tilt: 0.0,
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _map = controller;
                    _fitRoute();
                  },
                ),
              ),
            ),
            Expanded(
              flex: 64,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Insets.s16,
                  Insets.s16,
                  Insets.s16,
                  Insets.s24,
                ),
                child: SafeArea(
                  top: false,
                  child: TripDetailBody(
                    trip: trip,
                    canCallPassenger: logic.canCallPassenger,
                    onCallPassenger: logic.callPassenger,
                    onContactSupport: _showSupport,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything under the map (`DD-42`): the amount and figures, the route and
/// passenger, and the lost-item card. Parts the args do not carry are left
/// out rather than shown empty.
class TripDetailBody extends StatelessWidget {
  const TripDetailBody({
    super.key,
    required this.trip,
    required this.canCallPassenger,
    required this.onCallPassenger,
    required this.onContactSupport,
  });

  final MapHistoryDetailArgs trip;
  final bool canCallPassenger;
  final VoidCallback onCallPassenger;
  final VoidCallback onContactSupport;

  /// "17:36" for a trip today, "30/09 17:36" otherwise — digits only, as on
  /// the payment screen. A dash when the trip's time is not known.
  String _time(DateTime? at) {
    if (at == null) return '—';
    final DateTime now = DateTime.now();
    final bool today =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return DateFormat(today ? 'HH:mm' : 'dd/MM HH:mm').format(at);
  }

  @override
  Widget build(BuildContext context) {
    final String? invoice =
        trip.invoiceId == null ? null : '#${trip.invoiceId}';
    final bool hasRoute = (trip.startAddress ?? '').trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PaymentHero(
          label: 'TOTAL_PRICE'.tr(),
          method: trip.paymentMethod,
          amount: '៛${trip.cost}',
          distance: trip.distand,
          duration: trip.duration,
          time: _time(trip.tripTime),
        ),
        if (hasRoute) ...<Widget>[
          const SizedBox(height: Insets.s12),
          PaymentRoute(
            passengerName: trip.passengerName ?? '',
            passengerImageUrl: trip.passengerImage,
            passengerCaption: invoice,
            startAddress: trip.startAddress!,
            endAddress: trip.endAddress ?? '',
          ),
        ],
        const SizedBox(height: Insets.s12),
        LostItemCard(
          canCallPassenger: canCallPassenger,
          invoice: invoice,
          onCallPassenger: onCallPassenger,
          onContactSupport: onContactSupport,
        ),
      ],
    );
  }
}

/// How to reach the passenger about something left in the vehicle (`DD-42`).
///
/// For 24 hours after the trip the driver can call the passenger — through
/// the button only; the number is never printed. After that, or with no
/// number, contact goes through support, with the invoice to quote.
class LostItemCard extends StatelessWidget {
  const LostItemCard({
    super.key,
    required this.canCallPassenger,
    required this.invoice,
    required this.onCallPassenger,
    required this.onContactSupport,
  });

  final bool canCallPassenger;

  /// "#7712", for the support hint. Null when the trip carries none.
  final String? invoice;
  final VoidCallback onCallPassenger;
  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final String hint = canCallPassenger
        ? 'LOST_ITEM_CALL_HINT'.tr()
        : invoice == null
            ? 'LOST_ITEM_SUPPORT_ONLY_HINT'.tr()
            : 'LOST_ITEM_SUPPORT_HINT'.tr(args: <String>[invoice!]);

    return TCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'LOST_ITEM_TITLE'.tr(),
            style: context.texts.bodyStrong.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: Insets.s4),
          Text(
            hint,
            style: context.texts.bodySecondary.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Insets.s12),
          if (canCallPassenger) ...<Widget>[
            TButton(
              label: 'CALL_PASSENGER'.tr(),
              icon: DsIcons.phone,
              variant: TButtonVariant.secondary,
              size: TButtonSize.small,
              onPressed: onCallPassenger,
            ),
            const SizedBox(height: Insets.s4),
            TButton(
              label: 'CONTACT_SUPPORT'.tr(),
              variant: TButtonVariant.tertiary,
              size: TButtonSize.small,
              onPressed: onContactSupport,
            ),
          ] else
            TButton(
              label: 'CONTACT_SUPPORT'.tr(),
              variant: TButtonVariant.secondary,
              size: TButtonSize.small,
              onPressed: onContactSupport,
            ),
        ],
      ),
    );
  }
}
