import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/screens/home/logic.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'package:easy_localization/easy_localization.dart';

/// Rendered as a tab body inside `DrawerScreen`, not as its own route — its
/// binding is attached to [AppRoutes.home] (`14` §3.5), mirroring how the
/// passenger app binds its `bottom_nav` tabs.
///
/// UX-redesign S3 (`03 S15`) gave it the logo badge, the blurb and four
/// identical rows. DD-44 groups it by what the driver wants to do: a compact
/// brand header (the PU Taxi mark), "Call us" with a number and a call button
/// per carrier, "Other ways" with the email and the office address — which
/// now opens in maps — and the app version with the copyright. The numbers
/// read the local way ("070 427 213"); dialling is unchanged. Scrolls, so
/// long Khmer or a short screen cannot overflow.
class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  /// The version the app's update check is pinned to (`HomeLogic`).
  String get _version => defaultTargetPlatform == TargetPlatform.iOS
      ? HomeLogic.currentVersionIos
      : HomeLogic.currentVersionAndroid;

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
          Insets.s16,
          Insets.tabContent,
          Insets.s24,
        ),
        children: <Widget>[
          ContactHeader(
            title: 'SUPPORT_TITLE'.tr(),
            blurb: 'CONTACT_BLURB'.tr(),
          ),
          ContactSectionLabel('CALL_US'.tr()),
          ContactGroup(
            children: <Widget>[
              PhoneRow(
                carrier: 'Smart',
                number: formatLocalPhone(state.smartPhone),
                onCall: () =>
                    logic.callPhone(state.smartPhone.replaceAll(' ', '')),
              ),
              PhoneRow(
                carrier: 'Cellcard',
                number: formatLocalPhone(state.cellcardPhone),
                onCall: () =>
                    logic.callPhone(state.cellcardPhone.replaceAll(' ', '')),
              ),
            ],
          ),
          ContactSectionLabel('OTHER_WAYS'.tr()),
          ContactGroup(
            children: <Widget>[
              ContactInfoRow(
                icon: DsIcons.mail,
                overline: 'CONTACT_EMAIL'.tr(),
                value: state.email,
                onTap: () => logic.sendEmail(state.email),
              ),
              ContactInfoRow(
                icon: DsIcons.home,
                overline: 'CONTACT_OFFICE'.tr(),
                value: state.address,
                onTap: () => logic.openMap(state.address),
              ),
            ],
          ),
          const SizedBox(height: Insets.s24),
          Text(
            'APP_VERSION'.tr(args: <String>[_version]),
            textAlign: TextAlign.center,
            style: context.texts.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            'COPYRIGHT'.tr(args: <String>['${DateTime.now().year}']),
            textAlign: TextAlign.center,
            style: context.texts.caption.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The brand mark with who this is and one line of what it is for.
class ContactHeader extends StatelessWidget {
  const ContactHeader({super.key, required this.title, required this.blurb});

  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            // The launcher icon is 1024 px; decode it at the size shown.
            child: Image.asset(
              'assets/launcher/launcher_driver_1024.png',
              width: 56,
              height: 56,
              cacheWidth: 168,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: Insets.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style:
                      context.texts.bodyStrong.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  blurb,
                  style: context.texts.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small heading over a [ContactGroup].
class ContactSectionLabel extends StatelessWidget {
  const ContactSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Insets.s4, Insets.s20, Insets.s4, Insets.s8),
        child: Text(
          text,
          style:
              context.texts.label.copyWith(color: context.colors.textSecondary),
        ),
      ),
    );
  }
}

/// One card holding related rows, with a hairline between them.
class ContactGroup extends StatelessWidget {
  const ContactGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return TCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 14,
                endIndent: 14,
                color: c.borderDivider,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A support line: the carrier, the number as it is said locally, and the
/// same green call button the trip screen uses.
class PhoneRow extends StatelessWidget {
  const PhoneRow({
    super.key,
    required this.carrier,
    required this.number,
    required this.onCall,
  });

  /// A carrier's brand name ("Smart", "Cellcard") — not translated.
  final String carrier;

  /// Pre-formatted by `formatLocalPhone`.
  final String number;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, Insets.s4, Insets.s8, Insets.s4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  carrier,
                  style: context.texts.caption.copyWith(color: c.textSecondary),
                ),
                Text(
                  number,
                  style: context.texts.bodyStrong.copyWith(
                    color: c.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TIconButton(
            icon: DsIcons.phone,
            tone: TIconButtonTone.success,
            semanticLabel: '$carrier $number',
            onPressed: onCall,
          ),
        ],
      ),
    );
  }
}

/// A non-phone way to reach the company: what it is, the value, and a
/// chevron — the whole row is the tap target.
class ContactInfoRow extends StatelessWidget {
  const ContactInfoRow({
    super.key,
    required this.icon,
    required this.overline,
    required this.value,
    required this.onTap,
  });

  final String icon;
  final String overline;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Semantics(
      button: true,
      // Its own Material, so the ripple shows over the card's fill.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: <Widget>[
                  TIcon(icon, color: c.brandText),
                  const SizedBox(width: Insets.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          overline,
                          style: context.texts.caption
                              .copyWith(color: c.textSecondary),
                        ),
                        Text(
                          value,
                          style: context.texts.bodySecondary
                              .copyWith(color: c.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Insets.s8),
                  TIcon(DsIcons.chevron,
                      size: TIconSize.sm, color: c.textSecondary),
                ],
              ),
            ),
          ),
        ),
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
