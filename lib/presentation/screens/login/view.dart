import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/core/utils/phone_formatter.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/presentation/widgets/language_segment.dart';

import 'logic.dart';
import 'state.dart';

/// UX-redesign S4 (`03 S02`, `DD-24`).
///
/// Language control inline at the top right, the existing headline and
/// description, a `TTextField.phone` with the inline error, and a 56 px Next
/// pinned above the keyboard. Submitting shows a spinner in the button and
/// disables the field instead of covering the screen.
///
/// **Validation is untouched** — it lives in [LoginLogic.validate]: empty
/// shakes with `CHECK_YOUR_PHONE_NUMBER_ERROR`; fewer than 10 characters *of
/// the formatted text* shakes with `CHECK_PHONE_NUMBER_DIGIT_ERROR` (the "8
/// digits" wording is a known quirk). The formatters are the same three, in
/// the same order. The keyboard action still only validates — it never
/// submitted, and still doesn't. No step dots (`DD-24`).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Resolved in build, never cached in a field: GetX owns this instance's
    // lifetime (see the note in history/view.dart).
    final LoginLogic logic = Get.find<LoginLogic>();
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        child: Obx(() {
          final bool isLoading =
              logic.state.status.value == LoginStatus.loading;
          final String? error = logic.state.isInvalidPhone.value
              ? 'CHECK_YOUR_PHONE_NUMBER_ERROR'.tr()
              : logic.state.isRequired8Digit.value
                  ? 'CHECK_PHONE_NUMBER_DIGIT_ERROR'.tr()
                  : null;

          return Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.screen,
                    Insets.s12,
                    Insets.screen,
                    Insets.s24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageSegment(),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'LOGINTITLE'.tr(),
                        style: context.texts.headline.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: Insets.s8),
                      Text(
                        'LOGINDES'.tr(),
                        style: context.texts.bodySecondary.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Insets.s32),
                      TTextField.phone(
                        label: 'MOBILENUM'.tr(),
                        controller: logic.phoneController,
                        hint: 'ENTER_YOUR_PHONE_NUMBER'.tr(),
                        errorText: error,
                        enabled: !isLoading,
                        shakeKey: logic.phoneShake,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                          CardNumberInputFormatter(),
                        ],
                        textInputAction: TextInputAction.send,
                        onSubmitted: (String value) {
                          if (!logic.validate(value)) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ],
                  ),
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
                  label: 'NEXT'.tr(),
                  loading: isLoading,
                  onPressed: () => logic.submit(logic.phoneController.text),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
