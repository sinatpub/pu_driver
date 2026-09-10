/// Defensive list parsing for the generated-style models.
///
/// Every one of these models was written as
/// `List<T>.from(json["key"].map(...))`, which calls `.map` on whatever the
/// key holds. When the key is absent or null — an account with no history, a
/// booking with no vehicle images, a notification with no attachments — that
/// is `.map` on null, a `NoSuchMethodError`, and a screen that cannot open.
///
/// Found in the wallet first (N-01, 2026-09-10, where it meant every newly
/// approved driver was locked out of their own wallet) and then in ten more
/// places by grepping for the same shape.
///
/// Returns an empty list rather than null: the callers all treat "no rows" and
/// "no list" identically, and an empty list is the shape their UI already
/// handles.
List<T> parseJsonList<T>(
  dynamic value,
  T Function(dynamic item) fromItem,
) {
  if (value is! List) return <T>[];
  return <T>[for (final item in value) fromItem(item)];
}
