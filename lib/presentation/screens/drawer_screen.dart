import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/resources/asset_resource.dart';
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:tara_driver_application/features/home/presentation/controller/home_controller.dart';
import 'package:tara_driver_application/presentation/blocs/get_current_driver_info_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/profile/presentation/controller/profile_controller.dart';
import 'package:tara_driver_application/presentation/screens/contact_us_screen.dart';
import 'package:tara_driver_application/presentation/screens/home_screen/widgets/switch_online_widget.dart';
import 'package:tara_driver_application/presentation/screens/home_screen/home_screen.dart';
import 'package:tara_driver_application/presentation/screens/history_booking/riding_history_screen.dart';
import 'package:tara_driver_application/presentation/screens/notification/view/notification_screen.dart';
import 'package:tara_driver_application/presentation/screens/payment_screen.dart';
import 'package:tara_driver_application/presentation/screens/termcondition_screen.dart';
import 'package:tara_driver_application/presentation/widgets/simmer_widget.dart';
import 'package:tara_driver_application/presentation/widgets/t_image_widget.dart';
import 'package:tara_driver_application/presentation/widgets/widget_change_laguage.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({
    super.key,
  });

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  bool connection = true;
  StreamSubscription? sub;
  int isActiveIndex = 0;

  @override
  void initState() {
    //=============Check internet====================
    sub = InternetConnection().onStatusChange.listen((event) {
      switch (event) {
        case InternetStatus.connected:
          setState(() {
            connection = true;
          });
          break;
        case InternetStatus.disconnected:
          setState(() {
            connection = false;
          });
          break;
        default:
          setState(() {
            connection = false;
          });
          break;
      }
    });
    //=============Eend Check internet====================
    BlocProvider.of<CurrentDriverInfoBloc>(context).add(GetCurrentInfoEvent());
    super.initState();
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return "TAARRAA".tr();
      case 1:
        return "RIDING_HISTORY".tr();
      case 2:
        return "MY_WALLET".tr();
      case 3:
        return "TERMCONDITION".tr();
      case 4:
        return "CONTACTUS".tr();
      case 5:
        return "CHANNEL".tr();
      default:
        return "WELCOME_TO_TARA".tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final translate = context.locale.toString();
    return Scaffold(
      backgroundColor: AppColors.light1,
      appBar: AppBar(
        foregroundColor: AppColors.dark1,
        backgroundColor: AppColors.light4,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getTitle(isActiveIndex),
              style: ThemeConstands.font20SemiBold
                  .copyWith(color: AppColors.dark1),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
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
            isActiveIndex == 0
                ? SwitchOnlineWidget()
                : Container(
                    width: 55,
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
              child: Obx(() {
                final controller = Get.find<ProfileController>();
                final status = controller.status.value;
                if (status == ProfileStatus.loaded) {
                  var data = controller.profile.value?.data;
                  return Container(
                    padding: EdgeInsets.all(16),
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TImageWidget(
                            image: NetworkImage(data!.profileImage.toString()),
                            width: 80,
                            height: 80,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                data.name.toString(),
                                style: ThemeConstands.font22SemiBold
                                    .copyWith(color: AppColors.light4),
                              ),
                              Text(
                                data.phone.toString(),
                                style: ThemeConstands.font16Regular
                                    .copyWith(color: AppColors.light4),
                              ),
                              Builder(builder: (context) {
                                return Text(
                                  "${typeVehicle(int.parse(data.vehicle!.typeVehicleId.toString()))} - ${data.driverId ?? "---"}",
                                  style: ThemeConstands.font16Regular
                                      .copyWith(color: AppColors.light4),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (status == ProfileStatus.error) {
                  return Center(
                    child: Text(
                      controller.errorMessage.value ?? 'Something went wrong.',
                      style: ThemeConstands.font16Regular
                          .copyWith(color: AppColors.light4),
                      textAlign: TextAlign.center,
                    ),
                  );
                } else {
                  return const ShimmerProfile();
                }
              }),
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
                        setState(() {
                          isActiveIndex = 0;
                        });
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
                        setState(() {
                          isActiveIndex = 1;
                        });
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
                        setState(() {
                          isActiveIndex = 2;
                        });
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
                        setState(() {
                          isActiveIndex = 3;
                        });
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
                        setState(() {
                          isActiveIndex = 4;
                        });
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
                    //     setState(() {
                    //       isActiveIndex = 5;
                    //     });
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
      body: BlocListener<CurrentDriverInfoBloc, CurrentDriverInfoState>(
        listener: (context, state) {
          if (state is CurrentDriverLoading) {
            tlog("Current Driver Loading");
          } else if (state is CurrentDriverInfoLoaded) {
            tlog("Current Driver Loaded");
            Get.find<HomeController>().setApprovalStatus(
              state.currentDriverInfoModel.data?.driver?.status,
            );
          } else {
            tlog("Current Driver Fail");
          }
        },
        child: Stack(
          children: [
            SafeArea(
                bottom: false,
                child: isActiveIndex == 0
                    ? HomeScreen()
                    : isActiveIndex == 1
                        ? const RidingHistoryScreen()
                        : isActiveIndex == 2
                            ? PaymentScreen()
                            : isActiveIndex == 4
                                ? ContactUsScreen()
                                : isActiveIndex == 3
                                    ? TermsOfServicePage()
                                    : isActiveIndex == 5
                                        ? NotificationPage()
                                        : const HomeScreen()),
            Obx(() {
              if (Get.find<HomeController>().isApproved) return const SizedBox();
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
              if (Get.find<HomeController>().isApproved) return const SizedBox();
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
      ),
    );
  }
}
