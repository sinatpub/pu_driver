import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/presentation/screens/home/data/repository/home_repository.dart';
import 'package:pu_taxi_driver/services/online_service.dart';
import 'package:pu_taxi_driver/services/session_service.dart';

import 'state.dart';

/// D-03/D-04 (`12`) — replaces `HomeBloc` and `CurrentDriverInfoBloc`.
///
/// App-lifetime driver state: online/offline, approval gate, and the current
/// in-progress ride. Every one of those is read by more than one screen —
/// `drawer/`'s approval banner and app-bar toggle, `home/`'s ride-status
/// redirect — so it belongs to the app, not to a screen (`14` §2, §3.5).
/// This is driver's counterpart to passenger's `AppLogic`, and it is
/// registered exactly once, in `app/service.dart`.
///
/// `HomeBloc`'s `GetCurrentLocationEvent`/`GenerateMarker` and their states
/// were dead — never dispatched, never consumed — and were not ported.
///
/// ## Going online without a tap (DD-53)
///
/// A driver who opens the app is there to work, so the app puts them online
/// itself — once per sign-in session, as soon as three things are known:
/// the account may work ([isApproved]), the server's own idea of their
/// availability has been read ([AppState.statusChecked]), and the phone has
/// a GPS fix ([AppState.locationReady]). They stay offline only when one of
/// those is missing — the check failed, the account is waiting or rejected,
/// there is no location — or when the server refuses, which is said in a
/// message. After that the pill is the driver's: a driver who turns
/// themselves off is not turned back on.
///
/// ## Online with the screen off (DD-58)
///
/// While [AppState.isOnline] is true the Android [OnlineService] runs, so the
/// socket that brings ride requests outlives the screen. It follows the
/// state: whatever turns the driver on or off starts or stops it.
class AppLogic extends GetxController {
  AppLogic(
    this._repository, {
    SessionService? session,
    OnlineService? onlineService,
    void Function(String message)? showMessage,
    void Function()? showBusy,
    void Function()? hideBusy,
  })  : _session = session ?? SessionService.instance,
        _onlineService = onlineService ?? OnlineService.instance,
        _showMessage = showMessage ?? EasyLoading.showToast,
        _showBusy = showBusy ?? EasyLoading.show,
        _hideBusy = hideBusy ?? EasyLoading.dismiss;

  final HomeRepository _repository;
  final SessionService _session;
  final OnlineService _onlineService;

  // The three EasyLoading calls, passed in so the logic can be tested
  // without the overlay it needs to be mounted in.
  final void Function(String message) _showMessage;
  final void Function() _showBusy;
  final void Function() _hideBusy;

  final AppState state = AppState();

  /// The driver has been put online for this session, or has used the pill
  /// themselves. Either way the app does not decide for them again.
  bool _autoOnlineUsed = false;

  /// [SessionService.endedSessions] when this state was last filled.
  int _sessionsSeen = 0;

  bool get isApproved =>
      state.approvalStatus.value == DriverApprovalStatus.approved;

  @override
  void onInit() {
    super.onInit();
    _sessionsSeen = _session.endedSessions;
    everAll(
      <RxInterface<dynamic>>[
        state.approvalStatus,
        state.statusChecked,
        state.locationReady,
      ],
      (_) => _goOnlineWhenReady(),
    );
    ever<bool>(state.isOnline, _followOnline);
  }

  /// What the service was last told. `isOnline` also reports being set to
  /// the value it already has.
  bool _serviceRunning = false;

  void _followOnline(bool online) {
    if (online == _serviceRunning) return;
    _serviceRunning = online;
    online ? _onlineService.start() : _onlineService.stop();
  }

  /// This object lives as long as the app does, so after a sign-out it still
  /// holds the last driver's answers. Called where a session starts (the
  /// shell's first fetch): if a session has ended since, start clean — and
  /// let the next driver be put online too.
  void _startCleanAfterSignOut() {
    if (_session.endedSessions == _sessionsSeen) return;
    _sessionsSeen = _session.endedSessions;
    _autoOnlineUsed = false;
    state.approvalStatus.value = DriverApprovalStatus.unknown;
    state.approvalCheckFailed.value = false;
    state.statusChecked.value = false;
    state.locationReady.value = false;
    state.isOnline.value = false;
    state.currentDriveInfo.value = null;
  }

