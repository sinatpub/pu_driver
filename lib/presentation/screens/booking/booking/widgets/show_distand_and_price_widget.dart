import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';

class ShowDistandWidget extends StatefulWidget {
  final dynamic distand;
  final dynamic duration;
  final dynamic cost;
  const ShowDistandWidget({super.key,required this.cost,required this.distand,required this.duration});

  @override
  State<ShowDistandWidget> createState() => _ShowDistandWidgetState();
}

class _ShowDistandWidgetState extends State<ShowDistandWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18),bottomRight: Radius.circular(18)),
        color: AppColors.light3,
        boxShadow: [
          BoxShadow(
            color: AppColors.dark2.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('${"DURATION".tr()} (${"Hour".tr()})',style: ThemeConstands.font16Regular,),
                Text(widget.duration,style: ThemeConstands.font16SemiBold,),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('${"DISTANCE".tr()} (${"km".tr()})',style: ThemeConstands.font16Regular,),
                Text(widget.distand.toString(),style: ThemeConstands.font16SemiBold,),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('${"TOTAL_PRICE".tr()} (${"khr".tr()})',style: ThemeConstands.font16Regular.copyWith(color: AppColors.info),),
                Text(widget.cost.toString(),style: ThemeConstands.font16SemiBold.copyWith(color: AppColors.info),),
              ],
            ),
          ),
        ],
      ),
    );
  }
}