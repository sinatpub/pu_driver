import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/history/widgets/history_days.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';
import 'package:tara_driver_application/presentation/screens/invite/invite_feature.dart';
import 'package:tara_driver_application/presentation/screens/invite/invite_presentation.dart';
import 'package:tara_driver_application/presentation/screens/invite/logic.dart';
import 'package:tara_driver_application/presentation/screens/invite/state.dart';
import 'package:tara_driver_application/presentation/screens/invite/transfer_sheet.dart';
import 'package:tara_driver_application/presentation/screens/invite/widgets/invite_widgets.dart';
import 'package:tara_driver_application/presentation/screens/wallet/data/models/wallet_model.dart';
import 'package:tara_driver_application/presentation/screens/wallet/wallet_presentation.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/routes/app_routes.dart';

import 'logic.dart';
import 'state.dart';
import 'widgets/wallet_widgets.dart';

/// Drawer tab 2 ("MY_WALLET"). Was `payment_screen.dart`, which despite the
/// name never touched payments — `calculate_fee_screen.dart` is the real
/// accept-payment screen (`14` §5).
///
/// Stateful because the balance must refetch each time the tab is opened:
/// `DrawerScreen` constructs this widget fresh on every tab switch, so
/// `initState` reproduces exactly what the old screen did. The instance
/// itself comes from [WalletBinding] on the shell route, not from `new`.
///
/// UX-redesign S2 (`03 S11`) gave it design-system filter chips and skeleton
/// / error / empty states. DD-43 reworked the content around the agreed
/// wallet model: one balance with the commission rate as a note, a warning
/// when commission is owed, and transactions grouped by day with translated
/// names and a sign for money in or out. Still no withdraw and no top-up —
/// there is no API for either (N-01). The fetch and the filter rules are
/// unchanged.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  // Resolved on each access, never cached: GetX owns this instance's
  // lifetime, and a `final` field would keep pointing at a disposed one
  // if the route is left and re-entered (hit on device 2026-09-06 —
  // "A TextEditingController was used after being disposed").
  WalletLogic get logic => Get.find<WalletLogic>();
  InviteLogic get invite => Get.find<InviteLogic>();

  @override
  void initState() {
    super.initState();
    logic.fetch();
    if (inviteFeatureEnabled) invite.fetch();
  }

  Future<void> _refresh() async {
    await Future.wait(<Future<void>>[
      logic.fetch(),
      if (inviteFeatureEnabled) invite.fetch(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Insets.tabContent,
              Insets.s16,
              Insets.tabContent,
              Insets.s24,
            ),
            children: <Widget>[Obx(_body)],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (logic.state.status.value) {
      case WalletStatus.initial:
      case WalletStatus.loading:
        return const WalletSkeleton();
      case WalletStatus.error:
        // N-01: a failed fetch used to render the same shimmer as loading,
        // so a driver whose wallet could not load watched it load forever
        // with no way to retry.
        return TErrorState(
          title: 'PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG'.tr(),
          actionLabel: 'PLEASE_TRY_AGAIN'.tr(),
          onAction: logic.fetch,
        );
      case WalletStatus.loaded:
        final dataWallet = logic.state.wallet.value?.data;
        final String? currency = dataWallet?.currency?.toString();
        final String? rate = commissionRateText(dataWallet?.commistionFare);
        final num? debt = walletDebt(dataWallet?.debted);
        final num rewards = _rewardBalance ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (dataWallet != null) ...<Widget>[
              // DD-43: one balance. `commission_fare` is the platform's rate,
              // not a second sum of money, so it is a note under the balance.
              WalletBalanceCard(
                label: 'WALLET_BALANCE'.tr(),
                amount: formatWalletMoney(dataWallet.balance, currency),
                note: rate == null
                    ? null
                    : 'WALLET_COMMISSION_NOTE'.tr(args: <String>[rate]),
              ),
              // DD-43: `debted` is unpaid commission. Shown only when owed.
              if (debt != null) ...<Widget>[
                const SizedBox(height: Insets.s8),
                WalletDebtCard(
                  title: 'WALLET_DEBT_TITLE'.tr(
                    args: <String>[formatWalletMoney(debt, currency)],
                  ),
                  message: 'WALLET_DEBT_MESSAGE'.tr(),
                  // DD-48: the driver owes and has rewards — one tap from
                  // the problem to the fix.
                  hint: rewards > 0
                      ? 'WALLET_DEBT_REWARD_HINT'.tr(args: <String>[
                          formatWalletMoney(rewards, currency),
                        ])
                      : null,
                  actionLabel: rewards > 0 ? 'INVITE_TRANSFER'.tr() : null,
                  onAction:
                      rewards > 0 ? () => confirmRewardTransfer(context) : null,
                ),
              ],
              // DD-48: invite rewards are a pot of their own, shown under the
              // balance with the button that moves them into it. Shown once
              // they have loaded; a failure to load them never takes the
              // wallet down with it.
              if (inviteFeatureEnabled) _inviteCard(),
              const SizedBox(height: Insets.s24),
            ],
            // N-01: the backend returns `transactions` inside the wallet
            // payload. The ordering, filtering, grouping and sign rules live
            // in wallet_presentation.dart.
            _transactionsSection(),
          ],
        );
    }
  }

  /// What the driver can transfer now, or null while the rewards have not
  /// loaded (or the feature is off).
  num? get _rewardBalance {
    if (!inviteFeatureEnabled ||
        invite.state.status.value != InviteStatus.loaded) {
      return null;
    }
    return rewardBalance(invite.state.referral.value);
  }

  Widget _inviteCard() {
    final num? available = _rewardBalance;
    if (available == null) return const SizedBox.shrink();
    final ReferralModel referral =
        invite.state.referral.value ?? const ReferralModel();
    final List<String> invited = <String>['${referral.invitees.length}'];
    return Padding(
      padding: const EdgeInsets.only(top: Insets.s8),
      child: RewardBalanceCard(
        label: 'INVITE_REWARDS'.tr(),
        amount: formatWalletMoney(available, referral.currency),
        caption: available > 0
            ? 'INVITE_NOT_IN_BALANCE'.tr(args: invited)
            : 'INVITE_NOTHING_TO_TRANSFER'.tr(args: invited),
        transferLabel: 'INVITE_TRANSFER'.tr(),
        transferring: invite.state.transferring.value,
        onTransfer: available > 0 ? () => confirmRewardTransfer(context) : null,
        onTap: () => Get.toNamed(AppRoutes.inviteRewards),
      ),
    );
  }

  /// The kind's translated name, or the backend's own text when the kind is
  /// not one the app knows.
  String _typeLabel(String? typeName) =>
      WalletTxKind.of(typeName).labelKey?.tr() ?? typeName ?? '—';

  Widget _transactionsSection() {
    final TaarraaColors c = context.colors;
    final filters = logic.availableTypeFilters;
    final List<WalletRow> rows = walletRows(logic.visibleTransactions);
    final currency = logic.state.wallet.value?.data?.currency?.toString();
    final DateTime now = DateTime.now();
    final String locale = context.locale.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'HISTORY'.tr(),
          style: context.texts.subtitle.copyWith(color: c.textPrimary),
        ),
        if (filters.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _filterChip(label: 'ALL'.tr(), value: null),
                for (final name in filters)
                  _filterChip(label: _typeLabel(name), value: name),
              ],
            ),
          )
        else
          const SizedBox(height: Insets.s12),
        if (rows.isEmpty)
          TEmptyState(
            icon: DsIcons.wallet,
            title: 'NO_TRANSACTIONS_YET'.tr(),
          )
        else
          for (final WalletRow row in rows)
            switch (row) {
              // DD-43: grouped by day, like the riding history (DD-40).
              WalletDayHeader(:final DateTime day) => Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Insets.s4, Insets.s8, Insets.s4, Insets.s8),
                    child: Text(
                      historyDayLabel(day, now: now, locale: locale),
                      style: context.texts.label.copyWith(color: c.textPrimary),
                    ),
                  ),
                ),
              WalletTxRow(:final transaction) => Padding(
                  padding: const EdgeInsets.only(bottom: Insets.s8),
                  child: _transactionRow(transaction, currency),
                ),
            },
      ],
    );
  }

  Widget _transactionRow(Transaction t, String? walletCurrency) {
    final WalletTxKind kind = WalletTxKind.of(t.typeName?.toString());
    final WalletTxDirection direction = walletTxDirection(kind, t.amount);
    final String? status = t.statusName?.toString();
    return TransactionRow(
      title: _typeLabel(t.typeName?.toString()),
      kind: kind,
      direction: direction,
      time: formatTransactionTime(t.createdAt),
      status: isRoutineStatus(status) ? null : status,
      amount: formatSignedWalletMoney(
        t.amount,
        t.currency?.toString() ?? walletCurrency,
        direction,
      ),
    );
  }

  Widget _filterChip({required String label, required String? value}) {
    return Padding(
      padding: const EdgeInsets.only(right: Insets.s8),
      child: TChip(
        label: label,
        selected: logic.state.typeFilter.value == value,
        onTap: () => logic.selectTypeFilter(value),
      ),
    );
  }
}
