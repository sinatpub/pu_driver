import 'package:get/get.dart' hide Trans;

import 'logic.dart';
import 'state.dart';
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/presentation/widgets/t_image_widget.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tara_driver_application/core/resources/asset_resource.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/presentation/widgets/fbtn_widget.dart';

/// Was `calculate_fee_screen.dart`. Despite `12`'s table naming
/// `payment_screen.dart` for D-08, this is the real accept-payment screen
/// (`14` §5). Route arguments are unpacked by [CalculateFeeBinding].
class CalculateFeeScreen extends StatelessWidget {
  const CalculateFeeScreen({super.key});

  static String formartDate(String dateTime) {
    var newStr = '${dateTime.substring(0, 10)} ${dateTime.substring(11, 23)}';
    DateTime dt = DateTime.parse(newStr);
    return DateFormat("EEE/d/MMM/yyyy - HH:mma").format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<CalculateFeeLogic>();

    return Scaffold(
      backgroundColor: AppColors.light4,
      body: SafeArea(
        bottom: false,
        child: Container(
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  "CALCULATE_FEE".tr(),
                  style: ThemeConstands.font22SemiBold
                      .copyWith(color: AppColors.dark1),
                ),
              ),
              const Divider(
                height: 1,
                color: AppColors.light1,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      logic.isFromDropBooking
                          ? bodyRecive(
                              context,
                              startTime: logic.dataComplete!.data!.startTime
                                  .toString(),
                              endAdd: logic.dataComplete!.data!.endAddress
                                  .toString(),
                              startAdd: logic.dataComplete!.data!.startAddress
                                  .toString(),
                              profile: logic
                                  .dataComplete!.data!.passenger!.profileImage!,
                              passagerName: logic
                                  .dataComplete!.data!.passenger!.name
                                  .toString(),
                              amount: logic.dataComplete!.data!.payment!.amount
                                  .toString(),
                              createAt: logic
                                  .dataComplete!.data!.payment!.createdAt
                                  .toString(),
                              distance: logic
                                  .dataComplete!.data!.payment!.distance
                                  .toString(),
                              duration: logic
                                  .dataComplete!.data!.payment!.duration
                                  .toString(),
                            )
                          : bodyRecive(
                              context,
                              startTime:
                                  logic.dataDriverInfo!.startTime.toString(),
                              endAdd:
                                  logic.dataDriverInfo!.endAddress.toString(),
                              startAdd:
                                  logic.dataDriverInfo!.startAddress.toString(),
                              profile: logic
                                  .dataDriverInfo!.passenger!.profileImage!,
                              passagerName: logic
                                  .dataDriverInfo!.passenger!.name
                                  .toString(),
                              amount: logic.dataDriverInfo!.payment!.amount
                                  .toString(),
                              createAt: logic.dataDriverInfo!.payment!.createdAt
                                  .toString(),
                              distance: logic.dataDriverInfo!.payment!.distance
                                  .toString(),
                              duration: logic.dataDriverInfo!.payment!.duration
                                  .toString(),
                            ),
                      const SizedBox(
                        height: 18,
                      ),
                      Obx(() => FBTNWidget(
                            loadingBut: logic.state.status.value ==
                                PaymentStatus.loading,
                            onPressed: () => logic.acceptPayment(),
                            width: 200,
                            color: AppColors.red,
                            textColor: AppColors.light4,
                            label: "PAYMENT_DONE".tr(),
                            enableWidth: true,
                          ))
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget bodyRecive(
    BuildContext context, {
    required String profile,
    required String passagerName,
    required String createAt,
    required String duration,
    required String distance,
    required String amount,
    required String startAdd,
    required String endAdd,
    required String startTime,
  }) {
    return Container(
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.light4,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            blurStyle: BlurStyle.normal,
            color: Colors.grey.withOpacity(0.2),
            offset: const Offset(5, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TImageWidget(
                        image: NetworkImage(profile),
                        width: 50,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              passagerName,
                              style: ThemeConstands.font20SemiBold
                                  .copyWith(color: AppColors.dark1),
                            ),
                            Text(
                              "${"METHOD".tr()} ${"Unknown Payment"}",
                              style: ThemeConstands.font14Regular
                                  .copyWith(color: AppColors.dark1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                        child: Text(
                      "PAYMENT_COLLECTION".tr(),
                      style: ThemeConstands.font14SemiBold
                          .copyWith(color: AppColors.main),
                      textAlign: TextAlign.start,
                    )),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            ImageAssets.map_outline,
                            width: 20,
                            color: AppColors.red,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            formatDistanceWithUnits(distance, context),
                            style: ThemeConstands.font16SemiBold
                                .copyWith(color: AppColors.dark1),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            ImageAssets.time_outline,
                            width: 20,
                            color: AppColors.red,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            convertTimeString(duration),
                            style: ThemeConstands.font14Regular
                                .copyWith(color: AppColors.dark1),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SvgPicture.asset(
                            ImageAssets.payment_outline,
                            width: 20,
                            color: AppColors.red,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            "៛${formatToTwoDecimalPlaces(amount)}",
                            style: ThemeConstands.font14SemiBold
                                .copyWith(color: AppColors.dark1),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 18,
                ),
                const Divider(
                  color: AppColors.light1,
                  thickness: 1,
                  height: 1,
                ),
                const SizedBox(
                  height: 18,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "DATE_TIME".tr(),
                      style: ThemeConstands.font14Regular
                          .copyWith(color: AppColors.dark1),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      formatDateTime(startTime),
                      style: ThemeConstands.font14Regular
                          .copyWith(color: AppColors.dark1),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 18,
                ),
                const Divider(
                  color: AppColors.light1,
                  thickness: 1,
                  height: 1,
                ),
                const SizedBox(
                  height: 18,
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          ImageAssets.current_location,
                          width: 22,
                          color: AppColors.dark1,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                            child: Text(
                          startAdd,
                          style: ThemeConstands.font16Regular
                              .copyWith(color: AppColors.dark1),
                        )),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      alignment: Alignment.centerLeft,
                      child: const DottedLine(
                        alignment: WrapAlignment.start,
                        lineLength: 30,
                        direction: Axis.vertical,
                        lineThickness: 1,
                        dashColor: AppColors.dark1,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          ImageAssets.book_outline,
                          width: 20,
                          color: AppColors.red,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                            child: Text(
                          endAdd.toString(),
                          style: ThemeConstands.font16Regular
                              .copyWith(color: AppColors.dark1),
                        )),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12))),
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                    "${"TOTAL_PRICE".tr()}:",
                    style: ThemeConstands.font16SemiBold
                        .copyWith(color: AppColors.light4),
                    textAlign: TextAlign.start,
                  )),
                  Expanded(
                      child: Text(
                    "៛${formatToTwoDecimalPlaces(amount)}",
                    style: ThemeConstands.font18SemiBold
                        .copyWith(color: AppColors.light4),
                    textAlign: TextAlign.end,
                  )),
                ],
              ))
        ],
      ),
    );
  }
}
