import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/presentation/widgets/simmer_widget.dart';
import 'package:tara_driver_application/features/profile/data/models/profile_model.dart';
import 'package:tara_driver_application/presentation/widgets/t_image_widget.dart';

import '../logic.dart';
import '../state.dart';

/// The driver's profile card in the drawer header — driver's only profile UI
/// (`14` §6.3). Lifted verbatim out of `drawer_screen.dart`'s `DrawerHeader`.
class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ProfileLogic>();

    return Obx(() {
      switch (logic.state.status.value) {
        case ProfileStatus.loaded:
          return _card(logic.state.profile.value!.data!);
        case ProfileStatus.error:
          return Center(
            child: Text(
              logic.state.errorMessage.value ?? 'Something went wrong.',
              style: ThemeConstands.font16Regular
                  .copyWith(color: AppColors.light4),
              textAlign: TextAlign.center,
            ),
          );
        case ProfileStatus.initial:
        case ProfileStatus.loading:
          return const ShimmerProfile();
      }
    });
  }

  Widget _card(Data data) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.bottomLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TImageWidget(
              image: NetworkImage(data.profileImage.toString()),
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(width: 16),
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
                Text(
                  "${typeVehicle(int.parse(data.vehicle!.typeVehicleId.toString()))} - ${data.driverId ?? "---"}",
                  style: ThemeConstands.font16Regular
                      .copyWith(color: AppColors.light4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
