import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/history/widgets/history_days.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';
import 'package:tara_driver_application/presentation/screens/invite/invite_presentation.dart';
import 'package:tara_driver_application/presentation/screens/wallet/wallet_presentation.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'people_view.dart';
import 'state.dart';
import 'widgets/invite_widgets.dart';

/// "Invite rewards" (DD-45, DD-46): one screen, two tabs.
///
/// **Rewards** — where the rewards came from (the total itself is on the
/// wallet, DD-47), the rules, and every reward by day. **People** — who joined
/// with the driver's code.
///
/// Opened from the wallet's invite card and from the QR sheet. A reward is
/// paid into the wallet balance, so it also shows in the wallet's own list as
/// a "Referral reward"; this screen adds who it came from. There is nothing
/// to withdraw or move here — the money is already in the wallet.
///
/// The tabs are pages, as on the riding history (DD-41): swipe between them,
/// or tap a tab.
class InviteRewardsPage extends StatefulWidget {
  const InviteRewardsPage({super.key});

  @override
  State<InviteRewardsPage> createState() => _InviteRewardsPageState();
}

class _InviteRewardsPageState extends State<InviteRewardsPage> {
  InviteLogic get logic => Get.find<InviteLogic>();

  final PageController _pages = PageController();
  final ValueNotifier<double> _position = ValueNotifier<double>(0);
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    logic.fetch();
    _pages.addListener(() {
      if (_pages.hasClients) _position.value = _pages.page ?? _position.value;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _position.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    if (reduceMotion(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: Motion.screen,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      appBar: TAppBar(title: 'INVITE_REWARDS'.tr()),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.tabContent,
              Insets.s12,
              Insets.tabContent,
              Insets.s4,
            ),
            child: TTabs(
              labels: <String>[
                'INVITE_TAB_REWARDS'.tr(),
                'INVITE_TAB_PEOPLE'.tr(),
              ],
              index: _tab,
              position: _position,
              onChanged: _goToTab,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (int index) => setState(() => _tab = index),
              children: <Widget>[
                _page((ReferralModel referral) => RewardsBody(
                      referral: referral,
                      rewards: logic.rewards,
                    )),
                _page((ReferralModel referral) => PeopleBody(
                      currency: referral.currency,
                      all: referral.invitees,
                      visible: logic.visibleInvitees,
                      filter: logic.state.peopleFilter.value,
                      onFilter: logic.selectPeopleFilter,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One tab's page: pull to refresh, and the shared loading / error states.
  Widget _page(Widget Function(ReferralModel referral) loaded) {
    return RefreshIndicator(
      onRefresh: logic.fetch,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Insets.tabContent,
          Insets.s8,
          Insets.tabContent,
          Insets.s24,
        ),
        children: <Widget>[
          SafeArea(
            top: false,
            child: Obx(() {
              switch (logic.state.status.value) {
                case InviteStatus.initial:
                case InviteStatus.loading:
                  return const InviteListSkeleton();
                case InviteStatus.error:
                  return TErrorState(
                    title: 'PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG'.tr(),
                    actionLabel: 'TRY_AGAIN'.tr(),
                    onAction: logic.fetch,
                  );
                case InviteStatus.loaded:
                  return loaded(
                    logic.state.referral.value ?? const ReferralModel(),
                  );
              }
            }),
          ),
        ],
      ),
    );
  }
}

/// The "Rewards" tab, loaded.
class RewardsBody extends StatelessWidget {
  const RewardsBody({super.key, required this.referral, required this.rewards});

  final ReferralModel referral;

  /// Newest first.
  final List<ReferralReward> rewards;

  String _caption(ReferralReward r, String? currency) {
    final DateTime? at = parseHistoryTime(r.createdAt);
    final String what = InviteeRole.of(r.role) == InviteeRole.driver
        ? r.baseAmount == null
            ? 'WALLET_TX_TOP_UP'.tr()
            : 'INVITE_REWARD_TOP_UP'
                .tr(args: <String>[formatWalletMoney(r.baseAmount, currency)])
        : 'TRIP'.tr();
    return <String>[what, if (at != null) historyTime(at)].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final String? currency = referral.currency;
    final DateTime now = DateTime.now();
    final String locale = context.locale.toString();
    final String? driverRate = commissionRateText(referral.driverTopUpRate);
    final String? passengerRate =
        commissionRateText(referral.passengerCommissionRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // DD-47: the total is on the wallet; here is where it came from.
        RewardSplitCard(
          driversLabel: 'INVITE_FROM_DRIVERS'.tr(),
          driversAmount: formatWalletMoney(
            earnedFrom(rewards, InviteeRole.driver),
            currency,
          ),
          passengersLabel: 'INVITE_FROM_PASSENGERS'.tr(),
          passengersAmount: formatWalletMoney(
            earnedFrom(rewards, InviteeRole.passenger),
            currency,
          ),
          note: 'INVITE_PAID_TO_WALLET'.tr(),
        ),
        const SizedBox(height: Insets.s24),
        Text(
          'INVITE_HOW_YOU_EARN'.tr(),
          style: context.texts.subtitle.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: Insets.s12),
        InviteRules(
          driverRule: driverRate == null
              ? null
              : 'INVITE_RULE_DRIVER'.tr(args: <String>[driverRate]),
          passengerRule: passengerRate == null
              ? null
              : 'INVITE_RULE_PASSENGER'.tr(args: <String>[passengerRate]),
        ),
        const SizedBox(height: Insets.s24),
        Text(
          'INVITE_REWARD_HISTORY'.tr(),
          style: context.texts.subtitle.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: Insets.s4),
        if (rewards.isEmpty)
          TEmptyState(
            icon: DsIcons.gift,
            title: 'INVITE_NO_REWARDS'.tr(),
            message: 'INVITE_NO_REWARDS_HINT'.tr(),
          )
        else
          for (final RewardRow row in rewardRows(rewards))
            switch (row) {
              RewardDayHeader(:final DateTime day) => InviteDayHeader(
                  label: historyDayLabel(day, now: now, locale: locale),
                ),
              RewardItemRow(:final ReferralReward reward) => Padding(
                  padding: const EdgeInsets.only(bottom: Insets.s8),
                  child: RewardTile(
                    name: reward.inviteeName,
                    caption: _caption(reward, currency),
                    amount: formatSignedWalletMoney(
                      reward.amount,
                      currency,
                      WalletTxDirection.moneyIn,
                    ),
                    fromDriver:
                        InviteeRole.of(reward.role) == InviteeRole.driver,
                  ),
                ),
            },
      ],
    );
  }
}
