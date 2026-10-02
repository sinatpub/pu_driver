import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:share_plus/share_plus.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/invite/data/models/referral_model.dart';
import 'package:tara_driver_application/presentation/screens/invite/invite_presentation.dart';
import 'package:tara_driver_application/presentation/screens/wallet/wallet_presentation.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';
import 'package:tara_driver_application/routes/app_routes.dart';

import 'logic.dart';
import 'state.dart';
import 'widgets/invite_widgets.dart';

/// Opens "My QR" (DD-45): the driver's invite QR and code, a share button,
/// what an invite earns, and one line on what it has earned so far.
///
/// One QR for everyone. It holds a link; the app the new person signs up in
/// decides whether they joined as a driver or as a passenger.
Future<void> showMyQrSheet(BuildContext context) {
  final InviteLogic logic = Get.find<InviteLogic>();
  logic.fetch();
  return showTSheet<void>(
    context: context,
    title: 'INVITE_MY_QR'.tr(),
    child: Obx(() {
      switch (logic.state.status.value) {
        case InviteStatus.initial:
        case InviteStatus.loading:
          return const MyQrSkeleton();
        case InviteStatus.error:
          return TErrorState(
            title: 'PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG'.tr(),
            actionLabel: 'TRY_AGAIN'.tr(),
            onAction: logic.fetch,
          );
        case InviteStatus.loaded:
          return MyQrBody(
            referral: logic.state.referral.value ?? const ReferralModel(),
          );
      }
    }),
  );
}

/// The loaded sheet. Scrolls: on a short phone, or at a large text size, the
/// QR and everything under it is taller than the sheet.
class MyQrBody extends StatelessWidget {
  const MyQrBody({super.key, required this.referral});

  final ReferralModel referral;

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      showTToast(context, 'INVITE_CODE_COPIED'.tr(), icon: DsIcons.check);
    }
  }

  void _share(String code, String target) {
    SharePlus.instance.share(
      ShareParams(text: 'INVITE_SHARE_TEXT'.tr(args: <String>[code, target])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TaarraaColors c = context.colors;
    final String? data = inviteQrData(referral);
    final String code = (referral.code ?? '').trim();

    if (data == null) {
      return TEmptyState(icon: DsIcons.qr, title: 'INVITE_NO_CODE'.tr());
    }

    final String? driverRate = commissionRateText(referral.driverTopUpRate);
    final String? passengerRate =
        commissionRateText(referral.passengerCommissionRate);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'INVITE_PITCH'.tr(),
            style: context.texts.bodySecondary.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Insets.s12),
          InviteQrCard(
            data: data,
            code: code.isEmpty ? '—' : code,
            codeLabel: 'INVITE_CODE'.tr(),
            copyLabel: 'INVITE_COPY_CODE'.tr(),
            qrLabel: 'INVITE_QR_LABEL'.tr(),
            onCopy: () => _copy(context, code),
          ),
          const SizedBox(height: Insets.s12),
          TButton(
            label: 'INVITE_SHARE'.tr(),
            icon: DsIcons.share,
            onPressed: () => _share(code, data),
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
          const SizedBox(height: Insets.s12),
          // DD-46: the rewards themselves live in the wallet. One line here,
          // because what the QR has earned is the reason to share it.
          InviteSummaryCard(
            title: 'INVITE_REWARDS'.tr(),
            summary: 'INVITE_SUMMARY'.tr(args: <String>[
              formatWalletMoney(
                totalEarned(referral.rewards),
                referral.currency,
              ),
              '${referral.invitees.length}',
            ]),
            onTap: () => Get.toNamed(AppRoutes.inviteRewards),
          ),
        ],
      ),
    );
  }
}
