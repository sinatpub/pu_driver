import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// Confirm-or-not dialog. Used by the driver's cancel-request flow and by
/// logout (`app/alert_widget.dart`).
///
/// UX-redesign F3 restyled the body only. Two behaviours are load-bearing and
/// unchanged:
///
/// - **`barrierDismissible: true`.**
/// - **YES does not pop.** It calls [onYes] and nothing else — the caller is
///   what tears the route down (the cancel flow emits `driverCancelDrive`,
///   calls the controller, and lets `TripCancelled` navigate home). Popping
///   here would change what the driver sees mid-cancellation.
///
/// The safe answer (NO) is the prominent button and YES is outlined, per
/// `02 §11`: on a dialog that ends a trip, the calm choice should be the easy
/// one to hit.
Future<void> showYesNoCustomDialog({
  required Function() onYes,
  required BuildContext context,
  required String title,
  required String description,
  // P2: the decline-confirm reads "Yes, cancel" / "Stay"; logout keeps YES/NO.
  String? yesLabel,
  String? noLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return TDialog(
        title: title,
        message: description,
        actions: <Widget>[
          TButton(
            label: noLabel ?? 'NO'.tr(),
            variant: TButtonVariant.primary,
            size: TButtonSize.small,
            onPressed: () => Navigator.of(context).pop(),
          ),
          TButton(
            label: yesLabel ?? 'YES'.tr(),
            variant: TButtonVariant.destructiveOutline,
            size: TButtonSize.small,
            onPressed: onYes,
          ),
        ],
      );
    },
  );
}
