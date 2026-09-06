import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/wallet/data/models/wallet_model.dart';

enum WalletStatus { initial, loading, loaded, error }

class WalletState {
  final Rx<WalletStatus> status = Rx<WalletStatus>(WalletStatus.initial);
  final Rxn<WalletModel> wallet = Rxn<WalletModel>();

  /// Selected top-up bank card. Nothing sets this today — the top-up UI it
  /// belongs to is still commented out in the view, pending N-01 (`12`).
  final RxInt bankSelected = 0.obs;
}
