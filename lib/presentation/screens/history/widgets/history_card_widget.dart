import 'package:dotted_line/dotted_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/contracts/booking_status.dart';
import 'package:tara_driver_application/core/resources/asset_resource.dart';
import 'package:tara_driver_application/routes/app_routes.dart';
import 'package:tara_driver_application/routes/route_arguments.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/features/history/data/models/history_driver_info_model.dart';
import 'package:tara_driver_application/presentation/widgets/t_image_widget.dart';

/// One trip in the riding-history list. Lifted verbatim out of
/// `riding_history_screen.dart`'s `itemBuilder`, which was ~180 lines of
/// nested layout inline in the screen (`14` §3.3).
class HistoryCardWidget extends StatelessWidget {
  const HistoryCardWidget({
    super.key,
    required this.item,
    required this.showMap,
  });

  final DataHistory item;

  /// The map thumbnail is hidden on the cancelled tab — a cancelled trip has
  /// no route to show.
  final bool showMap;

  bool get _isCompleted => item.status == BookingStatus.completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(left: 18, right: 18, top: 18),
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
          _header(),
          const SizedBox(height: 12),
          _metrics(context),
          const SizedBox(height: 18),
          const Divider(color: AppColors.light1, thickness: 1, height: 1),
          const SizedBox(height: 18),
          _dateRow(),
          const SizedBox(height: 18),
          const Divider(color: AppColors.light1, thickness: 1, height: 1),
          const SizedBox(height: 18),
          if (showMap) _mapThumbnail(context),
          _addresses(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TImageWidget(
            image: NetworkImage(item.passenger!.profileImage.toString()),
            width: 50,
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${"INVOICE".tr()}: #${item.payment!.invoiceId}",
                      style: ThemeConstands.font14Regular
                          .copyWith(color: AppColors.dark2),
                      textAlign: TextAlign.start,
                    ),
                    Text(
                      item.statusName.toString().toUpperCase().tr(),
                      style: ThemeConstands.font14SemiBold.copyWith(
                        color:
                            _isCompleted ? AppColors.success : AppColors.dark2,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
                Text(
                  item.passenger!.name.toString(),
                  style: ThemeConstands.font20SemiBold
                      .copyWith(color: AppColors.dark1),
                ),
                Text(
                  "${"METHOD".tr()} ${item.payment!.paymentMethod}",
                  style: ThemeConstands.font14Regular
                      .copyWith(color: AppColors.dark1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metrics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(ImageAssets.map_outline,
                  width: 20, color: AppColors.red),
              const SizedBox(width: 8),
              Text(
                formatDistanceWithUnits(
                    item.payment!.distance.toString(), context),
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
              SvgPicture.asset(ImageAssets.time_outline,
                  width: 20, color: AppColors.red),
              const SizedBox(width: 8),
              Text(
                _isCompleted
                    ? convertTimeString(item.payment!.duration.toString())
                    : "UNKNOWN".tr(),
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
              SvgPicture.asset(ImageAssets.payment_outline,
                  width: 20, color: AppColors.red),
              const SizedBox(width: 8),
              Text(
                "៛${formatToTwoDecimalPlaces(item.payment!.amount.toString())}",
                style: ThemeConstands.font14SemiBold
                    .copyWith(color: AppColors.dark1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "DATE_TIME".tr(),
          style: ThemeConstands.font14Regular.copyWith(color: AppColors.dark1),
        ),
        const SizedBox(width: 8),
        Text(
          _isCompleted
              ? formatDateTime(item.startTime.toString())
              : "UNKNOWN".tr(),
          style: ThemeConstands.font14Regular.copyWith(color: AppColors.dark1),
        ),
      ],
    );
  }

  Widget _mapThumbnail(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.mapHistoryDetail,
          arguments: MapHistoryDetailArgs(
            cost: formatToTwoDecimalPlaces(item.payment!.amount.toString()),
            duration: convertTimeString(item.payment!.duration.toString()),
            distand: formatDistanceWithUnits(
                item.payment!.distance.toString(), context),
            typeVehicleId: item.driver!.vehicle!.typeVehicleId!,
            latEnd: double.parse(item.endLatitude.toString()),
            latStart: double.parse(item.startLatitude.toString()),
            lngEnd: double.parse(item.endLongitude.toString()),
            lngStart: double.parse(item.startLongitude.toString()),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/image/png/image_map.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _addresses() {
    final isCancelled = item.status == BookingStatus.cancel;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(ImageAssets.current_location,
                width: 22, color: AppColors.dark1),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isCompleted ? item.startAddress.toString() : "UNKNOWN".tr(),
                style: ThemeConstands.font16Regular
                    .copyWith(color: AppColors.dark1),
              ),
            ),
          ],
        ),
        if (!isCancelled) ...[
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
              SvgPicture.asset(ImageAssets.book_outline,
                  width: 20, color: AppColors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isCompleted ? item.endAddress.toString() : "UNKNOWN".tr(),
                  style: ThemeConstands.font16Regular
                      .copyWith(color: AppColors.dark1),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
