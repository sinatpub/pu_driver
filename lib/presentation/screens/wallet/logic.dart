import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/features/wallet/data/repository/wallet_repository.dart';

import 'state.dart';

/// D-11 (`12`) — replaces `DriverWalletBloc`. Read-only today.
///
/// Moved out of `features/wallet/presentation/controller/` as part of `14`
/// §3.6: a feature owns its data layer, a screen owns its presentation.
class WalletLogic extends GetxController {
  WalletLogic(this._repository);

  final WalletRepository _repository;
  final WalletState state = WalletState();

  Future<void> fetch() async {
    state.status.value = WalletStatus.loading;
    final result = await _repository.getWallet();
    result.when(
      ok: (data) {
        state.wallet.value = data;
        state.status.value = WalletStatus.loaded;
      },
      err: (_) => state.status.value = WalletStatus.error,
    );
  }

  void selectBank(int index) => state.bankSelected.value = index;
}
