import 'dart:async';

import 'package:get/get.dart' hide Trans;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:tara_driver_application/app/logic.dart';

import 'state.dart';

/// The shell hosting the driver app's tabs — the same role passenger's
/// `bottom_nav` plays, which is why every tab's binding hangs off this
/// screen's route (`14` §6.2).
///
/// The connectivity subscription and the active-tab index moved off
/// `_DrawerScreenState`; the subscription used to be opened in `initState`
/// and **never cancelled** — `_DrawerScreenState` had no `dispose`, so every
/// `Get.offAllNamed(home)` (logout, cancel, language switch, trip complete)
/// leaked another listener onto `InternetConnection`. `onClose` cancels it.
class DrawerLogic extends GetxController {
  final DrawerState state = DrawerState();

  StreamSubscription<InternetStatus>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = InternetConnection().onStatusChange.listen((event) {
      state.connection.value = event == InternetStatus.connected;
    });
    Get.find<AppLogic>().fetchCurrentDriveInfo();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void selectTab(DrawerTab tab) => state.activeTab.value = tab;
}
