import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tara_driver_application/core/helper/address_parts.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/booking/widgets/passenger_row.dart';
import 'package:tara_driver_application/core/utils/clock_format.dart';
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
/// - every stage after the request carries the same pinned header — stage
///   line, [TripProgressBar], one headline figure — so it stays visible when
///   the sheet is collapsed (`DD-36`–`DD-38`); on a trip the meter's figures
///   are pinned with it (`C4` "done when");
/// - fares are only ever shown as "≈" estimates, with the note that the
///   server confirms the final fare (`DD-14`);
/// - Drop off is hold-to-confirm (`DD-38`);
/// - Cancel still opens the same confirm dialog, and its `onYes` still emits
///   `driverCancelDrive` **before** calling [onCancel] — that order is what
///   the passenger app sees;
/// - the request stage (`DD-35`, superseding `DD-15`) leads with the time
///   and distance to the pickup, from a Directions route the screen fetches
///   on arrival; then the trip distance and an "≈" fare when there is a
///   destination; then the two addresses. No stepper, phone number or call
///   button until the ride is accepted. The decision timer sits inside
///   Accept, and the text action below it reads "Decline".
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

  /// Formatted meter values, computed in `booking/view.dart` from the same
  /// figures the old top-of-map strip used (`DD-14`): time on trip ("12:40"),
  /// distance driven ("3.2 km") and the fare, without the "≈" — the sheet
  /// adds it.
  final String duration;
  final String distance;
  final String fare;

  /// On trip (`DD-38`): whether the ride has a destination. With one, the
  /// headline is the time and distance left; without, time and distance
  /// driven.
  final bool hasDestination;

  /// On trip with a destination: "18 min", "5.8 km", and how much of the
  /// trip is done (0–1) for the progress bar. Null without a route.
  final String? tripEta;
  final String? tripLeft;
  final double? tripProgress;

  /// True until the trip route has been fetched, or has failed.
  final bool tripRouteLoading;

  /// Request stage only (`DD-35`), formatted by the screen: "4 min" and
  /// "1.2 km". Null when there is no route — no GPS fix, or Directions
  /// found none — and the summary then shows no figures rather than guesses.
  final String? pickupEta;
  final String? pickupDistance;

  /// True until the pickup route has been fetched, or has failed.
  final bool pickupRouteLoading;

  /// Request stage only: the pickup→destination driving distance and the
  /// fare estimated from it, both formatted. Null when there is no
  /// destination or no route.
  final String? tripDistance;
  final String? tripFare;

  /// The request's decision time, drawn inside Accept. Null on other stages.
  final int? requestTimeoutSeconds;

  /// Reports the sheet's height, so the map can pad its camera by it.
  final ValueChanged<double>? onHeightChanged;

  /// At pickup (`DD-37`): when the driver arrived, for the waiting timer.
  /// Null when unknown — the timer is then not shown.
  final DateTime? waitingSince;

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
      this.isLoading = false,
      this.pickupEta,
      this.pickupDistance,
      this.pickupRouteLoading = false,
      this.tripDistance,
      this.tripFare,
      this.requestTimeoutSeconds,
      this.onHeightChanged,
      this.waitingSince,
      this.hasDestination = false,
      this.tripEta,
      this.tripLeft,
      this.tripProgress,
      this.tripRouteLoading = false});

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
        4 => "HOLD_TO_DROP_OFF".tr(),
        6 => "ACTION_DROP_OFF".tr(),
        _ => "",
      };

  /// Only a pending request can be cancelled — the same gate
  /// `TripStateMachine.canCancel` enforces.
  bool get _canCancel => widget.processType == 1;

  /// The request stage runs tighter (`DD-35`): no grabber — a 30 s decision
  /// has nothing to collapse for — and less padding under Decline.
  bool get _isRequest => widget.processType == 1;

  /// Going to the pickup (`DD-36`): the same compact anatomy as the request —
  /// stage line, thin progress bar, one headline figure — under a grabber
  /// that sits in the sheet's top padding.
  bool get _isEnRoute => widget.processType == 2;

  /// At pickup (`DD-37`): the same anatomy, with the waiting time as the
  /// headline.
  bool get _isAtPickup => widget.processType == 3;

  /// The stages whose header is the stage line, progress bar and headline
  /// rather than the numbered [TripTimeline].
  bool get _hasStageHeader => _isEnRoute || _isAtPickup || _isOnTrip;

  /// On trip (`DD-38`), including the drop-off in flight (6).
  bool get _isOnTrip => widget.processType == 4 || widget.processType == 6;

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

  /// Which [_stageContent] branch is showing; 4 and 6 share one.
  int get _contentBranch => switch (widget.processType) {
        1 || 2 || 3 => widget.processType,
        _ => 4,
      };

  List<Widget> _stageContent(BuildContext context) {
    // DD-36/DD-37: the call button is how to reach them, so no phone line.
    final PassengerRow passenger = PassengerRow(
      name: widget.namePassanger,
      phone: widget.phonePassanger,
      callSemanticLabel: "MOBILENUM".tr(),
      imageUrl: widget.profilePassanger,
      onCall: () => _launchLink("tel:${widget.phonePassanger}"),
      dense: true,
    );

    switch (widget.processType) {
      // Request (`DD-35`): what the driver decides on comes first — how far
      // the pickup is, then what the trip is worth — then where it goes.
      case 1:
        final (String pickupPlace, String? pickupArea) =
            splitAddress(widget.passegerLocationName);
        final (String destinationPlace, String? destinationArea) =
            splitAddress(widget.whereToGoLocationName);
        return <Widget>[
          _RequestSummary(
            eta: widget.pickupEta,
            distance: widget.pickupDistance,
            loading: widget.pickupRouteLoading,
            passengerName: widget.namePassanger,
            passengerImage: widget.profilePassanger,
          ),
          if (widget.tripDistance != null || widget.tripFare != null) ...[
            const SizedBox(height: Insets.s12),
            _TripFigures(
              distance: widget.tripDistance,
              fare: widget.tripFare,
            ),
          ],
          const SizedBox(height: Insets.s4),
          TAddressRow(
            kind: TAddressKind.pickup,
            overline: "PICKUP".tr(),
            primary: pickupPlace,
            secondary: pickupArea,
            loading: widget.passegerLocationName.isEmpty,
          ),
          if (widget.whereToGoLocationName.isNotEmpty)
            TAddressRow(
              kind: TAddressKind.destination,
              overline: "DESTINATION".tr(),
              primary: destinationPlace,
              secondary: destinationArea,
            ),
        ];
      // Going to pickup (`DD-36`): where, then who — the address split like
      // the request's, and the passenger without the phone line, since the
      // call button is how to reach them.
      case 2:
        final (String pickupPlace, String? pickupArea) =
            splitAddress(widget.passegerLocationName);
        return <Widget>[
          TAddressRow(
            kind: TAddressKind.pickup,
            overline: "PICKUP".tr(),
            primary: pickupPlace,
            secondary: pickupArea,
            loading: widget.passegerLocationName.isEmpty,
          ),
          const SizedBox(height: Insets.s4),
          passenger,
        ];
      // At pickup (`DD-37`): what the trip ahead is — distance and "≈" fare
      // as the request showed them, once computed (`DD-14`) — then where it
      // goes, then who. No destination: just the passenger.
      case 3:
        final (String destinationPlace, String? destinationArea) =
            splitAddress(widget.whereToGoLocationName);
        return <Widget>[
          if (widget.tripDistance != null || widget.tripFare != null) ...[
            _TripFigures(distance: widget.tripDistance, fare: widget.tripFare),
            const SizedBox(height: Insets.s4),
          ],
          if (widget.whereToGoLocationName.isNotEmpty)
            TAddressRow(
              kind: TAddressKind.destination,
              overline: "DESTINATION".tr(),
              primary: destinationPlace,
              secondary: destinationArea,
            ),
          const SizedBox(height: Insets.s4),
          passenger,
        ];
      // In progress (`4`) and dropping (`6`): only the destination line — the
      // pinned header carries the time, distance and fare.
      default:
        final (String destinationPlace, String? destinationArea) =
            splitAddress(widget.whereToGoLocationName);
        return <Widget>[
          if (widget.whereToGoLocationName.isNotEmpty)
            TAddressRow(
              kind: TAddressKind.destination,
              overline: "DESTINATION".tr(),
              primary: destinationPlace,
              secondary: destinationArea,
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
      child: _MeasureHeight(
        onChange: widget.onHeightChanged,
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
            padding: EdgeInsets.fromLTRB(
              Insets.s20,
              _isRequest
                  ? Insets.s16
                  : _hasStageHeader
                      ? 0
                      : Insets.s12,
              Insets.s20,
              _isRequest ? Insets.s8 : Insets.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // The grabber is the collapse control now that the stage name
                // lives in the header over the map.
                // P3: a 48 px target (the bar itself is unchanged) that says
                // what it does — it was 24 px and unlabelled.
                if (!_isRequest)
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
                // DD-35: no stepper on a request — nothing has started yet.
                // DD-36: the compact stages carry their own header — stage
                // line, progress bar, headline — pinned above the collapsible
                // region so it stays when the sheet is collapsed.
                if (_isEnRoute)
                  _StageSummary(
                    label: "STAGE_GO_TO_PICKUP".tr(),
                    color: c.stagePickupText,
                    processType: widget.processType,
                    bookingCode: widget.bookingCode,
                    headline: _EtaHero(
                      eta: widget.pickupEta,
                      detail: widget.pickupDistance == null
                          ? null
                          : "DISTANCE_LEFT"
                              .tr(args: <String>[widget.pickupDistance!]),
                      loading: widget.pickupRouteLoading,
                    ),
                  ),
                if (_isAtPickup)
                  _StageSummary(
                    label: "STAGE_AT_PICKUP".tr(),
                    color: c.stagePickupText,
                    processType: widget.processType,
                    bookingCode: widget.bookingCode,
                    headline: widget.waitingSince == null
                        ? null
                        : _WaitingClock(since: widget.waitingSince!),
                  ),
                if (!_isRequest && !_hasStageHeader)
                  TripTimeline(
                    processType: widget.processType,
                    labels: <String>[
                      "TIMELINE_ACCEPT".tr(),
                      "TIMELINE_ARRIVE".tr(),
                      "TIMELINE_START".tr(),
                      "TIMELINE_DROP".tr(),
                    ],
                  ),
                // DD-38 / C4 / DD-14: on a trip the meter is pinned with the
                // header, so it stays on screen when the sheet is collapsed.
                if (_isOnTrip) ...<Widget>[
                  _StageSummary(
                    label: "STAGE_ON_TRIP".tr(),
                    color: c.stageOnTripText,
                    progressColor: c.successGraphic,
                    progressFraction:
                        widget.hasDestination ? widget.tripProgress : null,
                    processType: widget.processType,
                    bookingCode: widget.bookingCode,
                    headline: widget.hasDestination
                        ? _EtaHero(
                            eta: widget.tripEta,
                            detail: widget.tripLeft == null
                                ? null
                                : "DISTANCE_LEFT"
                                    .tr(args: <String>[widget.tripLeft!]),
                            loading: widget.tripRouteLoading,
                          )
                        : _EtaHero(
                            eta: widget.duration,
                            detail: "DISTANCE_DRIVEN"
                                .tr(args: <String>[widget.distance]),
                            loading: false,
                          ),
                  ),
                  const SizedBox(height: Insets.s8),
                  _FigureTiles(
                    tiles: <(String, String)>[
                      if (widget.hasDestination)
                        ("DURATION".tr(), widget.duration),
                      (
                        widget.hasDestination
                            ? "EST_FARE".tr()
                            : "FARE_SO_FAR".tr(),
                        "≈ ៛${widget.fare}"
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.s4),
                  const _EstimateNote(),
                ],
                if (isExpanded) ...<Widget>[
                  if (!_isRequest)
                    SizedBox(height: _hasStageHeader ? Insets.s8 : Insets.s12),
                  Flexible(
                    // Keyed so the content keeps its element — and its
                    // cross-fade — when accepting adds the grabber above it.
                    key: const ValueKey<String>('stage-content'),
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
                  cancelLabel: "DECLINE".tr(),
                  onCancel: _confirmCancel,
                  countdownSeconds: widget.processType == 1
                      ? widget.requestTimeoutSeconds
                      : null,
                  holdToConfirm: widget.processType == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The request's headline (`DD-35`): the stage and who is waiting on one
/// line, then the time and distance to the pickup. The name takes whatever
/// the stage label leaves, so it is cut only when it is genuinely long.
class _RequestSummary extends StatelessWidget {
  const _RequestSummary({
    required this.eta,
    required this.distance,
    required this.loading,
    required this.passengerName,
    required this.passengerImage,
  });

  final String? eta;
  final String? distance;
  final bool loading;
  final String passengerName;
  final String passengerImage;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            TPulseDot(color: c.stageRequestText, size: 8),
            const SizedBox(width: Insets.s8),
            Text(
              "STAGE_NEW_REQUEST".tr(),
              style: context.texts.caption.copyWith(
                color: c.stageRequestText,
              ),
            ),
            const SizedBox(width: Insets.s12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TAvatar(
                    name: passengerName,
                    imageUrl: passengerImage,
                    size: 28,
                  ),
                  const SizedBox(width: Insets.s8),
                  Flexible(
                    child: Text(
                      passengerName,
                      style: context.texts.caption.copyWith(
                        color: c.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.s4),
        _EtaHero(
          eta: eta,
          detail: distance == null
              ? null
              : "TO_PICKUP".tr(args: <String>[distance!]),
          loading: loading,
        ),
      ],
    );
  }
}

/// The compact stages' header (`DD-36`, `DD-37`): the stage and booking on
/// one line, the four steps as a thin bar, then the stage's one headline
/// figure — time left going to the pickup, time waited at it.
class _StageSummary extends StatelessWidget {
  const _StageSummary({
    required this.label,
    required this.color,
    required this.processType,
    required this.bookingCode,
    required this.headline,
    this.progressColor,
    this.progressFraction,
  });

  final String label;
  final Color color;

  /// The current step's colour on the bar, when it must differ from [color]
  /// — on a trip, finished steps are already the stage's green.
  final Color? progressColor;
  final double? progressFraction;
  final int processType;
  final int bookingCode;

  /// Null shows no headline, e.g. a waiting time that is not known.
  final Widget? headline;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            TPulseDot(color: color, size: 8),
            const SizedBox(width: Insets.s8),
            Expanded(
              child: Text(
                label,
                style: context.texts.caption.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Insets.s8),
            Text(
              '#$bookingCode',
              style: context.texts.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: Insets.s8),
        TripProgressBar(
          processType: processType,
          currentColor: progressColor ?? color,
          currentFraction: progressFraction,
        ),
        if (headline != null) ...<Widget>[
          const SizedBox(height: Insets.s8),
          headline!,
        ],
      ],
    );
  }
}

/// At pickup (`DD-37`): how long the driver has waited, counting up from
/// [since] — "2:10", or "1:02:10" past an hour. Ticks itself, so only this
/// line rebuilds each second.
class _WaitingClock extends StatefulWidget {
  const _WaitingClock({required this.since});

  final DateTime since;

  @override
  State<_WaitingClock> createState() => _WaitingClockState();
}

class _WaitingClockState extends State<_WaitingClock> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EtaHero(
      eta: formatClock(DateTime.now().difference(widget.since)),
      detail: "WAITING".tr(),
      loading: false,
    );
  }
}

/// The trip's distance and "≈" fare as two tiles — the request and at-pickup
/// stages show the same pair.
class _TripFigures extends StatelessWidget {
  const _TripFigures({required this.distance, required this.fare});

  final String? distance;
  final String? fare;

  @override
  Widget build(BuildContext context) {
    return _FigureTiles(
      tiles: <(String, String)>[
        if (distance != null) ("TRIP".tr(), distance!),
        if (fare != null) ("EST_FARE".tr(), "≈ ៛$fare"),
      ],
    );
  }
}

/// Labelled figures side by side, equal width.
class _FigureTiles extends StatelessWidget {
  const _FigureTiles({required this.tiles});

  final List<(String, String)> tiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < tiles.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: Insets.s8),
          Expanded(child: _FigureTile(label: tiles[i].$1, value: tiles[i].$2)),
        ],
      ],
    );
  }
}

/// DD-14's note under an estimated fare: only the server's figure is final.
class _EstimateNote extends StatelessWidget {
  const _EstimateNote();

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: TIcon(DsIcons.info, size: TIconSize.sm, color: c.warning),
        ),
        const SizedBox(width: Insets.s4),
        Expanded(
          child: Text(
            "EST_NOTE".tr(),
            style: context.texts.caption.copyWith(color: c.warning),
          ),
        ),
      ],
    );
  }
}

