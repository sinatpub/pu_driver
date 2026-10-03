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
import 'transfer_sheet.dart';
import 'widgets/invite_widgets.dart';

/// "Invite rewards" (DD-45, DD-46, DD-48): one screen, two tabs.
///
/// **Rewards** — the reward balance and the button that moves it into the
/// wallet balance, where the rewards came from, the rules, and the history:
/// every reward, and every transfer out. **People** — who joined with the
/// driver's code.
///
/// Opened from the wallet's reward card and from the QR sheet. Rewards are a
/// pot of their own (DD-48): they pay no commission until the driver
/// transfers them to the balance. There is no cash withdrawal.
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
                      history: logic.history,
                      transferring: logic.state.transferring.value,
                      onTransfer: () => confirmRewardTransfer(context),
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
  const RewardsBody({
    super.key,
    required this.referral,
    required this.history,
    required this.transferring,
    required this.onTransfer,
  });

  final ReferralModel referral;

  /// Rewards and transfers, newest first.
  final List<RewardEntry> history;
  final bool transferring;
  final VoidCallback onTransfer;

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

  Widget _tile(RewardEntry entry, String? currency) {
    switch (entry) {
      case EarnedEntry(:final ReferralReward reward):
        return RewardTile(
          name: reward.inviteeName,
          caption: _caption(reward, currency),
          amount: formatSignedWalletMoney(
            reward.amount,
            currency,
            WalletTxDirection.moneyIn,
          ),
          icon: InviteeRole.of(reward.role) == InviteeRole.driver
              ? DsIcons.car
              : DsIcons.users,
        );
      case TransferEntry(:final RewardTransfer transfer):
        final DateTime? at = entry.at;
        return RewardTile(
          name: 'INVITE_TRANSFERRED'.tr(),
          caption: at == null ? '' : historyTime(at),
          amount: formatSignedWalletMoney(
            transfer.amount,
            currency,
            WalletTxDirection.moneyOut,
          ),
          icon: DsIcons.wallet,
          moneyIn: false,
        );
    }
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
    final num available = rewardBalance(referral);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // DD-48: what can be moved to the wallet now, and the button.
        RewardBalanceCard(
          label: 'INVITE_REWARD_BALANCE'.tr(),
          amount: formatWalletMoney(available, currency),
          caption: 'INVITE_TRANSFER_TO_USE'.tr(),
          transferLabel: 'INVITE_TRANSFER'.tr(),
          transferring: transferring,
          onTransfer: available > 0 ? onTransfer : null,
          figures: <(String, String)>[
            (
              'INVITE_TOTAL_EARNED'.tr(),
              formatWalletMoney(totalEarned(referral.rewards), currency),
            ),
            (
              'INVITE_TRANSFERRED'.tr(),
              formatWalletMoney(totalTransferred(referral.transfers), currency),
            ),
          ],
        ),
        const SizedBox(height: Insets.s8),
        // DD-47: where the rewards came from.
        RewardSplitCard(
          driversLabel: 'INVITE_FROM_DRIVERS'.tr(),
          driversAmount: formatWalletMoney(
            earnedFrom(referral.rewards, InviteeRole.driver),
            currency,
          ),
          passengersLabel: 'INVITE_FROM_PASSENGERS'.tr(),
          passengersAmount: formatWalletMoney(
            earnedFrom(referral.rewards, InviteeRole.passenger),
            currency,
          ),
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
        if (history.isEmpty)
          TEmptyState(
            icon: DsIcons.gift,
            title: 'INVITE_NO_REWARDS'.tr(),
            message: 'INVITE_NO_REWARDS_HINT'.tr(),
          )
        else
          for (final RewardRow row in rewardRows(history))
            switch (row) {
              RewardDayHeader(:final DateTime day) => InviteDayHeader(
                  label: historyDayLabel(day, now: now, locale: locale),
                ),
              RewardItemRow(:final RewardEntry entry) => Padding(
                  padding: const EdgeInsets.only(bottom: Insets.s8),
                  child: _tile(entry, currency),
                ),
            },
      ],
    );
  }
}
