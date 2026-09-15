import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/profile/data/models/profile_model.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/presentation/widgets/simmer_widget.dart';

import '../logic.dart';
import '../state.dart';

/// The driver's profile card in the drawer header — the driver's only profile
/// UI (`14` §6.3).
///
/// UX-redesign C1 restyled it for the light drawer: the orange `DrawerHeader`
/// block became a plain row on white, the photo goes through [TAvatar] so a
/// missing image falls back to initials rather than a broken-image glyph, and
/// the three states use the shared skeleton and error treatments.
///
/// The data it reads, and its three states, are unchanged.
class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ProfileLogic>();
    return Obx(() {
      switch (logic.state.status.value) {
        case ProfileStatus.loaded:
          return _card(context, logic.state.profile.value!.data!);
        case ProfileStatus.error:
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.s16),
            child: Text(
              logic.state.errorMessage.value ??
                  'PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG'.tr(),
              style: context.texts.bodySecondary.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          );
        case ProfileStatus.initial:
        case ProfileStatus.loading:
          return const ShimmerProfile();
      }
    });
  }

  Widget _card(BuildContext context, Data data) {
    final TaarraaColors c = context.colors;
    return Row(
      children: <Widget>[
        TAvatar(
          name: data.name?.toString() ?? '',
          imageUrl: data.profileImage?.toString(),
          size: 54,
        ),
        const SizedBox(width: Insets.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                data.name.toString(),
                style: context.texts.bodyStrong.copyWith(color: c.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                data.phone.toString(),
                style: context.texts.caption.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                // Same expression as before the redesign, including its
                // null-assert on `vehicle`: changing it would change behaviour.
                '${typeVehicle(int.parse(data.vehicle!.typeVehicleId.toString()))} · ${data.driverId ?? "---"}',
                style: context.texts.caption.copyWith(color: c.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
