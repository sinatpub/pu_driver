import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pinput/pinput.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'state.dart';

/// Was `otp_page.dart`. Route arguments ([OtpPageArgs]) are unpacked by
/// [OtpBinding] now, so the widget carries none.
///
/// UX-redesign S4 (`03 S03`, `DD-24`): back, headline, "Enter the 4-digit code
/// sent to" + the number, the [OtpInput] boxes, and a countdown pill that
/// turns into "Resend code" at zero. While verifying, the boxes are disabled
/// and a small spinner sits under them.
///
/// Behaviour is the controller's and is unchanged: auto-submit on the 4th
/// digit (`onCompleted` → `verify`), the countdown source and the resend
/// callback, the debug bypass, and the new-driver → register branch. No
/// Register link (`DD-24`).
class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<OtpLogic>();
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        child: Obx(() {
          final bool verifying = logic.state.status.value == OtpStatus.loading;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Insets.s8,
              Insets.s8,
              Insets.s8,
              Insets.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TIconButton(
                    icon: DsIcons.back,
                    filled: false,
                    semanticLabel:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: Insets.s16),
                      Text(
                        'OTP_VERIFICATION'.tr(),
                        style: context.texts.headline.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: Insets.s8),
                      OtpSentTo(phoneNumber: logic.phoneNumber),
                      const SizedBox(height: Insets.s24),
                      OtpInput(
                        controller: logic.pinController,
                        focusNode: logic.focusNode,
                        enabled: !verifying,
                        onCompleted: (String value) {
                          logic.verify(
                            phone: logic.phoneNumber.toString(),
                            otpCode: value.toString(),
                          );
                        },
                      ),
                      SizedBox(
                        height: 40,
                        child: verifying
                            ? Center(
                                child: SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.brandText,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      OtpResendRow(
                        secondsRemaining: logic.state.secondsRemaining.value,
                        canResend: logic.state.isResendEnabled.value,
                        onResend: logic.onResend,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// "Enter the 4-digit code sent to" + the number in bold.
class OtpSentTo extends StatelessWidget {
  const OtpSentTo({super.key, required this.phoneNumber});

  /// Digits only, as sent to `verify-phone-otp`. Null omits the number.
  final String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool hasNumber = phoneNumber != null && phoneNumber!.isNotEmpty;
    return Text.rich(
      TextSpan(
        style: context.texts.bodySecondary.copyWith(color: c.textSecondary),
        children: <InlineSpan>[
          TextSpan(text: 'OTP_SENT_TO'.tr()),
          if (hasNumber) ...<InlineSpan>[
            const TextSpan(text: '\n'),
            TextSpan(
              text: '+855 $phoneNumber',
              style: context.texts.bodyStrong.copyWith(color: c.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

/// The four code boxes — a `Pinput` themed per `02 §8`: 64 high, 26/700,
/// `r.control`; focus is `border.focus` with a 3 px `brand.tint` halo.
class OtpInput extends StatelessWidget {
  const OtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onCompleted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onCompleted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 12;
        final double box = ((constraints.maxWidth - gap * 3) / 4).clamp(
          48,
          80,
        );
        final PinTheme base = PinTheme(
          width: box,
          height: 64,
          textStyle: context.texts.headline.copyWith(
            fontSize: 26,
            fontWeight: FontWeights.bold,
            color: c.textPrimary,
          ),
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: Radii.controlRadius,
            border: Border.all(color: c.borderControl, width: 1.5),
          ),
        );

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            length: 4,
            autofocus: true,
            enabled: enabled,
            controller: controller,
            focusNode: focusNode,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            separatorBuilder: (_) => const SizedBox(width: gap),
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            onCompleted: onCompleted,
            defaultPinTheme: base,
            focusedPinTheme: base.copyWith(
              decoration: base.decoration!.copyWith(
                border: Border.all(color: c.borderFocus, width: 1.5),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: c.brandTint, spreadRadius: 3),
                ],
              ),
            ),
            submittedPinTheme: base,
            disabledPinTheme: base.copyWith(
              decoration: base.decoration!.copyWith(color: c.bgSunken),
            ),
          ),
        );
      },
    );
  }
}

/// "Didn't receive the code?" + a countdown pill, which becomes the
/// "Resend code" action when the controller enables it.
class OtpResendRow extends StatelessWidget {
  const OtpResendRow({
    super.key,
    required this.secondsRemaining,
    required this.canResend,
    required this.onResend,
  });

  final int secondsRemaining;
  final bool canResend;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Insets.s8,
      runSpacing: Insets.s4,
      children: <Widget>[
        Text(
          'UNRECEIVED_OTP'.tr(),
          style: context.texts.bodySecondary.copyWith(color: c.textSecondary),
        ),
        if (canResend)
          TButton(
            label: 'RESEND_CODE'.tr(),
            variant: TButtonVariant.tertiary,
            size: TButtonSize.small,
            expand: false,
            onPressed: onResend,
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: c.brandTint,
              borderRadius: BorderRadius.circular(Radii.full),
            ),
            child: Text(
              '${secondsRemaining}s',
              style: context.texts.label.copyWith(
                color: c.brandText,
                fontWeight: FontWeights.bold,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
