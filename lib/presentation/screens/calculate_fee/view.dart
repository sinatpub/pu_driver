import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/theme/tokens.dart';
import 'package:tara_driver_application/core/utils/clock_format.dart';
import 'package:tara_driver_application/core/utils/distance_format.dart';
import 'package:tara_driver_application/presentation/screens/calculate_fee/widgets/receipt_card.dart';
import 'package:tara_driver_application/presentation/widgets/ds/ds.dart';

import 'logic.dart';
import 'state.dart';

/// Was `calculate_fee_screen.dart`. Despite `12`'s table naming
/// `payment_screen.dart` for D-08, this is the real accept-payment screen
/// (`14` §5). Route arguments are unpacked by [CalculateFeeBinding].
///
/// UX-redesign C6 (03 § Screen: Payment, 04 § B), reworked by DD-39: the
/// trip-complete header, the amount to collect with its method, the trip,
/// then a method-aware hint and a pinned success button. The two payload
/// branches, the exact `payment.amount` formatting, the emit-after-REST order
/// and the immediate navigation are all unchanged (`DD-18`).
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

    final String amountText = '៛${formatRielAmount(amount)}';
    final PaymentKind kind = PaymentKind.of(method);
    final Duration? parsedDuration = parseDurationText(duration);

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.s16, Insets.s16, Insets.s16, 0),
              child: PaymentHeader(bookingCode: logic.bookingCode),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Insets.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    PaymentHero(
                      method: method,
                      amount: amountText,
                      distance: formatDistanceText(distance),
                      duration: parsedDuration == null
                          ? duration
                          : formatClock(parsedDuration),
                      time: _formatTime(startTime),
                    ),
                    const SizedBox(height: Insets.s12),
                    PaymentRoute(
                      passengerName: passengerName,
                      passengerImageUrl: passengerImage,
                      startAddress: startAddress,
                      endAddress: endAddress,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.s16, 0, Insets.s16, Insets.s12),
              child: Text(
                kind.hint(amountText),
                textAlign: TextAlign.center,
                style: context.texts.caption.copyWith(color: c.textSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.s16, 0, Insets.s16, Insets.s16),
              // DD-39: reactive, so the spinner shows — and the button is
              // disabled — while the request is in flight. Read without Obx,
              // it never updated, and a second tap sent a second request.
              child: SafeArea(
                top: false,
                child: Obx(() {
                  final bool busy =
                      logic.state.status.value == PaymentStatus.loading;
                  return TButton(
                    label: kind.action,
                    variant: TButtonVariant.success,
                    loading: busy,
                    onPressed: busy ? null : logic.acceptPayment,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "17:36" for a time today, "30/09 17:36" otherwise; the server's text if it
/// does not parse. Digits only, so it reads the same in Khmer (DD-39).
String _formatTime(String serverTime) {
  try {
    final DateTime t = DateFormat('yyyy-MM-dd HH:mm:ss').parse(serverTime);
    final DateTime now = DateTime.now();
    final bool today =
        t.year == now.year && t.month == now.month && t.day == now.day;
    return DateFormat(today ? 'HH:mm' : 'dd/MM HH:mm').format(t);
  } on FormatException {
    return serverTime;
  }
}
