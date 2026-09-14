import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/passenger_row.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/show_distand_and_price_widget.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/trip_action_bar.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/trip_timeline.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/presentation/widgets/yesno_dialog_widget.dart';
import 'package:tara_driver_application/services/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/ds/t_motion.dart';

/// The trip screen's bottom sheet, for every stage.
///
/// UX-redesign C3 rebuilt the body and C4 restyled the per-stage content:
/// grabber → timeline → (in-trip meter) → stage content → **pinned** action
/// bar.
///
/// Behaviour today (`C4`):
/// - the sheet starts collapsed when the screen is *entered* already in
///   progress (`processType == 4`);
/// - while in progress (`processType == 4` or `6`) the live meter
///   ([TripMeterStrip]) sits **above** the collapsible region, so it stays
///   visible when the sheet is collapsed (`C4` "done when");
/// - the at-pickup stage shows the passenger, the destination (with its
///   distance once known) and an "≈ Est. fare" row **only once** the fare is
///   computed (`DD-14`);
/// - Cancel still opens the same confirm dialog, and its `onYes` still emits
///   `driverCancelDrive` **before** calling [onCancel] — that order is what
///   the passenger app sees;
/// - the request stage still shows no fare, distance or rating, because the
///   payload carries none (`DD-15`).
class ModelBottomSheetNewRequestWidget extends StatefulWidget {
  final int bookingId;
  final int bookingCode;
  final int passengerId;
  final int processType;
  final String profilePassanger;
  final String namePassanger;
  final String phonePassanger;
  final String passegerLocationName;
  final String whereToGoLocationName;
  final double distandTotal;
  final String totalFee;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  /// True while any trip action is in flight. Disables **every** action —
  /// see [TripActionBar] for why Cancel in particular must not be tappable.
  final bool isLoading;

  /// Formatted live-meter values, computed in `booking/view.dart` with the
  /// exact expressions the old top-of-map strip used (`DD-14`). Only read by
  /// [TripMeterStrip], which itself prefixes the "≈" (see its `fare`).
  final String duration;
  final String distance;
  final String fare;

  const ModelBottomSheetNewRequestWidget(
      {super.key,
      required this.bookingCode,
      required this.passengerId,
      required this.distandTotal,
      required this.totalFee,
      required this.duration,
      required this.distance,
      required this.fare,
      required this.bookingId,
      required this.namePassanger,
      required this.phonePassanger,
      required this.profilePassanger,
      required this.onTap,
      required this.onCancel,
      required this.processType,
      required this.whereToGoLocationName,
      required this.passegerLocationName,
      this.isLoading = false});

  @override
  State<ModelBottomSheetNewRequestWidget> createState() =>
      _ModelBottomSheetNewRequestWidgetState();
}

