import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// Error dialog for trip actions, auth and payment.
///
/// UX-redesign F3 restyled the body only. **The dismissal behaviour is
/// carried over exactly, including its oddity** (`DD-33`):
///
/// - `comfirmBook == true` → the button pops **twice**: the dialog, and the
///   route underneath it. On the trip screen that means a failed accept,
///   arrive, start or complete ejects the driver from `/booking`.
/// - `comfirmBook == false` → a single pop, and the label reads "Try Again"
///   (`TRY_AGAIN`, added at C6 — it had been a hardcoded English string).
/// - The barrier is dismissible either way, so tapping outside only ever
///   closes the dialog — a second, quieter path with a different outcome.
///
/// That asymmetry is a real defect (logged as B1 in
/// `docs/ux-redesign/06-implementation-plan.md §4`), but fixing it is a
/// behaviour change and belongs in its own change with its own tests. A
/// restyle must not smuggle it in.
Future<void> showErrorCustomDialog(
    BuildContext context, String title, String description, bool comfirmBook) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return TDialog(
        icon: DsIcons.warn,
        iconColor: context.colors.danger,
        title: title,
        message: description,
        actions: <Widget>[
          TButton(
            label: comfirmBook == true ? 'OK'.tr() : 'TRY_AGAIN'.tr(),
            size: TButtonSize.small,
            onPressed: () {
              if (comfirmBook == true) {
                Navigator.of(context).pop();
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
