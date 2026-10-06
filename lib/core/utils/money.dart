/// N-01 (docs/12) — reading money off the wire.
///
/// Every monetary field on `WalletModel` is declared `dynamic`, because the
/// backend is not consistent about it: `balance` and `amount` arrive
/// sometimes as a JSON number and sometimes as a quoted string. Code that
/// does arithmetic or comparison on `dynamic` compiles and then fails at
/// runtime on whichever shape it did not expect.
///
/// `.agent/RULES.md` puts anything touching money in mandatory-test
/// territory. This is the one coercion point, so there is one place to test.
library;

/// Reads a monetary value that may arrive as a number, a numeric string, or
/// nothing at all.
///
/// Returns null rather than 0 when the value is missing or unparseable —
/// "no balance reported" and "a balance of zero" are different facts, and
/// showing a driver `$0.00` because a field failed to parse is worse than
/// showing them nothing.
num? parseMoney(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) {
    final cleaned = value.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return null;
    return num.tryParse(cleaned);
  }
  return null;
}

/// The same value as a double, for arithmetic. Null stays null.
double? parseMoneyAsDouble(dynamic value) => parseMoney(value)?.toDouble();

/// The symbol for a currency code.
///
/// Unknown or absent codes fall back to `$`, matching what the wallet screen
/// did before this moved here.
String currencySymbol(String? currency) => currency == "KHR" ? "៛" : "\$";

/// Whether a currency is conventionally written without a fractional part.
///
/// Riel is used in whole units in practice, which is why the app's
/// `formatRielAmount` renders zero decimals.
bool isWholeUnitCurrency(String? currency) => currency == "KHR";
