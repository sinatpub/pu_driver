import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/utils/money.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';
import 'package:tara_driver_application/presentation/screens/invite/invite_presentation.dart';
import 'package:tara_driver_application/presentation/screens/wallet/logic.dart';
import 'package:tara_driver_application/presentation/screens/wallet/wallet_presentation.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'widgets/invite_widgets.dart';

/// Opens the transfer sheet and, when the driver confirms an amount, moves it
/// from the reward balance into the wallet balance (DD-48, DD-49).
///
/// The driver types the amount; "All" fills in the whole reward balance. The
/// sheet says where the money goes — to what the driver owes first, if they
/// owe (DD-43) — what is left in rewards, and that it does not come back. The
/// wallet is refreshed afterwards, so its balance and its list are the
/// server's.
Future<void> confirmRewardTransfer(BuildContext context) async {
  final InviteLogic invite = Get.find<InviteLogic>();
  final ReferralModel? referral = invite.state.referral.value;
  final num available = rewardBalance(referral);
  if (available <= 0 || invite.state.transferring.value) return;

  final String? currency = referral?.currency;
  final WalletLogic? wallet =
      Get.isRegistered<WalletLogic>() ? Get.find<WalletLogic>() : null;
  final walletData = wallet?.state.wallet.value?.data;
  final num? balance = parseMoney(walletData?.balance);
  final num? debt = walletDebt(walletData?.debted);
  String money(num? value) => formatWalletMoney(value, currency);

  final num? amount = await showTSheet<num>(
    context: context,
    title: 'INVITE_TRANSFER'.tr(),
    child: Builder(
      builder: (BuildContext sheetContext) => TransferAmountBody(
        availableText:
            'INVITE_TRANSFER_AVAILABLE'.tr(args: <String>[money(available)]),
        amountLabel: 'INVITE_TRANSFER_AMOUNT'.tr(),
        symbol: currencySymbol(currency),
        allLabel: 'ALL'.tr(),
        allValue: transferAmountText(available, currency),
        wholeUnits: isWholeUnitCurrency(currency),
        parse: (String text) => parseTransferAmount(text, currency),
        errorFor: (num typed) => checkTransferAmount(typed, available) ==
                TransferAmountCheck.tooMuch
            ? 'INVITE_TRANSFER_TOO_MUCH'.tr(args: <String>[money(available)])
            : null,
        linesFor: (num typed) {
          final TransferPreview preview =
              transferPreview(amount: typed, balance: balance, debt: debt);
          return <String>[
            if (preview.toDebt > 0 && preview.toBalance > 0)
              'INVITE_TRANSFER_DEBT_SPLIT'.tr(args: <String>[
                money(preview.toDebt),
                money(preview.toBalance),
              ])
            else if (preview.toDebt > 0)
              'INVITE_TRANSFER_DEBT_ALL'
                  .tr(args: <String>[money(preview.debtLeft)]),
            if (preview.balanceAfter != null)
              'INVITE_TRANSFER_BALANCE_AFTER'
                  .tr(args: <String>[money(preview.balanceAfter)]),
            'INVITE_TRANSFER_REWARDS_LEFT'
                .tr(args: <String>[money(available - typed)]),
          ];
        },
        confirmLabelFor: (num? typed) => typed == null
            ? 'INVITE_TRANSFER_CONFIRM'.tr()
            : 'INVITE_TRANSFER_BUTTON'.tr(args: <String>[money(typed)]),
        warning: 'INVITE_TRANSFER_ONE_WAY'.tr(),
        cancelLabel: 'CANCEL'.tr(),
        onConfirm: (num typed) => Navigator.of(sheetContext).pop(typed),
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    ),
  );
  if (amount == null) return;

  final num? moved = await invite.transferRewards(amount);
  if (!context.mounted) return;
  if (moved == null) {
    showTToast(context, 'INVITE_TRANSFER_FAILED'.tr(), icon: DsIcons.warn);
    return;
  }
  if (wallet != null) unawaited(wallet.fetch(silent: true));
  showTToast(
    context,
    'INVITE_TRANSFER_DONE'.tr(args: <String>[money(moved)]),
    icon: DsIcons.check,
  );
}
