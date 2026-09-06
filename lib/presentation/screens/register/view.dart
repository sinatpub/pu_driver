import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/core/utils/pretty_logger.dart';
import 'package:tara_driver_application/data/models/vehical_model.dart';
import 'package:tara_driver_application/presentation/widgets/card_atta_widget.dart';
import 'package:tara_driver_application/presentation/widgets/fbtn_widget.dart';
import 'package:tara_driver_application/presentation/widgets/loading_widget.dart';
import 'package:tara_driver_application/presentation/widgets/x_button.dart';
import 'package:tara_driver_application/presentation/widgets/x_dropdown_search.dart';
import 'package:tara_driver_application/presentation/widgets/x_showmodal_bottom.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/presentation/controllers/vehicle_controller.dart';

import 'logic.dart';
import 'state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
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
    return Scaffold(
      backgroundColor: AppColors.light4,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          // Touch every field the enabled/border logic reads so this Obx
          // rebuilds when they change (was `setState(() {})`).
          logic.state.formRevision.value;
          bool isLoading = logic.state.status.value == RegisterStatus.loading;
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                            alignment: Alignment.centerLeft,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 24,
                            )),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 18,
                              ),
                              const Text(
                                "Fill Information",
                                style: ThemeConstands.font20SemiBold,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              const Text(
                                "Please fill out the information below to register for a new account.",
                                style: ThemeConstands.font16Regular,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: 28,
                              ),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Text(
                                          "Full Name - ",
                                          style: ThemeConstands.font16SemiBold,
                                          textAlign: TextAlign.left,
                                        ),
                                        Text(
                                          "ឈ្មោះពេញ",
                                          style: ThemeConstands.font16SemiBold,
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    SizedBox(
                                      height: 54,
                                      child: TextFormField(
                                        controller: logic.nameController,
                                        textAlign: TextAlign.start,
                                        keyboardType: TextInputType.name,
                                        onChanged: (value) {
                                          logic.markFormChanged();
                                        },
                                        style: ThemeConstands.font16SemiBold
                                            .copyWith(color: AppColors.main),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppColors.light3,
                                          hintText:
                                              "Enter Full Name - បញ្ចូលឈ្មោះពេញ",
                                          hintStyle: ThemeConstands
                                              .font16Regular
                                              .copyWith(color: AppColors.dark3),
                                          border:
                                              logic.nameController.text != ""
                                                  ? focusColor
                                                  : border,
                                          enabledBorder:
                                              logic.nameController.text != ""
                                                  ? focusColor
                                                  : enableBorder,
                                          focusedBorder: focusColor,
                                          errorBorder: errorColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 22,
                                    ),
                                    const Row(
                                      children: [
                                        Text(
                                          "Vehicle Type - ",
                                          style: ThemeConstands.font16SemiBold,
                                          textAlign: TextAlign.left,
                                        ),
                                        Text(
                                          "ប្រភេទយានយន្ដ",
                                          style: ThemeConstands.font16SemiBold,
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Obx(() {
                                      final data =
                                          vehicleController.vehicalData.value;
                                      if (vehicleController.status.value ==
                                              VehicleStatus.loaded &&
                                          data != null) {
                                        return SizedBox(
                                          width: double.infinity,
                                          height: 58,
                                          child:
                                              SearchableDropdown<SingleVehical>(
                                            items: data.data,
                                            hintText:
                                                "Select Service type - ជ្រើសរើសប្រភេទយានយន្ដ",
                                            itemToString: (value) =>
                                                value.name.toString(),
                                            onChanged: (value) => logic
                                                .selectVehicle(value.item?.id),
                                          ),
                                        );
                                      }
                                      return Container();
                                    }),
                                    const SizedBox(
                                      height: 22,
                                    ),
                                    const Row(
                                      children: [
                                        Text(
                                          "Vehicle Color - ",
                                          style: ThemeConstands.font16SemiBold,
                                          textAlign: TextAlign.left,
                                        ),
                                        Text(
                                          "ពណ៌យានយន្ដ",
                                          style: ThemeConstands.font16SemiBold,
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    SizedBox(
                                        width: double.infinity,
                                        height: 58,
                                        child: TextFormField(
                                          controller:
                                              logic.vehicleColorController,
                                          textAlign: TextAlign.start,
                                          keyboardType: TextInputType.text,
                                          onChanged: (value) {
                                            logic.markFormChanged();
                                          },
                                          style: ThemeConstands.font16SemiBold
                                              .copyWith(color: AppColors.main),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: AppColors.light3,
                                            hintText:
                                                'Enter your vehicle color',
                                            hintStyle: ThemeConstands
                                                .font16Regular
                                                .copyWith(
                                                    color: AppColors.dark3),
                                            border: logic.vehicleColorController
                                                        .text !=
                                                    ""
                                                ? focusColor
                                                : border,
                                            enabledBorder: logic
                                                        .vehicleColorController
                                                        .text !=
                                                    ""
                                                ? focusColor
                                                : enableBorder,
                                            focusedBorder: focusColor,
                                            errorBorder: errorColor,
                                          ),
                                        )),
                                    const SizedBox(
                                      height: 22,
                                    ),
                                    const Text(
                                      "Plate Number - ផ្លាកលេខ",
                                      style: ThemeConstands.font16SemiBold,
                                      textAlign: TextAlign.left,
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    SizedBox(
                                      height: 58,
                                      child: TextFormField(
                                        controller: logic.plateController,
                                        textAlign: TextAlign.start,
                                        keyboardType: TextInputType.text,
                                        onChanged: (value) {
                                          logic.markFormChanged();
                                        },
                                        style: ThemeConstands.font16SemiBold
                                            .copyWith(color: AppColors.main),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppColors.light3,
                                          hintText: 'xxx-xxxx',
                                          hintStyle: ThemeConstands
                                              .font16Regular
                                              .copyWith(color: AppColors.dark3),
                                          border:
                                              logic.plateController.text != ""
                                                  ? focusColor
                                                  : border,
                                          enabledBorder:
                                              logic.plateController.text != ""
                                                  ? focusColor
                                                  : enableBorder,
                                          focusedBorder: focusColor,
                                          errorBorder: errorColor,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 22,
                                    ),
                                    const Text(
                                      "Upload Attachment - ឯកសារភ្ជាប់",
                                      style: ThemeConstands.font16SemiBold,
                                      textAlign: TextAlign.left,
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    // Driver License & ID Card
                                    SizedBox(
                                      height: 120,
                                      width: double.infinity,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              CardUploadAttachment(
                                                onPressedIcon: () {
                                                  logic.clearAttachment(
                                                      RegisterAttachment
                                                          .license);
                                                },
                                                title: "Driver License",
                                                titleKh: "ប័ណ្ណបើកបរ",
                                                image: logic
                                                    .state.imageLicense.value,
                                                icon:
                                                    'assets/icon/svg/driver_license_icon.svg',
                                                onPressed: () {
                                                  showModal(RegisterAttachment
                                                      .license);
                                                },
                                              ),
                                              CardUploadAttachment(
                                                onPressedIcon: () {
                                                  logic.clearAttachment(
                                                      RegisterAttachment
                                                          .cardId);
                                                },
                                                title: "ID Card",
                                                titleKh: "អត្តសញ្ញាណប័ណ្ណ",
                                                image: logic
                                                    .state.imageCardID.value,
                                                icon:
                                                    'assets/icon/svg/id_card_icon.svg',
                                                onPressed: () {
                                                  showModal(RegisterAttachment
                                                      .cardId);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Profile & Vehicle Image
                                    const SizedBox(
                                      height: 18,
                                    ),
                                    SizedBox(
                                      height: 120,
                                      width: double.infinity,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              CardUploadAttachment(
                                                onPressedIcon: () {
                                                  logic.clearAttachment(
                                                      RegisterAttachment
                                                          .profile);
                                                },
                                                title: "Profile Image",
                                                titleKh: "រូបភាពអ្នក",
                                                image: logic
                                                    .state.imageProfile.value,
                                                icon:
                                                    "assets/icon/svg/profile_icon.svg",
                                                onPressed: () {
                                                  showModal(RegisterAttachment
                                                      .profile);
                                                },
                                              ),
                                              CardUploadAttachment(
                                                onPressedIcon: () {
                                                  logic.clearAttachment(
                                                      RegisterAttachment
                                                          .vehicle);
                                                },
                                                title: "Vehicle Image",
                                                titleKh: "រូបភាពរថយន្ត",
                                                image: logic
                                                    .state.imageVehicle.value,
                                                icon:
                                                    "assets/icon/svg/vehicle_icon.svg",
                                                onPressed: () {
                                                  showModal(RegisterAttachment
                                                      .vehicle);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 28,
                                    ),
                                    FBTNWidget(
                                      onPressed: logic.nameController.text ==
                                                  "" &&
                                              logic.plateController.text == ""
                                          ? null
                                          : () {
                                              FocusScope.of(context).unfocus();
                                              tlog(
                                                  "Register Driver ${logic.nameController.text}, Vehical ID: ${logic.state.vehicalId.value}, Plate Number ${logic.plateController.text}");
                                              logic.submit();
                                            },
                                      textColor: AppColors.light4,
                                      label: "Create - បង្កើត",
                                      enableWidth: true,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                const Positioned(
                  child: LoadingWidget(),
                )
            ],
          );
        }),
      ),
    );
  }

  void showModal(RegisterAttachment which) async {
    xShowModalBottomSheet(
      initialChildSize: 0.2,
      maxChildSize: 1.0,
      minChildSize: 0.1,
      context: context,
      body: (context, scrollController) {
        return SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              XButton(
                onPress: () {
                  Navigator.pop(context);
                  logic.pickFromGallery(which);
                },
                child: Container(
                  width: 180,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.light2,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        "Gallery\nកន្លែងផ្ទុករូបថត",
                        textAlign: TextAlign.center,
                        style: ThemeConstands.font16SemiBold,
                      ),
                    ],
                  ),
                ),
              ),
              XButton(
                onPress: () {
                  Navigator.pop(context);
                  logic.pickFromCamera(which);
                },
                child: Container(
                  width: 180,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.light2,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        "Take a Photo\nថតរូប",
                        textAlign: TextAlign.center,
                        style: ThemeConstands.font16SemiBold,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.dark1));
  final enableBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.dark1));
  final focusColor = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.main),
  );
  final errorColor = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.red),
  );

  final List<String> itemsColor = [
    'Blue - ខៀវ',
    'Black - ខ្មៅ',
    'Red - ក្រហម',
    'Green - បៃតង',
    'Yellow - លឿង',
    'Grey - ប្រផេះ',
    'Pink - ផ្កាឈូក',
  ];
}
