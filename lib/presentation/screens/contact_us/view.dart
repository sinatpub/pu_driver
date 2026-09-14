import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'package:easy_localization/easy_localization.dart';

/// Rendered as a tab body inside `DrawerScreen`, not as its own route — its
/// binding is attached to [AppRoutes.home] (`14` §3.5), mirroring how the
/// passenger app binds its `bottom_nav` tabs.
///
/// UX-redesign S3 (`03 S15`): the existing logo in a badge, the blurb, a
/// [ContactRow] for each phone and the email, a non-tappable address row, and
/// the copyright. Scrolls, so long Khmer or a short screen cannot overflow.
/// The data (`ContactUsState`) and the launch calls are unchanged.
class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ContactUsLogic logic = Get.find<ContactUsLogic>();
    final state = logic.state;
    final TaarraaColors c = context.colors;

    return ColoredBox(
      color: c.bgPage,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.tabContent,
          Insets.s24,
          Insets.tabContent,
          Insets.s24,
        ),
        children: <Widget>[
          Center(
            child: Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(Insets.s12),
              decoration: BoxDecoration(
                color: c.bgSurface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: c.borderDivider),
              ),
              child: const Image(
                image: AssetImage('assets/image/png/company_logo.png'),
              ),
            ),
          ),
          const SizedBox(height: Insets.s16),
          Text(
            'CONTACT_BLURB'.tr(),
            textAlign: TextAlign.center,
            style: context.texts.bodySecondary.copyWith(
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: Insets.s24),
          ContactRow(
            icon: DsIcons.phone,
            label: 'Smart: ${state.smartPhone}',
            onTap: () => logic.callPhone(state.smartPhone.replaceAll(' ', '')),
          ),
          const SizedBox(height: Insets.s8),
          ContactRow(
            icon: DsIcons.phone,
            label: 'Cellcard: ${state.cellcardPhone}',
            onTap: () =>
                logic.callPhone(state.cellcardPhone.replaceAll(' ', '')),
          ),
          const SizedBox(height: Insets.s8),
          ContactRow(
            icon: DsIcons.mail,
            label: state.email,
            onTap: () => logic.sendEmail(state.email),
          ),
          const SizedBox(height: Insets.s8),
          ContactRow(icon: DsIcons.home, label: state.address),
          const SizedBox(height: Insets.s32),
          Text(
            'COPYRIGHT'.tr(),
            textAlign: TextAlign.center,
            style: context.texts.caption.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// A contact line (`.prow` HTML:250-252). With [onTap] it is a button with a
/// chevron; without, it is plain information (the address).
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Semantics(
      button: onTap != null,
      child: TCard(
        padding: const EdgeInsets.all(15),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: Row(
            children: <Widget>[
              TIcon(icon, color: c.brandText),
              const SizedBox(width: Insets.s12),
              Expanded(
                child: Text(
                  label,
                  style: context.texts.bodyStrong.copyWith(
                    fontSize: 15,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(width: Insets.s8),
                TIcon(
                  DsIcons.chevron,
                  size: TIconSize.sm,
                  color: c.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
