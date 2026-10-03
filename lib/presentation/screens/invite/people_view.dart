import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pu_taxi_driver/core/theme/tokens.dart';
import 'package:pu_taxi_driver/presentation/screens/history/widgets/history_days.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/data/models/referral_model.dart';
import 'package:pu_taxi_driver/presentation/screens/invite/invite_presentation.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/wallet_presentation.dart';
import 'package:pu_taxi_driver/presentation/widgets/ds/ds.dart';

import 'widgets/invite_widgets.dart';

/// The "People" tab of the invite rewards screen (DD-45, DD-46): everyone
/// who signed up with the driver's code, newest first, with what each has
/// earned the driver so far. A filter by kind of person, then the list.
class PeopleBody extends StatelessWidget {
  const PeopleBody({
    super.key,
    required this.currency,
    required this.all,
    required this.visible,
    required this.filter,
    required this.onFilter,
  });

  final String? currency;
  final List<Invitee> all;

  /// [all] after [filter], newest first.
  final List<Invitee> visible;
  final InviteeRole? filter;
  final ValueChanged<InviteeRole?> onFilter;

  int _count(InviteeRole role) =>
      all.where((Invitee i) => InviteeRole.of(i.role) == role).length;

  String _caption(Invitee invitee, DateTime now, String locale) {
    final String? role = switch (InviteeRole.of(invitee.role)) {
      InviteeRole.driver => 'INVITE_ROLE_DRIVER'.tr(),
      InviteeRole.passenger => 'INVITE_ROLE_PASSENGER'.tr(),
      InviteeRole.unknown => null,
    };
    final DateTime? joined = parseHistoryTime(invitee.joinedAt);
    return <String>[
      if (role != null) role,
      if (joined != null)
        'INVITE_JOINED'.tr(
          args: <String>[inviteShortDate(joined, now: now, locale: locale)],
        ),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return TEmptyState(
        icon: DsIcons.users,
        title: 'INVITE_NO_PEOPLE'.tr(),
        message: 'INVITE_NO_PEOPLE_HINT'.tr(),
      );
    }

    final DateTime now = DateTime.now();
    final String locale = context.locale.toString();

    Widget chip(String label, InviteeRole? value) => Padding(
          padding: const EdgeInsets.only(right: Insets.s8),
          child: TChip(
            label: label,
            selected: filter == value,
            onTap: () => onFilter(value),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              chip('${'ALL'.tr()} · ${all.length}', null),
              chip(
                '${'INVITE_DRIVERS'.tr()} · ${_count(InviteeRole.driver)}',
                InviteeRole.driver,
              ),
              chip(
                '${'INVITE_PASSENGERS'.tr()} · ${_count(InviteeRole.passenger)}',
                InviteeRole.passenger,
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.s4),
        if (visible.isEmpty)
          TEmptyState(icon: DsIcons.users, title: 'INVITE_NO_PEOPLE'.tr())
        else
          for (final Invitee invitee in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.s8),
              child: InviteeTile(
                name: invitee.name ?? '',
                imageUrl: invitee.image,
                caption: _caption(invitee, now, locale),
                hasEarned: (invitee.earned ?? 0) > 0,
                earned: (invitee.earned ?? 0) > 0
                    ? formatSignedWalletMoney(
                        invitee.earned,
                        currency,
                        WalletTxDirection.moneyIn,
                      )
                    : 'INVITE_NO_REWARDS'.tr(),
              ),
            ),
      ],
    );
  }
}
