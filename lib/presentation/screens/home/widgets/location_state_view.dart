import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/home/state.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

/// UX-redesign C2 — what the home tab shows when there is no location fix.
///
/// The prototype has nothing for this: its map is a drawing and its splash
/// only *prints* "Requesting location…". But a driver whose GPS is off sees
/// this screen, and before the redesign it was raw English strings — one of
/// them with no way out at all.
///
/// Pure: it takes its copy and its callback, so every state can be pumped in
/// a test.
class LocationStateView extends StatelessWidget {
  const LocationStateView({
    super.key,
    required this.status,
    required this.searchingLabel,
    required this.deniedTitle,
    required this.deniedMessage,
    required this.failedTitle,
    required this.openSettingsLabel,
    this.errorText,
    this.onOpenSettings,
  });

  final LocationLoadStatus status;
  final String searchingLabel;
  final String deniedTitle;
  final String deniedMessage;
  final String failedTitle;
  final String openSettingsLabel;

  /// The underlying failure, when there is one. Shown verbatim beneath the
  /// title — it is the only clue a support call has to work from.
  final String? errorText;

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    switch (status) {
      case LocationLoadStatus.inProgress:
        return Container(
          color: c.bgPage,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(c.actionPrimary),
                ),
              ),
              const SizedBox(height: Insets.s16),
              Text(
                searchingLabel,
                style: context.texts.bodySecondary
                    .copyWith(color: c.textSecondary),
              ),
            ],
          ),
        );

      case LocationLoadStatus.permissionDenied:
        return Container(
          color: c.bgPage,
          alignment: Alignment.center,
          // The old screen showed this text with **no action**, leaving the
          // driver to find the OS settings themselves. The failure branch
          // already had this button; it belongs here too.
          child: TEmptyState(
            icon: DsIcons.warn,
            title: deniedTitle,
            message: deniedMessage,
            actionLabel: openSettingsLabel,
            onAction: onOpenSettings,
          ),
        );

      case LocationLoadStatus.failure:
        return Container(
          color: c.bgPage,
          alignment: Alignment.center,
          child: TErrorState(
            title: failedTitle,
            message: errorText,
            actionLabel: openSettingsLabel,
            onAction: onOpenSettings,
          ),
        );

      case LocationLoadStatus.success:
        // The caller renders the map.
        return const SizedBox.shrink();
    }
  }
}
