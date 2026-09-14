import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/drawer/state.dart';
import 'package:tara_driver_application/presentation/screens/profile/widgets/profile_header_widget.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/presentation/widgets/language_segment.dart';

/// UX-redesign C1 — the drawer, the driver app's only navigation menu.
///
/// Destinations are exactly the ones the app has today. The prototype's drawer
/// also offers Referral, Announcements, a sound toggle, a second online
/// toggle and Logout; each is excluded for a recorded reason (`DD-05`,
/// `DD-06`, `DD-22`) — three have no backend, one duplicates the app bar, and
/// logout is a product decision that is still open.
class DriverDrawer extends StatelessWidget {
  const DriverDrawer({
    super.key,
    required this.activeTab,
    required this.onSelect,
  });

  final DrawerTab activeTab;
  final ValueChanged<DrawerTab> onSelect;

  static const List<(DrawerTab, String, String)> _items =
      <(DrawerTab, String, String)>[
    (DrawerTab.home, DsIcons.home, 'HOME'),
    (DrawerTab.history, DsIcons.calendar, 'HISTORY'),
    (DrawerTab.wallet, DsIcons.wallet, 'WALLET'),
    (DrawerTab.termCondition, DsIcons.doc, 'TERMCONDITION'),
    (DrawerTab.contactUs, DsIcons.mail, 'CONTACTUS'),
  ];

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Drawer(
      backgroundColor: c.bgSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Insets.s16,
                vertical: Insets.s8,
              ),
              child: ProfileHeaderWidget(),
            ),
            Divider(color: c.borderDivider, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.s12,
                  vertical: Insets.s12,
                ),
                children: <Widget>[
                  for (final (DrawerTab tab, String icon, String key) in _items)
                    _DrawerRow(
                      icon: icon,
                      label: key.tr(),
                      selected: tab == activeTab,
                      onTap: () => onSelect(tab),
                    ),
                ],
              ),
            ),
            Divider(color: c.borderDivider, height: 1),
            Padding(
              padding: const EdgeInsets.all(Insets.s16),
              // P3: wraps the segment under the label when the drawer is narrow
              // or the text scale is up (it overflowed by 32 px at 1.3 on a
              // 320 px screen).
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Insets.s12,
                runSpacing: Insets.s8,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TIcon(DsIcons.globe, color: c.textSecondary),
                      const SizedBox(width: Insets.s12),
                      Flexible(
                        child: Text(
                          'CHOOSE_LANGUADE'.tr(),
                          style:
                              context.texts.body.copyWith(color: c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const LanguageSegment(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final Color content = selected ? c.brandText : c.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
            padding: const EdgeInsets.symmetric(horizontal: Insets.s12),
            decoration: BoxDecoration(
              color: selected ? c.brandTint : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: <Widget>[
                TIcon(icon, color: content),
                const SizedBox(width: Insets.s12),
                Expanded(
                  child: Text(
                    label,
                    style: context.texts.body.copyWith(
                      color: selected ? c.brandText : c.textPrimary,
                      fontWeight:
                          selected ? FontWeights.bold : FontWeights.regular,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
