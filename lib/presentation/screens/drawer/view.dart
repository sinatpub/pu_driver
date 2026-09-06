import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:tara_driver_application/core/resources/asset_resource.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/app/logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:get/get.dart' hide Trans;

import 'logic.dart';
import 'state.dart';
import 'package:tara_driver_application/presentation/screens/profile/widgets/profile_header_widget.dart';
import 'package:tara_driver_application/presentation/screens/contact_us/view.dart';
import 'package:tara_driver_application/presentation/screens/home/widgets/switch_online_widget.dart';
import 'package:tara_driver_application/presentation/screens/home/view.dart';
import 'package:tara_driver_application/presentation/screens/history/view.dart';
import 'package:tara_driver_application/presentation/screens/announcement/view.dart';
import 'package:tara_driver_application/presentation/screens/wallet/view.dart';
import 'package:tara_driver_application/presentation/screens/term_condition/view.dart';
import 'package:tara_driver_application/presentation/widgets/widget_change_laguage.dart';

/// The app shell. Tab bodies are full screen units in their own right; their
/// bindings hang off this screen's route (`14` §6.2).
class DrawerScreen extends StatelessWidget {
  const DrawerScreen({super.key});

  static String _title(DrawerTab tab) {
    switch (tab) {
      case DrawerTab.home:
        return "TAARRAA".tr();
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
    final translate = context.locale.toString();
    return Scaffold(
      backgroundColor: AppColors.light1,
      appBar: AppBar(
        foregroundColor: AppColors.dark1,
        backgroundColor: AppColors.light4,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(
              () => Text(
                _title(logic.state.activeTab.value),
                style: ThemeConstands.font20SemiBold
                    .copyWith(color: AppColors.dark1),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () {
                Get.toNamed(AppRoutes.notification);
              },
              icon: Icon(
                CupertinoIcons.bell_circle_fill,
                color: AppColors.main,
                size: 44,
              ),
            ),
            Obx(
              () => logic.state.activeTab.value == DrawerTab.home
                  ? SwitchOnlineWidget()
                  : Container(width: 55),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                  color: AppColors.main,
                  border: Border.all(color: Colors.transparent)),
              child: const ProfileHeaderWidget(),
            ),
            // Body List
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      selectedColor: AppColors.main,
                      leading: SvgPicture.asset(
                        ImageAssets.home_outline,
                        color: AppColors.main,
                      ),
                      title: Text(
                        "HOME".tr(),
                        style: ThemeConstands.font20Regular,
                      ),
                      onTap: () {
                        // Taxi.shared.notifyBooking(
                        //     title: "NEWREQUEST".tr(),
                        //     description: "DESREQUEST".tr(),
                        //     isSound: true);
                        Navigator.pop(context);
                        logic.selectTab(DrawerTab.home);
                        // Handle navigation
                      },
                    ),
                    ListTile(
                      selectedColor: AppColors.main,
                      leading: SvgPicture.asset(
                        ImageAssets.book_outline,
                        color: AppColors.main,
                      ),
                      title: Text(
                        "HISTORY".tr(),
                        style: ThemeConstands.font20Regular,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        logic.selectTab(DrawerTab.history);
                        // Handle navigation
                      },
                    ),
                    ListTile(
                      selectedColor: AppColors.main,
                      leading: Icon(
                        Icons.wallet_outlined,
                        size: 26,
                        color: AppColors.main,
                      ),
                      title: Text(
                        "WALLET".tr(),
                        style: ThemeConstands.font20Regular,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        logic.selectTab(DrawerTab.wallet);
                        // Handle navigation
                      },
                    ),
                    ListTile(
                      selectedColor: AppColors.main,
                      leading:
                          SvgPicture.asset(ImageAssets.icon_contact_setting),
                      title: Text(
                        "TERMCONDITION".tr(),
                        style: ThemeConstands.font20Regular,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        logic.selectTab(DrawerTab.termCondition);
                        // Handle navigation
                      },
                    ),
                    ListTile(
                      selectedColor: AppColors.main,
                      leading: Icon(
                        Icons.contact_phone_outlined,
                        size: 22,
                        color: AppColors.main,
                      ),
                      title: Text(
                        "CONTACTUS".tr(),
                        style: ThemeConstands.font20Regular,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        logic.selectTab(DrawerTab.contactUs);
                        // Handle navigation
                      },
                    ),
                    // ListTile(
                    //   selectedColor: AppColors.main,
                    //   leading: Icon(
                    //     Icons.notifications_none_sharp,
                    //     size: 28,
                    //     color: AppColors.main,
                    //   ),
                    //   title: Text(
                    //     "CHANNEL".tr(),
                    //     style: ThemeConstands.font20Regular,
                    //   ),
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //     logic.selectTab(DrawerTab.announcement);
                    //     // Handle navigation
                    //   },
                    // ),
                    ListTile(
                      selectedColor: AppColors.main,
                      leading: translate == "km"
                          ? SvgPicture.asset(
                              ImageAssets.flag_km,
                              width: 30,
                            )
                          : Image.asset(
                              ImageAssets.flag_en,
                              width: 30,
                            ),
                      title: Text(
                        "CHOOSE_LANGUADE".tr(),
                        style: ThemeConstands.font20Regular,
                      ),
                      onTap: () {
                        showModalBottomSheet(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16)),
                            ),
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(builder:
                                  (BuildContext context,
                                      StateSetter stateSetter) {
                                return ChangeLanguage();
                              });
                            });
                        // Handle navigation
                      },
                    ),
                    // Container(
                    //   margin: const EdgeInsets.only(
                    //       left: 16, right: 16, bottom: 16, top: 28),
                    //   decoration: const BoxDecoration(
                    //     color: AppColors.light4,
                    //     borderRadius: BorderRadius.all(Radius.circular(8)),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Color(0xFFEDEBEB),
                    //         spreadRadius: 2,
                    //         blurRadius: 10,
                    //         offset: Offset(0, 1),
                    //       ),
                    //     ],
                    //   ),
                    //   child: MaterialButton(
                    //     height: 50,
                    //     shape: const RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.all(Radius.circular(8)),
                    //     ),
                    //     elevation: 0,
                    //     onPressed: () async {
                    //       AlertWidget().logout(
                    //         context,
                    //       );
                    //     },
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         SvgPicture.asset(
                    //           ImageAssets.icon_logout,
                    //           width: 30,
                    //           height: 30,
                    //         ),
                    //         const SizedBox(
                    //           width: 16,
                    //         ),
                    //         Text(
                    //           "LOGOUT".tr(),
                    //           style: ThemeConstands.font16Regular
                    //               .copyWith(color: AppColors.dark1),
                    //           textAlign: TextAlign.left,
                    //         )
                    //       ],
                    //     ),
                    //   ),
                    // )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Obx(() => _bodyFor(logic.state.activeTab.value)),
          ),
          Obx(() {
            if (Get.find<AppLogic>().isApproved) return const SizedBox();
            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: 0,
              child: Container(
                color: Colors.white.withValues(alpha: .1),
              ),
            );
          }),
          Obx(() {
            if (Get.find<AppLogic>().isApproved) return const SizedBox();
            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 250,
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    SvgPicture.asset("assets/icon/svg/waiting_approve.svg"),
                    Text(
                      "WAITING_APPROVED_FROM_ADMIN".tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
