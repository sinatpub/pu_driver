import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/announcement/view.dart';
import 'package:tara_driver_application/presentation/screens/contact_us/view.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/approval_gate.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/driver_drawer.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/offline_banner.dart';
import 'package:tara_driver_application/presentation/screens/drawer/widgets/online_status_pill.dart';
import 'package:tara_driver_application/presentation/screens/history/view.dart';
import 'package:tara_driver_application/presentation/screens/home/view.dart';
import 'package:tara_driver_application/presentation/screens/term_condition/view.dart';
import 'package:tara_driver_application/presentation/screens/wallet/view.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/routes/app_routes.dart';

import 'logic.dart';
import 'state.dart';
import 'package:tara_driver_application/core/utils/app_constant.dart';

/// The app shell. Tab bodies are full screen units in their own right; their
/// bindings hang off this screen's route (`14` §6.2).
///
/// UX-redesign C1 restyled the shell. The structure it had is intact: the same
/// six tabs, the same one-fetch-on-init, the online control on the home tab
/// only, and the approval gate covering the body while the app bar stays
/// reachable.
class DrawerScreen extends StatelessWidget {
  const DrawerScreen({super.key});

  static String _title(DrawerTab tab) {
    switch (tab) {
      case DrawerTab.home:
        return AppConstant.titleApp;
      case DrawerTab.history:
        return "RIDING_HISTORY".tr();
      case DrawerTab.wallet:
        return "MY_WALLET".tr();
      case DrawerTab.termCondition:
        return "TERMCONDITION".tr();
      case DrawerTab.contactUs:
        return "CONTACTUS".tr();
      case DrawerTab.announcement:
        return "CHANNEL".tr();
    }
  }

  static Widget _bodyFor(DrawerTab tab) {
    switch (tab) {
      case DrawerTab.home:
        return HomeScreen();
      case DrawerTab.history:
        return const HistoryPage();
      case DrawerTab.wallet:
        return const WalletPage();
      case DrawerTab.termCondition:
        return const TermConditionPage();
      case DrawerTab.contactUs:
        return const ContactUsPage();
      case DrawerTab.announcement:
        return const AnnouncementPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<DrawerLogic>();
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: c.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: Insets.s8,
        leadingWidth: Sizes.touchTarget + Insets.s16,
        leading: Padding(
          padding: const EdgeInsets.only(left: Insets.s8),
          child: Builder(
            builder: (BuildContext context) => TIconButton(
              icon: DsIcons.menu,
              semanticLabel: 'HOME'.tr(),
              filled: false,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        title: Obx(() => _AppBarTitle(tab: logic.state.activeTab.value)),
        actions: <Widget>[
          TIconButton(
            icon: DsIcons.bell,
            semanticLabel: 'NOTIFICATION'.tr(),
            filled: false,
            onPressed: () => Get.toNamed(AppRoutes.notification),
          ),
          const SizedBox(width: Insets.s8),
          // The availability control belongs to the map, so it shows on the
          // home tab only — as it did before.
          Obx(
            () => logic.state.activeTab.value == DrawerTab.home
                ? const OnlineStatusPill()
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: Insets.s12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.borderDivider),
        ),
      ),
      drawer: Obx(
        () => DriverDrawer(
          activeTab: logic.state.activeTab.value,
          onSelect: (DrawerTab tab) {
            Navigator.pop(context);
            logic.selectTab(tab);
          },
        ),
      ),
      body: Stack(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Obx(() => _bodyFor(logic.state.activeTab.value)),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(bottom: false, child: OfflineBanner()),
          ),
          const ApprovalGate(),
        ],
      ),
    );
  }
}

/// The wordmark on the home tab, the tab's name everywhere else.
class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.tab});

  final DrawerTab tab;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    if (tab != DrawerTab.home) {
      return Text(
        DrawerScreen._title(tab),
        style: context.texts.subtitle.copyWith(color: c.textPrimary),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          AppConstant.titleApp,
          style: context.texts.subtitle.copyWith(
            color: c.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          // Identical in both languages in the prototype's dictionary, so it
          // carries no translation key.
          'DRIVER · តារា',
          style: context.texts.micro.copyWith(
            color: c.brandText,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
