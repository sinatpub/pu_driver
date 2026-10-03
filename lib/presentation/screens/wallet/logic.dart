import 'package:get/get.dart' hide Trans;
import 'package:pu_taxi_driver/presentation/screens/wallet/data/repository/wallet_repository.dart';

import 'package:pu_taxi_driver/presentation/screens/wallet/data/models/wallet_model.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/wallet_presentation.dart';

import 'state.dart';

/// D-11 (`12`) — replaces `DriverWalletBloc`. Read-only today.
///
/// Moved out of `features/wallet/presentation/controller/` as part of `14`
/// §3.6: a feature owns its data layer, a screen owns its presentation.
class WalletLogic extends GetxController {
  WalletLogic(this._repository);

  final WalletRepository _repository;
  final WalletState state = WalletState();

  /// [silent] refreshes a wallet that is already on screen without swapping
  /// it for the skeleton, and keeps it if the refresh fails — used after a
  /// reward transfer (DD-48), where the driver is looking at the balance.
  Future<void> fetch({bool silent = false}) async {
    final bool keep = silent && state.status.value == WalletStatus.loaded;
    if (!keep) state.status.value = WalletStatus.loading;
    final result = await _repository.getWallet();
    result.when(
      ok: (data) {
        state.wallet.value = data;
        state.status.value = WalletStatus.loaded;
      },
      err: (_) {
        if (!keep) state.status.value = WalletStatus.error;
      },
    );
  }

  void selectBank(int index) => state.bankSelected.value = index;

  /// N-01: null clears the filter and shows everything.
  void selectTypeFilter(String? typeName) => state.typeFilter.value = typeName;

  /// The rows the list should render: filtered, then newest first.
  List<Transaction> get visibleTransactions => sortedTransactions(
        filterTransactionsByType(
          state.wallet.value?.data?.transactions,
          state.typeFilter.value,
        ),
      );

  List<String> get availableTypeFilters =>
      transactionTypeNames(state.wallet.value?.data?.transactions);
}
