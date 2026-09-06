import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/app/funtion_convert.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/presentation/widgets/simmer_widget.dart';

import 'logic.dart';
import 'state.dart';

/// Drawer tab 2 ("MY_WALLET"). Was `payment_screen.dart`, which despite the
/// name never touched payments — `calculate_fee_screen.dart` is the real
/// accept-payment screen (`14` §5).
///
/// Stateful because the balance must refetch each time the tab is opened:
/// `DrawerScreen` constructs this widget fresh on every tab switch, so
/// `initState` reproduces exactly what the old screen did. The instance
/// itself comes from [WalletBinding] on the shell route, not from `new`.
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
    return Scaffold(
      backgroundColor: AppColors.light4,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const Divider(height: 1, color: AppColors.light1),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.light4,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x7CDEDADA),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      child: Obx(() {
                        if (logic.state.status.value == WalletStatus.loaded) {
                          final dataWallet = logic.state.wallet.value!.data;
                          return Row(
                            children: [
                              Expanded(
                                child: _balanceCard(
                                  label: "COMMISSION_FARE".tr(),
                                  amount: dataWallet!.commistionFare,
                                  currency: dataWallet.currency,
                                  color: AppColors.main,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _balanceCard(
                                  label: "WALLET".tr(),
                                  amount: dataWallet.balance,
                                  currency: dataWallet.currency,
                                  color: const Color(0xff01b951),
                                ),
                              ),
                            ],
                          );
                        }
                        // Both `loading` and `error`/`initial` showed the
                        // same shimmer pair before this move — preserved.
                        return Row(
                          children: [
                            Expanded(child: ShimmerWalletCard()),
                            const SizedBox(width: 18),
                            Expanded(child: ShimmerWalletCard()),
                          ],
                        );
                      }),
                    ),
                    // Top-up UI — N-01 (`12`). Left commented exactly as it
                    // was found; `_cardBank` and `state.bankSelected` exist
                    // only to serve it.
                    //  const SizedBox(height: 28,),
                    //  Align(
                    //    alignment: Alignment.centerLeft,
                    //    child: Text("TOP_UP_WALLET".tr(), style: ThemeConstands.font18SemiBold.copyWith(color: AppColors.dark1), textAlign: TextAlign.left)
                    //   ),
                    // const SizedBox(height: 22,),
                    // Obx(() => Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     _cardBank(ImageAssets.date_time, logic.state.bankSelected.value == 1, () => logic.selectBank(1)),
                    //     _cardBank(ImageAssets.date_time, logic.state.bankSelected.value == 2, () => logic.selectBank(2)),
                    //     _cardBank(ImageAssets.date_time, logic.state.bankSelected.value == 3, () => logic.selectBank(3)),
                    //   ],
                    // )),
                    // const SizedBox(height: 22,),
                    // FBTNWidget(
                    //   onPressed: logic.state.bankSelected.value == 0 ? null : () {},
                    //   color: AppColors.red,
                    //   textColor: AppColors.light4,
                    //   label: "PAYMENT_NOW".tr(),
                    //   enableWidth: true,
                    // )
                  ],
                ),
              ),
            ),
          )
        ]),
      ),
    );
  }

  /// Both balance tiles were duplicated line-for-line in `payment_screen.dart`
  /// apart from label, value and colour.
  Widget _balanceCard({
    required String label,
    required dynamic amount,
    required String? currency,
    required Color color,
  }) {
    final symbol = currency == "KHR" ? "៛" : "\$";
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFDEDADA),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: ThemeConstands.font18Regular
                        .copyWith(color: AppColors.light4),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.wallet_outlined,
                    color: AppColors.light4, size: 22),
              ],
            ),
            Text(
              "${formatToTwoDecimalPlaces(amount.toString().replaceAll(",", ""))} $symbol",
              style: ThemeConstands.font22SemiBold
                  .copyWith(color: AppColors.light4),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _cardBank(String image, bool actionSelect, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: AppColors.light4,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: actionSelect ? AppColors.red : AppColors.light3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFDEDADA),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(1, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              bottom: 12,
              child: SvgPicture.asset(image),
            ),
            if (actionSelect)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.light4,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.check, size: 22, color: AppColors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
