import 'package:easy_localization/easy_localization.dart';

/// "650 m" under a kilometre, "1.2 km" from there (DD-35–DD-39).
String formatKm(double km) => km < 1
    ? '${(km * 1000).round()} ${'m'.tr()}'
    : '${km.toStringAsFixed(1)} ${'km'.tr()}';

/// A distance as the server writes it — "3.08 km", "850 m", or a bare
/// "3.08", which is kilometres — through [formatKm]. Anything else is shown
/// as given.
String formatDistanceText(String text) {
  final RegExpMatch? match =
      RegExp(r'^\s*([0-9]+(?:\.[0-9]+)?)\s*([a-zA-Z]*)\s*$').firstMatch(text);
  if (match == null) return text;
  final double? value = double.tryParse(match.group(1)!);
  if (value == null) return text;
  return switch (match.group(2)!.toLowerCase()) {
    '' || 'km' || 'kms' => formatKm(value),
    'm' => formatKm(value / 1000),
    _ => text,
  };
}
