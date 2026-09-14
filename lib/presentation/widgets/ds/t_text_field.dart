import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds_icons.dart';
import 'package:tara_driver_application/presentation/widgets/shake_widget.dart';

/// UX-redesign F2 — labelled text input (`02 §8`).
///
/// **Owns no validation.** Formatters, error text and the shake trigger all
/// come from the caller, so a screen's existing rules move across untouched —
/// the driver phone check (`<10` characters of the *formatted* text) is a
/// documented quirk that must survive the redesign.
class TTextField extends StatelessWidget {
  const TTextField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.prefix,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.focusNode,
    this.shakeKey,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  /// The `+855` phone field used by login and registration.
  const factory TTextField.phone({
    Key? key,
    String? label,
    TextEditingController? controller,
    String? hint,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
    bool enabled,
    FocusNode? focusNode,
    GlobalKey<ShakeWidgetState>? shakeKey,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputAction? textInputAction,
  }) = _TPhoneField;

  final String? label;
  final TextEditingController? controller;
  final String? hint;

  /// Non-null puts the field in its error state and shows the message.
  final String? errorText;

  /// Leading content inside the field, separated by a divider (see
  /// [TTextField.phone]).
  final Widget? prefix;

  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool autofocus;
  final int? maxLength;
  final FocusNode? focusNode;

  /// Lets the caller shake the field on a failed validation, the way login
  /// does today. The caller holds the key and calls `currentState?.shake()`.
  final GlobalKey<ShakeWidgetState>? shakeKey;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// The keyboard's action key (login uses `send`).
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    final Widget field = Container(
      constraints: const BoxConstraints(minHeight: Sizes.input),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? c.bgSurface : c.bgSunken,
        borderRadius: Radii.controlRadius,
        border: Border.all(
          color: hasError ? c.danger : c.borderControl,
          width: 1.5,
        ),
      ),
      child: Row(
        children: <Widget>[
          if (prefix != null) ...<Widget>[
            prefix!,
            const SizedBox(width: 10),
            Container(width: 1, height: 24, color: c.borderDivider),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: autofocus,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              cursorColor: c.borderFocus,
              style: context.texts.body.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                // P3: the input fills the 56 px field. With zero padding the
                // tappable text box was 22 px tall — taps on the rest of the
                // field did nothing, and it failed the 48 px target rule.
                constraints: const BoxConstraints(minHeight: Sizes.input),
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintText: hint,
                hintStyle: context.texts.body.copyWith(color: c.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: context.texts.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Insets.s8),
        ],
        if (shakeKey != null)
          ShakeWidget(key: shakeKey, shakeOffset: 10, child: field)
        else
          field,
        if (hasError) ...<Widget>[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TIcon(DsIcons.warn, size: TIconSize.sm, color: c.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorText!,
                  style: context.texts.label.copyWith(
                    color: c.danger,
                    fontWeight: FontWeights.regular,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TPhoneField extends TTextField {
  const _TPhoneField({
    super.key,
    super.label,
    super.controller,
    super.hint,
    super.errorText,
    super.inputFormatters,
    super.enabled = true,
    super.focusNode,
    super.shakeKey,
    super.onChanged,
    super.onSubmitted,
    super.textInputAction,
  }) : super(
          keyboardType: TextInputType.phone,
          prefix: const _PhonePrefix(),
        );
}

class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix();

  @override
  Widget build(BuildContext context) {
    return Text(
      '+855',
      style:
          context.texts.bodyStrong.copyWith(color: context.colors.textPrimary),
    );
  }
}
