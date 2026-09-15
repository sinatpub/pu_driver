// NumberFormat/DateFormat come via easy_localization's re-export, which is
// how `app/funtion_convert.dart` already reaches them. `intl` itself is a
// transitive dependency and is not declared in pubspec.yaml; declaring it
// would need a docs/13 entry per .agent/RULES.md.
import 'package:easy_localization/easy_localization.dart';
import 'package:tara_driver_application/core/utils/money.dart';
import 'package:tara_driver_application/presentation/screens/wallet/data/models/wallet_model.dart';

/// N-01 (docs/12) — presenting the wallet the backend already returns.
///
/// Pure: no GetX, no BuildContext, no widgets. The wallet is the driver's
/// money, and `.agent/RULES.md` puts money in mandatory-test territory, so
/// every rule about how it is displayed or ordered lives here where it can be
/// tested rather than inside a widget tree.

/// The symbol for a currency code.
///
/// Unknown or absent codes fall back to `$`, matching what the screen did
/// before. That fallback is a guess the backend should not be making us take
/// — see the note on [formatWalletAmount].
String currencySymbol(String? currency) => currency == "KHR" ? "៛" : "\$";

/// Whether a currency is conventionally written without a fractional part.
///
/// Riel is used in whole units in practice, which is why the app's shared
/// `formatRielAmount` renders zero decimals. It was called
/// `formatToTwoDecimalPlaces` until 2026-09-10, and this screen using it for
/// USD on the strength of that name is what produced the rounding defect
/// below.
bool isWholeUnitCurrency(String? currency) => currency == "KHR";

/// Formats a wallet amount for display.
///
/// The wallet is the one screen whose currency is **dynamic**, and it was
/// passing its amounts through the riel formatter regardless. A USD balance
/// of `125.50` rendered as `126`, and `0.99` rendered as `1` — the driver's
/// own balance, rounded up, on the screen they check it on.
///
/// A null amount renders as an em dash rather than `0`: "not reported" and
/// "empty" are different, and a driver seeing `$0.00` because a field failed
/// to parse would be worse than a driver seeing nothing.
String formatWalletAmount(dynamic amount, String? currency) {
  final value = parseMoney(amount);
  if (value == null) return "—";

  final pattern = isWholeUnitCurrency(currency) ? "#,##0" : "#,##0.00";
  return NumberFormat(pattern).format(value);
}

/// Amount with its symbol, in the order the screen already used.
String formatWalletAmountWithSymbol(dynamic amount, String? currency) =>
    "${formatWalletAmount(amount, currency)} ${currencySymbol(currency)}";

/// Transactions, newest first.
///
/// `created_at` is `dynamic` on the model like everything else here, so an
/// unparseable or missing timestamp sorts last rather than throwing. Ordering
/// is stable for equal timestamps, so a page of same-second transactions
/// keeps the order the backend sent.
List<Transaction> sortedTransactions(List<Transaction>? transactions) {
  final list = [...?transactions];
  final indexed = <MapEntry<int, Transaction>>[
    for (var i = 0; i < list.length; i++) MapEntry(i, list[i]),
  ];

  indexed.sort((a, b) {
    final da = _parseDate(a.value.createdAt);
    final db = _parseDate(b.value.createdAt);
    if (da == null && db == null) return a.key.compareTo(b.key);
    if (da == null) return 1;
    if (db == null) return -1;
    final byDate = db.compareTo(da);
    return byDate != 0 ? byDate : a.key.compareTo(b.key);
  });

  return [for (final e in indexed) e.value];
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// The transaction types present in this wallet, for the filter row.
///
/// Derived from the data rather than a hardcoded list, deliberately. The
/// backend sends `type` as an integer and `type_name` as its display string,
/// and **the integer codes are not documented anywhere the client can see** —
/// the `topUp = 10` / `withdraw = 11` constants in `core/contracts/` are FCM
/// notification types, not transaction types (see `.agent/DECISIONS.md`
/// Q-4). Filtering on names the backend supplied avoids inventing a mapping
/// that could silently mis-file a driver's money.
List<String> transactionTypeNames(List<Transaction>? transactions) {
  final names = <String>{};
  for (final t in transactions ?? const <Transaction>[]) {
    final name = t.typeName?.toString().trim();
    if (name != null && name.isNotEmpty) names.add(name);
  }
  final sorted = names.toList()..sort();
  return sorted;
}

/// Transactions matching [typeName]; null means "all".
List<Transaction> filterTransactionsByType(
  List<Transaction>? transactions,
  String? typeName,
) {
  final list = [...?transactions];
  if (typeName == null) return list;
  return [
    for (final t in list)
      if (t.typeName?.toString().trim() == typeName) t,
  ];
}

/// A transaction's date for display, or null when it has none to show.
String? formatTransactionDate(dynamic createdAt) {
  final date = _parseDate(createdAt);
  if (date == null) return null;
  return DateFormat('d MMM yyyy · HH:mm').format(date.toLocal());
}
