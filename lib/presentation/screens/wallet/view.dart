import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/features/wallet/wallet_presentation.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

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
/// UX-redesign S2 (`03 S11`, `DD-21`): tinted balance cards with the existing
/// labels only, design-system filter chips, neutral transaction rows, and
/// skeleton / error / empty states. No withdraw and no top-up — there is no
/// API for either (N-01; the old commented-out top-up UI is in git history).
/// The fetch, the filter rules and the USD/riel formatting are unchanged.
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

  @override
  void initState() {
    super.initState();
    logic.fetch();
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: logic.fetch,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (dataWallet != null) ...<Widget>[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: WalletBalanceCard(
                        label: 'WALLET'.tr(),
                        // N-01: was routed through the riel formatter
                        // regardless of currency, so a USD balance of 125.50
                        // rendered as "126".
                        amount: formatWalletAmountWithSymbol(
                          dataWallet.balance,
                          dataWallet.currency,
                        ),
                        tone: WalletBalanceTone.wallet,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: WalletBalanceCard(
                        label: 'COMMISSION_FARE'.tr(),
                        amount: formatWalletAmountWithSymbol(
                          dataWallet.commistionFare,
                          dataWallet.currency,
                        ),
                        tone: WalletBalanceTone.commission,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.s24),
            ],
            // N-01: the backend returns `transactions` inside the wallet
            // payload and nothing rendered them. The ordering and filtering
            // rules live in wallet_presentation.dart.
            _transactionsSection(),
          ],
        );
    }
  }

  Widget _transactionsSection() {
    final TaarraaColors c = context.colors;
    final filters = logic.availableTypeFilters;
    final rows = logic.visibleTransactions;
    final currency = logic.state.wallet.value?.data?.currency?.toString();

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
                  _filterChip(label: name, value: name),
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
          for (final t in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.s8),
              child: TransactionRow(
                typeName: t.typeName?.toString(),
                date: formatTransactionDate(t.createdAt),
                status: t.statusName?.toString(),
                amount: formatWalletAmountWithSymbol(
                  t.amount,
                  t.currency?.toString() ?? currency,
                ),
              ),
            ),
      ],
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
