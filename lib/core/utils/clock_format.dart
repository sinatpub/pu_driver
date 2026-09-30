/// An elapsed time as a clock: "0:07", "12:40", or "1:02:10" past an hour.
/// Used by the trip sheet's waiting timer (DD-37) and on-trip time (DD-38).
String formatClock(Duration elapsed) {
  final int total = elapsed.isNegative ? 0 : elapsed.inSeconds;
  final int h = total ~/ 3600;
  final String m = ((total % 3600) ~/ 60).toString();
  final String s = (total % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.padLeft(2, '0')}:$s' : '$m:$s';
}

/// A duration as the server writes it — "8 mins 24 seconds", "1 hours
/// 5 mins" — read with the same patterns `convertTimeString` used. Null when
/// nothing matches, so the caller can show the text as given.
Duration? parseDurationText(String text) {
  int? read(String unit) =>
      int.tryParse(RegExp('(\\d+)\\s*$unit', caseSensitive: false)
              .firstMatch(text)
              ?.group(1) ??
          '');
  final int? h = read('hour');
  final int? m = read('min');
  final int? s = read('sec');
  if (h == null && m == null && s == null) return null;
  return Duration(hours: h ?? 0, minutes: m ?? 0, seconds: s ?? 0);
}
