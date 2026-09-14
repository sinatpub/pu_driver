import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/t_states.dart';

/// Loading skeleton for the drawer profile.
///
/// UX-redesign F3 moved these onto [TSkeleton] and the design tokens. S5
/// removed the wallet, history and announcement variants once those screens
/// grew skeletons shaped like their own cards (`WalletSkeleton`,
/// `HistoryCardSkeleton`, `NewsCardSkeleton`).

/// Drawer header while the profile loads.
class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Insets.s16,
        vertical: Insets.s12,
      ),
      child: Row(
        children: <Widget>[
          const TSkeleton.box(width: 80, height: 80, radius: Radii.md),
          const SizedBox(width: Insets.s16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const TSkeleton.line(width: 150),
                const SizedBox(height: Insets.s12),
                const TSkeleton.line(width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
