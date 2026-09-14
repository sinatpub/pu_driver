import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/widgets/receipt_card.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'state.dart';

/// Was `calculate_fee_screen.dart`. Despite `12`'s table naming
/// `payment_screen.dart` for D-08, this is the real accept-payment screen
/// (`14` §5). Route arguments are unpacked by [CalculateFeeBinding].
///
/// UX-redesign C6 (03 § Screen: Payment, 04 § B): title, receipt, total box,
/// hint and a pinned success button. The two payload branches, the exact
/// `payment.amount` formatting, the emit-after-REST order and the immediate
/// navigation are all unchanged (`DD-18`).
class CalculateFeeScreen extends StatelessWidget {
  const CalculateFeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CalculateFeeLogic logic = Get.find<CalculateFeeLogic>();
    final TaarraaColors c = context.colors;

    final String passengerName = logic.isFromDropBooking
        ? logic.dataComplete!.data!.passenger!.name.toString()
        : logic.dataDriverInfo!.passenger!.name.toString();
    final String? passengerImage = logic.isFromDropBooking
        ? logic.dataComplete!.data!.passenger!.profileImage?.toString()
        : logic.dataDriverInfo!.passenger!.profileImage?.toString();
    final String startAddress = logic.isFromDropBooking
        ? logic.dataComplete!.data!.startAddress.toString()
        : logic.dataDriverInfo!.startAddress.toString();
    final String endAddress = logic.isFromDropBooking
        ? logic.dataComplete!.data!.endAddress.toString()
        : logic.dataDriverInfo!.endAddress.toString();
    final String startTime = logic.isFromDropBooking
        ? logic.dataComplete!.data!.payment!.createdAt.toString()
        : logic.dataDriverInfo!.payment!.createdAt.toString();
    final String distance = logic.isFromDropBooking
        ? logic.dataComplete!.data!.payment!.distance.toString()
        : logic.dataDriverInfo!.payment!.distance.toString();
    final String duration = logic.isFromDropBooking
        ? logic.dataComplete!.data!.payment!.duration.toString()
        : logic.dataDriverInfo!.payment!.duration.toString();
    final String amount = logic.isFromDropBooking
        ? logic.dataComplete!.data!.payment!.amount.toString()
        : logic.dataDriverInfo!.payment!.amount.toString();
    final String? method = logic.isFromDropBooking
        ? logic.dataComplete!.data!.payment!.paymentMethod
        : logic.dataDriverInfo!.payment!.paymentMethod;

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                  horizontal: Insets.s16, vertical: 12),
              child: Text(
                'COLLECT_PAYMENT_TITLE'.tr(),
                style: context.texts.title.copyWith(color: c.textPrimary),
              ),
            ),
            Divider(height: 1, color: c.borderDivider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Insets.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ReceiptCard(
                      passengerName: passengerName,
                      passengerImageUrl: passengerImage,
                      method: method,
                      distance: formatDistanceWithUnits(distance, context),
                      duration: convertTimeString(duration),
                      dateTime: formatDateTime(startTime),
                      startAddress: startAddress,
                      endAddress: endAddress,
                    ),
                    const SizedBox(height: Insets.s16),
                    TotalBox(amount: '៛${formatRielAmount(amount)}'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.s16, 0, Insets.s16, Insets.s12),
              child: Text(
                'COLLECT_HINT'.tr(),
                textAlign: TextAlign.center,
                style: context.texts.caption.copyWith(color: c.textSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.s16, 0, Insets.s16, Insets.s16),
              child: TButton(
                label: 'PAYMENT_DONE'.tr(),
                variant: TButtonVariant.success,
                loading: logic.state.status.value == PaymentStatus.loading,
                onPressed: () => logic.acceptPayment(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
