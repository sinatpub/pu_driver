import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// Where the sign-up invite code stands.
enum InviteCodeStatus {
  /// Nothing typed, or typed and not checked yet.
  idle,
  checking,

  /// The server knows the code; the inviter's name is shown.
  valid,

  /// The server does not know the code.
  invalid,

  /// The check itself failed (no connection, server error).
  failed,
}

/// The optional invite code on the sign-up form (DD-45): type it, or scan the
/// inviter's QR with the button inside the field.
///
/// Presentational: the caller owns the text, the check and every string.
class InviteCodeField extends StatelessWidget {
  const InviteCodeField({
    super.key,
    required this.controller,
    required this.status,
    required this.label,
    required this.hint,
    required this.scanLabel,
    required this.onChanged,
    required this.onScan,
    this.note,
    this.appliedText,
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final InviteCodeStatus status;

  /// "Invite code (optional)".
  final String label;
  final String hint;

  /// "Scan invite QR" — for the screen reader.
  final String scanLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onScan;

  /// Shown while there is no result: the code can only be added now.
  final String? note;

  /// "Invited by Dara Sok" — shown when [status] is valid.
  final String? appliedText;

  /// Shown when [status] is invalid or failed.
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final bool hasError =
        status == InviteCodeStatus.invalid || status == InviteCodeStatus.failed;

    // On a card: the form's page fill is too close to the error red for the
    // message to pass contrast (4.46), and white is not (4.98). The card
    // also sets the optional code apart from the fields that are required.
    return TCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TTextField(
            label: label,
            controller: controller,
            hint: hint,
            enabled: enabled,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            maxLength: 12,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              _UpperCase(),
            ],
            errorText: hasError ? errorText : null,
            onChanged: onChanged,
            suffix: status == InviteCodeStatus.checking
                ? const SizedBox(
                    width: Sizes.touchTarget,
                    height: Sizes.touchTarget,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : TIconButton(
                    icon: DsIcons.scan,
                    semanticLabel: scanLabel,
                    filled: false,
                    onPressed: enabled ? onScan : null,
                  ),
          ),
          if (status == InviteCodeStatus.valid &&
              appliedText != null) ...<Widget>[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TIcon(DsIcons.check, size: TIconSize.sm, color: c.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    appliedText!,
                    style: context.texts.label.copyWith(color: c.success),
                  ),
                ),
              ],
            ),
          ] else if (!hasError && note != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              note!,
              style: context.texts.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
