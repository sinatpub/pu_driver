import 'package:get/get.dart' hide Trans;

/// Drawer tab indices. Were bare ints 0–5 compared in a nested ternary and
/// in `_getTitle`'s switch; the two lists were kept in sync by hand.
enum DrawerTab { home, history, wallet, termCondition, contactUs, announcement }

class DrawerState {
  final Rx<DrawerTab> activeTab = Rx<DrawerTab>(DrawerTab.home);

  /// Network reachability — drives the offline banner.
  final RxBool connection = true.obs;
}
