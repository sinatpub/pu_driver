import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C3 — who you are collecting, and how to reach them.
///
/// No rating: the ride-request payload carries none (`DD-15`). The prototype
/// shows one, which would have to be invented.
///
/// The call button stays enabled while a trip action is in flight — calling
/// the passenger touches no trip state, and it is exactly the moment a driver
/// is most likely to need it.
///
/// C6: the payment receipt reuses this row without a phone line or call
/// button, passing a trailing widget (the payment-method badge) instead.
class PassengerRow extends StatelessWidget {
  const PassengerRow({
    super.key,
    required this.name,
    this.phone,
    this.phoneLabel,
    this.callSemanticLabel,
    this.imageUrl,
    this.onCall,
    this.trailing,
  });

  final String name;
  final String? phone;

  /// The phone line as the screen already renders it, e.g. "Phone Number 012…".
  /// Null hides the line entirely (the payment receipt shows no phone).
  final String? phoneLabel;

  final String? callSemanticLabel;
  final String? imageUrl;

  /// Overrides the call button when set — the receipt's payment-method badge.
  final Widget? trailing;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Container(
      padding: const EdgeInsets.all(Insets.s12),
      decoration: BoxDecoration(
        color: c.bgPage,
        borderRadius: Radii.controlRadius,
        border: Border.all(color: c.borderDivider),
      ),
      child: Row(
        children: <Widget>[
          TAvatar(name: name, imageUrl: imageUrl),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  style: context.texts.bodyStrong.copyWith(
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phoneLabel != null && phoneLabel!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    phoneLabel!,
                    style: context.texts.caption.copyWith(
                      color: c.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Insets.s8),
          if (onCall != null)
            TIconButton(
              icon: DsIcons.phone,
              tone: TIconButtonTone.success,
              semanticLabel: callSemanticLabel ?? '',
              onPressed: onCall,
            )
          else if (trailing != null)
            trailing!,
        ],
      ),
    );
  }
}
