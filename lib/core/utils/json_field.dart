/// Reading scalars off a JSON payload, under an explicit policy:
/// **fail loudly on money, degrade on display.**
///
/// The generated-style models declared scalars non-nullable and read them
/// straight off the map, so an omitted key threw
/// `type 'Null' is not a subtype of type 'String'` — a message that names
/// neither the model nor the field, from a stack deep inside a `fromJson`.
///
/// The policy exists because the two failure modes have opposite costs:
///
/// * A **money** field that silently defaults is a wrong number shown to a
///   driver as if it were right. A fare computed from a price of `0`, or a
///   minimum fare that quietly became zero, is worse than a screen that
///   refuses to load — the screen gets reported, the wrong number gets
///   believed.
/// * A **display** field that refuses to parse takes down a whole list
///   because one row lacked a name. Degrading costs a blank label; failing
///   costs the screen.
library;

/// Thrown when a money-bearing field is missing or unusable.
///
/// Names the model and the field, because the point of failing loudly is that
/// the failure is actionable. The original error named neither.
class MalformedPayloadException implements Exception {
  const MalformedPayloadException({
    required this.model,
    required this.field,
    required this.received,
  });

  final String model;
  final String field;
  final Object? received;

  @override
  String toString() =>
      'MalformedPayloadException: $model.$field is money and cannot be '
      'read from ${received == null ? 'a missing value' : '"$received"'}. '
      'Refusing to continue rather than showing a wrong amount.';
}

/// A required money value, as a [num].
///
/// Accepts a number or a numeric string, because this backend sends both.
/// Anything else — including null — throws [MalformedPayloadException].
num requireMoney(
  dynamic value, {
  required String model,
  required String field,
}) {
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value.trim().replaceAll(',', ''));
    if (parsed != null) return parsed;
  }
  throw MalformedPayloadException(
    model: model,
    field: field,
    received: value,
  );
}

/// A required money value, as an [int]. Truncates a fractional input rather
/// than rounding it — a fare floor of `2999.9` riel is `2999`, and rounding
/// money up by default is not a decision this helper should make.
int requireMoneyInt(
  dynamic value, {
  required String model,
  required String field,
}) =>
    requireMoney(value, model: model, field: field).toInt();

// ---- Display fields: degrade -------------------------------------------

/// A display string, or `''` when absent. A blank label beats a dead screen.
String stringOrEmpty(dynamic value) => value is String ? value : '';

/// A display integer, or [fallback] when absent or unparseable.
int intOrDefault(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

/// A flag, or [fallback] when absent.
bool boolOrDefault(dynamic value, {bool fallback = false}) =>
    value is bool ? value : fallback;

/// A timestamp, or null when absent or unparseable.
///
/// Deliberately nullable rather than defaulting to `DateTime.now()` or the
/// epoch: a sentinel date is indistinguishable from a real one downstream,
/// and "we do not know when" is a fact the UI can render honestly.
DateTime? dateOrNull(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
