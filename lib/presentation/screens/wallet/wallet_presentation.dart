// NumberFormat/DateFormat come via easy_localization's re-export, which is
// how `app/funtion_convert.dart` already reaches them. `intl` itself is a
// transitive dependency and is not declared in pubspec.yaml; declaring it
// would need a docs/13 entry per .agent/RULES.md.
import 'package:easy_localization/easy_localization.dart';
import 'package:pu_taxi_driver/core/utils/money.dart';
import 'package:pu_taxi_driver/presentation/screens/wallet/data/models/wallet_model.dart';

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

/// A wallet amount with its symbol first — "៛85,400", "$125.50" — the order
/// every other money figure in the app uses (DD-43). A negative amount keeps
/// its sign in front of the symbol: "−៛1,300".
String formatWalletMoney(dynamic amount, String? currency) {
  final value = parseMoney(amount);
  if (value == null) return "—";
  final String figure = formatWalletAmount(value.abs(), currency);
  return "${value < 0 ? "−" : ""}${currencySymbol(currency)}$figure";
}

/// What a wallet transaction is (DD-43), read from the backend's `type_name`
/// — the integer `type` codes are still undocumented (see
/// [transactionTypeNames]). Matching is loose on purpose ("Top Up", "top-up",
/// "TOPUP"); a name that matches nothing is [unknown] and is shown as the
/// backend wrote it, with no sign or direction assumed.
enum WalletTxKind {
  topUp,
  tripEarning,
  commission,
  withdraw,
  referralReward,

  /// Invite rewards moved into the balance by the driver (DD-48).
  rewardTransfer,
  unknown;

  static WalletTxKind of(String? typeName) {
    final String name =
        (typeName ?? '').toLowerCase().replaceAll(RegExp('[^a-z]'), '');
    if (name.contains('topup')) return WalletTxKind.topUp;
    if (name.contains('commission')) return WalletTxKind.commission;
    if (name.contains('withdraw')) return WalletTxKind.withdraw;
    // Before "reward": "Reward Transfer" contains both words.
    if (name.contains('transfer')) return WalletTxKind.rewardTransfer;
    if (name.contains('referral') || name.contains('reward')) {
      return WalletTxKind.referralReward;
    }
    if (name.contains('earning')) return WalletTxKind.tripEarning;
    return WalletTxKind.unknown;
  }

  /// The translation key for this kind's name; null for [unknown], whose
  /// name is the backend's own text.
  String? get labelKey => switch (this) {
        WalletTxKind.topUp => 'WALLET_TX_TOP_UP',
        WalletTxKind.tripEarning => 'WALLET_TX_TRIP_EARNING',
        WalletTxKind.commission => 'WALLET_TX_COMMISSION',
        WalletTxKind.withdraw => 'WALLET_TX_WITHDRAW',
        WalletTxKind.referralReward => 'WALLET_TX_REFERRAL_REWARD',
        WalletTxKind.rewardTransfer => 'WALLET_TX_REWARD_TRANSFER',
        WalletTxKind.unknown => null,
      };
}

/// Which way the money moved.
enum WalletTxDirection { moneyIn, moneyOut, unknown }

/// A transaction's direction (DD-43): a negative amount is always money out;
/// otherwise the kind decides — commission and withdrawals go out, top-ups,
/// trip earnings and referral rewards come in. An unknown kind with a
/// positive amount is [WalletTxDirection.unknown]: no sign is guessed.
WalletTxDirection walletTxDirection(WalletTxKind kind, dynamic amount) {
  final num? value = parseMoney(amount);
  if (value != null && value < 0) return WalletTxDirection.moneyOut;
  return switch (kind) {
    WalletTxKind.commission ||
    WalletTxKind.withdraw =>
      WalletTxDirection.moneyOut,
    WalletTxKind.topUp ||
    WalletTxKind.tripEarning ||
    WalletTxKind.referralReward ||
    WalletTxKind.rewardTransfer =>
      WalletTxDirection.moneyIn,
    WalletTxKind.unknown => WalletTxDirection.unknown,
  };
}

/// A transaction amount with its direction: "+៛18,200", "−៛1,300", or the
/// bare "៛500" when the direction is unknown. The figure is the absolute
/// value — the sign comes from [direction], so a commission the backend
/// sends as a positive number still reads as money out.
String formatSignedWalletMoney(
  dynamic amount,
  String? currency,
  WalletTxDirection direction,
) {
  final num? value = parseMoney(amount);
  if (value == null) return "—";
  final String figure =
      "${currencySymbol(currency)}${formatWalletAmount(value.abs(), currency)}";
  return switch (direction) {
    WalletTxDirection.moneyIn => "+$figure",
    WalletTxDirection.moneyOut => "−$figure",
    WalletTxDirection.unknown => figure,
  };
}

/// The platform's commission rate as text — "10", "7.5" — from the wallet's
/// `commission_fare`, which is a percentage of each trip's fare (DD-43).
/// Null when it is not reported or not positive, so no note is shown.
String? commissionRateText(dynamic commissionFare) {
  final num? rate = parseMoney(commissionFare);
  if (rate == null || rate <= 0) return null;
  return rate == rate.roundToDouble()
      ? rate.round().toString()
      : NumberFormat('0.##').format(rate);
}

/// What the driver owes the platform — the wallet's `debted`, unpaid
/// commission (DD-43) — or null when nothing is owed or it is not reported.
num? walletDebt(dynamic debted) {
  final num? value = parseMoney(debted);
  return value != null && value > 0 ? value : null;
}

/// Whether a status needs no mention. "Success" on every row is noise; a
/// status is shown only when it is something else (pending, failed…).
bool isRoutineStatus(String? statusName) => const <String>{
      '',
      'success',
      'successful',
      'completed',
      'paid',
    }.contains((statusName ?? '').trim().toLowerCase());

/// When a transaction happened, in local time, or null.
DateTime? transactionDateTime(dynamic createdAt) =>
    _parseDate(createdAt)?.toLocal();

/// "09:14" — the day is in the list's header.
String? formatTransactionTime(dynamic createdAt) {
  final DateTime? at = transactionDateTime(createdAt);
  return at == null ? null : DateFormat('HH:mm').format(at);
}

/// One line of the transaction list: a day header or a transaction.
sealed class WalletRow {
  const WalletRow();
}

class WalletDayHeader extends WalletRow {
  const WalletDayHeader(this.day);

  /// Midnight of the day, local time.
  final DateTime day;
}

class WalletTxRow extends WalletRow {
  const WalletTxRow(this.transaction);

  final Transaction transaction;
}

/// [transactions] (already sorted) with a [WalletDayHeader] before the first
/// one of each day. One with no readable date stays under the header above.
List<WalletRow> walletRows(List<Transaction> transactions) {
  final List<WalletRow> rows = <WalletRow>[];
  DateTime? current;
  for (final Transaction t in transactions) {
    final DateTime? at = transactionDateTime(t.createdAt);
    if (at != null) {
      final DateTime day = DateTime(at.year, at.month, at.day);
      if (day != current) {
        rows.add(WalletDayHeader(day));
        current = day;
      }
    }
    rows.add(WalletTxRow(t));
  }
  return rows;
}

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