  /// The home reports whether it has a GPS fix.
  void setLocationReady(bool ready) => state.locationReady.value = ready;

  Future<void> _goOnlineWhenReady() async {
    if (_autoOnlineUsed ||
        !isApproved ||
        !state.statusChecked.value ||
        !state.locationReady.value) {
      return;
    }
    // Once, whatever comes of it: a refusal is told to the driver, not
    // retried behind their back.
    _autoOnlineUsed = true;
    // The server still had them online from last time.
    if (state.isOnline.value) return;
    await _setOnline(true, quiet: true);
  }

  /// Fetched once from `DrawerLogic.onInit`, the same trigger point the bloc
  /// had. `home/logic.dart` reacts to changes via `ever()` to redirect into
  /// an in-progress ride, and this also feeds the D-03 approval gate — the
  /// bloc's driver-approval consumer and its ride-status consumer read the
  /// same API response, so one fetch serves both. A driver with no ride gets
  /// `"data": null`, which opens the gate: see [approvalStatusForDriveInfo].
  ///
  /// [AppState.approvalChecking] is true while it runs, and
  /// [AppState.approvalCheckFailed] says afterwards whether the driver is
  /// still without an answer (DD-52). A check that fails for a driver whose
  /// status is already known changes nothing: they keep what they had.
  Future<void> fetchCurrentDriveInfo() async {
    if (state.approvalChecking.value) return;
    _startCleanAfterSignOut();
    state.approvalChecking.value = true;
    state.approvalCheckFailed.value = false;
    try {
      final result = await _repository.getCurrentDriveInfo();
      result.when(
        ok: (data) {
          state.approvalStatus.value = approvalStatusForDriveInfo(data);
          state.currentDriveInfo.value = data;
        },
        err: (_) {},
      );
    } finally {
      state.approvalChecking.value = false;
      state.approvalCheckFailed.value =
          state.approvalStatus.value == DriverApprovalStatus.unknown;
    }
  }

  Future<void> checkStatus() async {
    final result = await _repository.getStatus();
    result.when(
      ok: (data) => state.isOnline.value = data.data?.isAvailable == 1,
      err: (_) {},
    );
    // Also after a failure: not knowing is no reason to leave the driver
    // offline, and `set-status` will say so if the server cannot be reached.
    state.statusChecked.value = true;
  }

  /// The original (`HomeBloc._toggleDriverService`) set `isOnline`
  /// optimistically before the request resolved, same as here, but never
  /// rolled it back on failure and never dismissed its EasyLoading overlay
  /// outside the success path — a failed toggle left the switch showing the
  /// wrong state forever under a spinner that never went away. Fixed:
  /// rollback on error, dismiss in `finally`.
  ///
  /// This is the pill — the driver's own choice — so it also ends the app's
  /// say in the matter for this session (DD-53).
  Future<void> toggle(bool turnOn) async {
    if (turnOn && !isApproved) return;
    _autoOnlineUsed = true;
    await _setOnline(turnOn, quiet: false);
  }

  /// [quiet] is the app going online by itself: no overlay over the home,
  /// the status card just changes. A failure is said either way — the
  /// server's own words when it sent some — because a switch that falls
  /// back without a reason reads as a broken switch.
  Future<void> _setOnline(bool turnOn, {required bool quiet}) async {
    final previous = state.isOnline.value;
    state.isOnline.value = turnOn;
    if (!quiet) _showBusy();
    try {
      final result = await _repository.setStatus(turnOn ? 1 : 0);
      result.when(
        ok: (data) => state.isOnline.value = data.data?.isAvailable == 1,
        err: (error) {
          state.isOnline.value = previous;
          _showMessage(error.message);
        },
      );
    } finally {
      if (!quiet) _hideBusy();
    }
  }
}