/// The one big figure on the compact stages — "3 min" — with its distance
/// line beside it, wrapping under it on a narrow screen. Skeleton bars while
/// the route is fetched; nothing at all when there is no route.
class _EtaHero extends StatelessWidget {
  const _EtaHero({
    required this.eta,
    required this.detail,
    required this.loading,
  });

  final String? eta;
  final String? detail;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: c.bgSunken,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        );

    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          bar(96, 26),
          const SizedBox(height: Insets.s4),
          bar(140, 14),
        ],
      );
    }
    if (eta == null) return const SizedBox.shrink();
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: Insets.s8,
      children: <Widget>[
        Text(
          eta!,
          style: context.texts.numericLg.copyWith(color: c.textPrimary),
        ),
        if (detail != null)
          Padding(
            // Sits on the figure's baseline rather than its box bottom.
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              detail!,
              style: context.texts.bodySecondary.copyWith(
                color: c.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// One labelled figure on the request sheet: the trip distance, the fare.
class _FigureTile extends StatelessWidget {
  const _FigureTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.s12,
        vertical: Insets.s8,
      ),
      decoration: BoxDecoration(
        color: c.bgPage,
        borderRadius: Radii.controlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: context.texts.micro.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.texts.bodyStrong.copyWith(color: c.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Reports its child's laid-out height after the frame, only when it changes.
class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({required this.onChange, required super.child});

  final ValueChanged<double>? onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureHeight(onChange);

  @override
  void updateRenderObject(
      BuildContext context, _RenderMeasureHeight renderObject) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight(this.onChange);

  ValueChanged<double>? onChange;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final double height = size.height;
    if (onChange == null || height == _reported) return;
    _reported = height;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange?.call(height));
  }
}
