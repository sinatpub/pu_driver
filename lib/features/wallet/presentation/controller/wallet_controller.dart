import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/wallet/data/models/wallet_model.dart';
import 'package:tara_driver_application/features/wallet/data/repository/wallet_repository.dart';

enum WalletStatus { initial, loading, loaded, error }

/// D-11 (docs/12) — replaces `DriverWalletBloc`. Read-only today; wired up
/// per-screen like the other list/detail controllers (payment_screen.dart
/// is its only consumer), not a permanent singleton.
class WalletController extends GetxController {
  WalletController(this._repository);

  final WalletRepository _repository;

  final status = Rx<WalletStatus>(WalletStatus.initial);
  final wallet = Rxn<WalletModel>();

  Future<void> fetch() async {
    status.value = WalletStatus.loading;
    final result = await _repository.getWallet();
    result.when(
      ok: (data) {
        wallet.value = data;
        status.value = WalletStatus.loaded;
      },
      err: (_) => status.value = WalletStatus.error,
    );
  }
}
