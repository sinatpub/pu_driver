import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// "Resuming your trip" — shown by `HomeLogic` when the driver reopens the app
/// with a ride already in flight, immediately before it navigates to
/// `/booking` two seconds later (`DD-32`).
///
/// UX-redesign F3 restyled the body only:
///
/// - The navigation is **not** here. `HomeLogic` owns the 2 s timer, and this
///   dialog neither knows nor cares when it fires.
/// - `barrierDismissible: true` is unchanged. The driver can tap it away; the
///   navigation still happens, exactly as before.
/// - [onYes] is accepted and ignored, as it always has been — call sites pass
///   it, so the signature stays.
///
/// The old body was a red button containing a spinner, which invited a tap
/// that did nothing (`onPressed: () {}`). It is now a spinner and a title: a
/// progress dialog that does not pretend to be actionable.
Future<void> showPocessBookingLoadingDialog({
  required Function() onYes,
  required BuildContext context,
  required String title,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return TDialog(
        title: title,
        top: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colors.actionPrimary,
              ),
            ),
          ),
        ),
      );
    },
  );
}
