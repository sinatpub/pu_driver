import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:tara_driver_application/data/models/vehical_model.dart';
import 'package:tara_driver_application/presentation/controllers/vehicle_controller.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/presentation/widgets/x_dropdown_search.dart';

import 'logic.dart';
import 'state.dart';
import 'widgets/photo_slot.dart';

/// UX-redesign S4 (`03 S04`, `DD-24`).
///
/// `TTextField`s, the existing searchable vehicle dropdown (restyled), colour
/// and plate side by side, a 2×2 [PhotoSlot] grid, and a 56 px submit pinned
/// at the bottom with its own spinner. The photo picker is a `TSheet` with the
/// same two choices, calling the same `pickFromGallery` / `pickFromCamera`.
///
/// **The enable rule is unchanged** ([canSubmit]): submit is enabled unless
/// name **and** plate are both empty — not the prototype's stricter rule.
/// Missing photos still surface as the controller's error dialog, as before.
/// No "24 hours" note (unconfirmed). P2 moved the form copy — once hardcoded
/// "English - Khmer" pairs — onto locale keys, so each language shows its own.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  /// Today's rule, verbatim (`register/view.dart:408-411` before S4).
  static bool canSubmit(String name, String plate) =>
      !(name == '' && plate == '');

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Resolved on each access, never cached: GetX owns this instance's
  // lifetime, and a `final` field would keep pointing at a disposed one
  // if the route is left and re-entered (hit on device 2026-09-06 —
  // "A TextEditingController was used after being disposed").
  RegisterLogic get logic => Get.find<RegisterLogic>();
  VehicleController get vehicleController => Get.find<VehicleController>();

  @override
  void initState() {
    super.initState();
    vehicleController.getAllVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        child: Obx(() {
          // Touch every field the enable rule reads so this Obx rebuilds when
          // they change (was `setState(() {})`).
          logic.state.formRevision.value;
          final bool isLoading =
              logic.state.status.value == RegisterStatus.loading;
          final bool enabled = RegisterPage.canSubmit(
            logic.nameController.text,
            logic.plateController.text,
          );

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.s8,
                  Insets.s8,
                  Insets.s8,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TIconButton(
                    icon: DsIcons.back,
                    filled: false,
                    semanticLabel:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.screen,
                    Insets.s8,
                    Insets.screen,
                    Insets.s24,
                  ),
                  child: _form(context, c, isLoading),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.screen,
                  Insets.s8,
                  Insets.screen,
                  Insets.s16,
                ),
                child: TButton(
                  label: 'REGISTER_SUBMIT'.tr(),
                  loading: isLoading,
                  onPressed: enabled
                      ? () {
                          FocusScope.of(context).unfocus();
                          tlog(
                              "Register Driver ${logic.nameController.text}, Vehical ID: ${logic.state.vehicalId.value}, Plate Number ${logic.plateController.text}");
                          logic.submit();
                        }
                      : null,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _form(BuildContext context, TaarraaColors c, bool isLoading) {
    final state = logic.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'REGISTER_TITLE'.tr(),
          style: context.texts.headline.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: Insets.s8),
        Text(
          'REGISTER_DESC'.tr(),
          style: context.texts.bodySecondary.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: Insets.s24),
        TTextField(
          label: 'FULL_NAME'.tr(),
          controller: logic.nameController,
          hint: 'FULL_NAME_HINT'.tr(),
          keyboardType: TextInputType.name,
          enabled: !isLoading,
          onChanged: (_) => logic.markFormChanged(),
        ),
        const SizedBox(height: Insets.s16),
        _label(context, c, 'VEHICLE_TYPE'.tr()),
        const SizedBox(height: Insets.s8),
        _vehicleField(context, c),
        const SizedBox(height: Insets.s16),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget color = TTextField(
              label: 'VEHICLE_COLOR'.tr(),
              controller: logic.vehicleColorController,
              hint: 'VEHICLE_COLOR_HINT'.tr(),
              keyboardType: TextInputType.text,
              enabled: !isLoading,
              onChanged: (_) => logic.markFormChanged(),
            );
            final Widget plate = TTextField(
              label: 'PLATE_NUMBER'.tr(),
              controller: logic.plateController,
              hint: 'xxx-xxxx',
              keyboardType: TextInputType.text,
              enabled: !isLoading,
              onChanged: (_) => logic.markFormChanged(),
            );
            // Two columns where there is room; stacked on narrow screens so
            // the bilingual labels are not crushed.
            if (constraints.maxWidth < 340) {
              return Column(
                children: <Widget>[
                  color,
                  const SizedBox(height: Insets.s16),
                  plate,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: color),
                const SizedBox(width: 10),
                Expanded(child: plate),
              ],
            );
          },
        ),
        const SizedBox(height: Insets.s24),
        _label(context, c, 'DOCUMENTS'.tr()),
        const SizedBox(height: Insets.s8),
        PhotoSlotGrid(
          slots: <PhotoSlot>[
            _slot(
              RegisterAttachment.license,
              'DOC_DRIVER_LICENSE'.tr(),
              'assets/icon/svg/driver_license_icon.svg',
              state.imageLicense.value,
              isLoading,
            ),
            _slot(
              RegisterAttachment.cardId,
              'DOC_ID_CARD'.tr(),
              'assets/icon/svg/id_card_icon.svg',
              state.imageCardID.value,
              isLoading,
            ),
            _slot(
              RegisterAttachment.profile,
              'DOC_PROFILE_PHOTO'.tr(),
              'assets/icon/svg/profile_icon.svg',
              state.imageProfile.value,
              isLoading,
            ),
            _slot(
              RegisterAttachment.vehicle,
              'DOC_VEHICLE_PHOTO'.tr(),
              'assets/icon/svg/vehicle_icon.svg',
              state.imageVehicle.value,
              isLoading,
            ),
          ],
        ),
      ],
    );
  }

  PhotoSlot _slot(
    RegisterAttachment which,
    String title,
    String icon,
    File? image,
    bool isLoading,
  ) {
    return PhotoSlot(
      title: title,
      icon: icon,
      image: image,
      enabled: !isLoading,
      onPick: () => _showPicker(which),
      onClear: () => logic.clearAttachment(which),
    );
  }

  Widget _label(BuildContext context, TaarraaColors c, String text) => Text(
        text,
        style: context.texts.label.copyWith(color: c.textSecondary),
      );

  Widget _vehicleField(BuildContext context, TaarraaColors c) {
    return Obx(() {
      final data = vehicleController.vehicalData.value;
      switch (vehicleController.status.value) {
        case VehicleStatus.initial:
        case VehicleStatus.loading:
          return const TSkeleton(height: Sizes.input, radius: Radii.control);
        case VehicleStatus.error:
          return TCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: <Widget>[
                TIcon(DsIcons.warn, size: TIconSize.sm, color: c.danger),
                const SizedBox(width: Insets.s8),
                Expanded(
                  child: Text(
                    'FAILED_TO_LOAD_DATA'.tr(),
                    style: context.texts.bodySecondary.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
                TButton(
                  label: 'TRY_AGAIN'.tr(),
                  variant: TButtonVariant.tertiary,
                  size: TButtonSize.small,
                  expand: false,
                  onPressed: vehicleController.getAllVehicles,
                ),
              ],
            ),
          );
        case VehicleStatus.loaded:
          if (data == null) return const SizedBox.shrink();
          return SizedBox(
            width: double.infinity,
            height: Sizes.input,
            child: SearchableDropdown<SingleVehical>(
              items: data.data,
              hintText: 'VEHICLE_TYPE_HINT'.tr(),
              itemToString: (value) => value.name.toString(),
              onChanged: (value) => logic.selectVehicle(value.item?.id),
            ),
          );
      }
    });
  }

  void _showPicker(RegisterAttachment which) {
    showTSheet<void>(
      context: context,
      child: Builder(
        builder: (BuildContext sheetContext) => Row(
          children: <Widget>[
            Expanded(
              child: _PickerOption(
                icon: DsIcons.doc,
                label: 'PHOTO_GALLERY'.tr(),
                onTap: () {
                  Navigator.pop(sheetContext);
                  logic.pickFromGallery(which);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerOption(
                icon: DsIcons.camera,
                label: 'PHOTO_CAMERA'.tr(),
                onTap: () {
                  Navigator.pop(sheetContext);
                  logic.pickFromCamera(which);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The four document slots, two per row.
class PhotoSlotGrid extends StatelessWidget {
  const PhotoSlotGrid({super.key, required this.slots});

  final List<PhotoSlot> slots;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int row = 0; row < slots.length; row += 2) ...<Widget>[
          if (row > 0) const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(child: slots[row]),
              const SizedBox(width: 10),
              Expanded(
                child: row + 1 < slots.length
                    ? slots[row + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    return TCard(
      variant: TCardVariant.raised,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: <Widget>[
          TIcon(icon, size: TIconSize.lg, color: c.brandText),
          const SizedBox(height: Insets.s8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.texts.label.copyWith(color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}
