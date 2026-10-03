import 'package:easy_localization/easy_localization.dart';
import 'package:pu_taxi_driver/presentation/screens/history/data/models/history_driver_info_model.dart';

/// DD-40 — the history list grouped by day.
///
/// Presentation only: the list keeps the order the server returned (newest
/// first) and a header is put in front of each run of trips from one day.

/// When a trip happened: its start, or — for a trip that never started, such
/// as a cancelled one — when it was created. Null if neither parses.
DateTime? historyDate(DataHistory item) =>
    parseHistoryTime(item.startTime) ?? parseHistoryTime(item.createdAt);

/// When a trip ended: its end time, else when its payment was created, else
/// its start. Used for the detail screen's passenger-call window (DD-42).
DateTime? historyEndedAt(DataHistory item) =>
    parseHistoryTime(item.endTime) ??
    parseHistoryTime(item.payment?.createdAt) ??
    historyDate(item);

/// A server timestamp — "2026-09-12 09:30:00" or ISO 8601 — or null.
DateTime? parseHistoryTime(dynamic value) {
  final String text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') return null;
  try {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parseStrict(text);
  } on FormatException {
    return DateTime.tryParse(text)?.toLocal();
  }
}

/// One line of the list: a day header or a trip.
sealed class HistoryRow {
  const HistoryRow();
}

class HistoryDayHeader extends HistoryRow {
  const HistoryDayHeader(this.day);

  /// Midnight of the day.
  final DateTime day;
}

class HistoryTripRow extends HistoryRow {
  const HistoryTripRow(this.item);

  final DataHistory item;
}

/// [items] with a [HistoryDayHeader] before the first trip of each day. A
/// trip with no readable date stays under the header above it.
List<HistoryRow> historyRows(List<DataHistory> items) {
  final List<HistoryRow> rows = <HistoryRow>[];
  DateTime? current;
  for (final DataHistory item in items) {
    final DateTime? at = historyDate(item);
    if (at != null) {
      final DateTime day = DateTime(at.year, at.month, at.day);
      if (day != current) {
        rows.add(HistoryDayHeader(day));
        current = day;
      }
    }
    rows.add(HistoryTripRow(item));
  }
  return rows;
}

/// "Today", "Yesterday", "Mon 28 Sep", or "Mon 28 Sep 2025" for another
/// year. Day and month names follow [locale]; if that locale's date names
/// are not loaded, it falls back to digits ("28/09/2026").
String historyDayLabel(DateTime day, {required DateTime now, String? locale}) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  final int daysAgo = today.difference(day).inDays;
  if (daysAgo == 0) return 'TODAY'.tr();
  if (daysAgo == 1) return 'YESTERDAY'.tr();
  try {
    return DateFormat(
      day.year == now.year ? 'EEE d MMM' : 'EEE d MMM yyyy',
      locale,
    ).format(day);
  } catch (_) {
    return DateFormat('dd/MM/yyyy').format(day);
  }
}

/// "07:14" — digits only, so it reads the same in both languages.
String historyTime(DateTime at) => DateFormat('HH:mm').format(at);