class _ModelBottomSheetNewRequestWidgetState
    extends State<ModelBottomSheetNewRequestWidget> {
  bool isExpanded = true;

  @override
  void initState() {
    // Unchanged: arriving already on a trip opens with the details collapsed.
    if (widget.processType == 4) {
      isExpanded = false;
    }
    super.initState();
  }

  Future<void> _launchLink(String url) async {
    if (await launchUrl(Uri.parse(url))) {
    } else {
      await launchUrl(
        Uri.parse(url),
      );
    }
  }

  /// Unchanged mapping; 4 and 6 are both the drop-off. P2 moved the labels
  /// to the prototype phrasing on new keys — `ARRIVE`/`START_RIDE` keep their
  /// values because they double as notification titles (`06 §3`, DD-29).
  String get _primaryLabel => switch (widget.processType) {
        1 => "ACCEPT".tr(),
        2 => "ACTION_ARRIVED".tr(),
        3 => "ACTION_START_RIDE".tr(),
        4 || 6 => "ACTION_DROP_OFF".tr(),
        _ => "",
      };

  /// Only a pending request can be cancelled — the same gate
  /// `TripStateMachine.canCancel` enforces.
  bool get _canCancel => widget.processType == 1;

  /// Preserved verbatim: the socket emit fires first, then the controller.
  void _confirmCancel() {
    showYesNoCustomDialog(
        context: context,
        title: "CANCEL_REQUEST_TITLE".tr(),
        description: "CANCEL_REQUEST_MSG".tr(),
        yesLabel: "YES_CANCEL".tr(),
        noLabel: "STAY".tr(),
        onYes: () {
          DriverSocketService().driverCancelDrive(
              bookingId: widget.bookingId,
              bookingCode: widget.bookingCode,
              passengerId: widget.passengerId);
          widget.onCancel();
        });
  }

  /// True once a destination exists — the same condition the old layout used
  /// (stages 3, 4 and 6). C4 uses it only for the at-pickup address meta
  /// line; the in-progress meter sits above the collapsible region.
  bool get _showTripFigures =>
      widget.processType != 1 &&
      widget.processType != 2 &&
      widget.whereToGoLocationName.isNotEmpty;

  /// Which [_stageContent] branch is showing; 4 and 6 share one.
  int get _contentBranch => switch (widget.processType) {
        1 || 2 || 3 => widget.processType,
        _ => 4,
      };

  List<Widget> _stageContent(BuildContext context) {
    final PassengerRow passenger = PassengerRow(
      name: widget.namePassanger,
      phone: widget.phonePassanger,
      phoneLabel: "${"MOBILENUM".tr()} ${widget.phonePassanger}",
      callSemanticLabel: "MOBILENUM".tr(),
      imageUrl: widget.profilePassanger,
      onCall: () => _launchLink("tel:${widget.phonePassanger}"),
    );

    switch (widget.processType) {
      case 1:
        return <Widget>[
          passenger,
          TAddressRow(
            kind: TAddressKind.pickup,
            overline: "PICKUP".tr(),
            primary: widget.passegerLocationName,
            loading: widget.passegerLocationName.isEmpty,
          ),
          if (widget.whereToGoLocationName.isNotEmpty)
            TAddressRow(
              kind: TAddressKind.destination,
              overline: "DESTINATION".tr(),
              primary: widget.whereToGoLocationName,
            ),
        ];
      case 2:
        return <Widget>[
          TAddressRow(
            kind: TAddressKind.pickup,
            overline: "PICKUP".tr(),
            primary: widget.passegerLocationName,
            loading: widget.passegerLocationName.isEmpty,
            focused: true,
          ),
          passenger,
        ];
      // At pickup (`C4`): the passenger, then the destination in focus with
      // its distance once known, then "≈ Est. fare" only once the fare has
      // been computed (`DD-14`). The driver's own address line is gone.
      case 3:
        return <Widget>[
          passenger,
          if (widget.whereToGoLocationName.isNotEmpty)
            TAddressRow(
              kind: TAddressKind.destination,
              overline: "DESTINATION".tr(),
              primary: widget.whereToGoLocationName,
              secondary: _showTripFigures
                  ? "${formatDistanceWithUnits(widget.distandTotal.toString(), context)} ${"km".tr()}"
                  : null,
              focused: true,
            ),
          if (_showTripFigures && widget.totalFee.isNotEmpty)
            TKeyValueRow(
              label: "EST_FARE".tr(),
              value: "≈ ៛${formatRielAmount(widget.totalFee.toString())}",
            ),
        ];
      // In progress (`4`) and dropping (`6`): only the destination line — the
      // meter above the collapsible region carries time, distance and fare.
      default:
        return <Widget>[
          if (widget.whereToGoLocationName.isNotEmpty)
            TAddressRow(
              kind: TAddressKind.destination,
              overline: "DESTINATION".tr(),
              primary: widget.whereToGoLocationName,
              focused: true,
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.74,
        ),
        decoration: BoxDecoration(
          color: c.bgSurface,
          borderRadius: Radii.sheetRadius,
          border: Border.all(color: c.borderDivider),
          boxShadow: Elevations.sheet,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.s20,
            Insets.s12,
            Insets.s20,
            Insets.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // The grabber is the collapse control now that the stage name
              // lives in the header over the map.
              // P3: a 48 px target (the bar itself is unchanged) that says
              // what it does — it was 24 px and unlabelled.
              Semantics(
                button: true,
                expanded: isExpanded,
                label: isExpanded
                    ? MaterialLocalizations.of(context).collapsedIconTapHint
                    : MaterialLocalizations.of(context).expandedIconTapHint,
                child: GestureDetector(
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: Sizes.touchTarget,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: c.borderDivider,
                          borderRadius: BorderRadius.circular(Radii.full),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              TripTimeline(
                processType: widget.processType,
                labels: <String>[
                  "TIMELINE_ACCEPT".tr(),
                  "TIMELINE_ARRIVE".tr(),
                  "TIMELINE_START".tr(),
                  "TIMELINE_DROP".tr(),
                ],
              ),
              // C4 / DD-14: the live meter is pinned above the collapsible
              // region, so it stays on screen when the sheet is collapsed.
              if (widget.processType == 4 || widget.processType == 6) ...[
                const SizedBox(height: Insets.s12),
                TripMeterStrip(
                  duration: widget.duration,
                  distance: widget.distance,
                  fare: widget.fare,
                ),
              ],
              if (isExpanded) ...<Widget>[
                const SizedBox(height: Insets.s12),
                Flexible(
                  child: SingleChildScrollView(
                    // P1: the stage's content cross-fades over 150 ms. Keyed by
                    // the content branch, not by every field, so a fare or an
                    // address updating within a stage never animates. The
                    // meter and the action bar sit outside it; the outgoing
                    // content ignores taps during the fade.
                    child: TCrossFade(
                      stateKey: _contentBranch,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _stageContent(context),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: Insets.s16),
              TripActionBar(
                primaryLabel: _primaryLabel,
                onPrimary: widget.onTap,
                isLoading: widget.isLoading,
                // DD-12: Start ride is the one trip action in the success
                // colour; Drop off is primary, and never red.
                primaryVariant: widget.processType == 3
                    ? TButtonVariant.success
                    : TButtonVariant.primary,
                showCancel: _canCancel,
                cancelLabel: "CANCEL_REQUEST".tr(),
                onCancel: _confirmCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
