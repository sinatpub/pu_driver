import 'package:easy_localization/easy_localization.dart' as easy_locale;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pinput/pinput.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';

import 'logic.dart';

/// Was `otp_page.dart`. Route arguments ([OtpPageArgs]) are unpacked by
/// [OtpBinding] now, so the widget carries none.
class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<OtpLogic>();
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: ThemeConstands.font22SemiBold,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dark1, width: 2),
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.light4,
      body: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          child: Obx(() {
            return Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      child: Container(
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
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 17),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 28,
                              ),
                              Text(
                                "OTP_VERIFICATION".tr(),
                                style: ThemeConstands.font20SemiBold,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: 18,
                              ),
                              Text(
                                "OTP_VERIFICATION_DES".tr(),
                                style: ThemeConstands.font16Regular,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(
                                height: 48,
                              ),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Pinput(
                                  length: 4,
                                  autofocus: true,
                                  //smsRetriever: smsRetriever,
                                  controller: logic.pinController,
                                  focusNode: logic.focusNode,
                                  defaultPinTheme: defaultPinTheme,
                                  separatorBuilder: (index) =>
                                      const SizedBox(width: 8),
                                  hapticFeedbackType:
                                      HapticFeedbackType.lightImpact,
                                  onChanged: (value) {
                                    debugPrint("---> value ---> $value");
                                  },
                                  onCompleted: (value) async {
                                    logic.verify(
                                      phone: logic.phoneNumber.toString(),
                                      otpCode: value.toString(),
                                    );
                                  },
                                  focusedPinTheme: defaultPinTheme.copyWith(
                                    decoration:
                                        defaultPinTheme.decoration!.copyWith(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.main, width: 2),
                                    ),
                                  ),
                                  submittedPinTheme: defaultPinTheme.copyWith(
                                    decoration:
                                        defaultPinTheme.decoration!.copyWith(
                                      color: AppColors.light4,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.dark4, width: 2),
                                    ),
                                  ),
                                  errorPinTheme: defaultPinTheme.copyBorderWith(
                                    border: Border.all(
                                        color: Colors.redAccent, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 28,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "UNRECEIVED_OTP".tr(),
                                    style: ThemeConstands.font16Regular,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(width: 8), // Add some space
                                  Text(
                                    "${logic.state.secondsRemaining.value}s",
                                    style:
                                        ThemeConstands.font16Regular.copyWith(
                                      color: AppColors.dark1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16), // Add some space
                              TextButton(
                                onPressed: logic.state.isResendEnabled.value
                                    ? logic.onResend
                                    : null,
                                child: Text(
                                  "RESEND_CODE".tr(),
                                  style: ThemeConstands.font16SemiBold.copyWith(
                                      decoration: TextDecoration.underline,
                                      color: logic.state.isResendEnabled.value
                                          ? AppColors.dark1
                                          : AppColors.dark4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
