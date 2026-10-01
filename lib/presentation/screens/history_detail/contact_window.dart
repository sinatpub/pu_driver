/// DD-42 — how long after a trip the driver may call the passenger directly,
/// for an item left behind. After it, contact goes through support.
const Duration passengerCallWindow = Duration(hours: 24);

/// Whether the trip detail offers "Call passenger".
///
/// Needs a phone number and a known end time: with no end time there is no
/// way to tell how old the trip is, so the safe answer is no. A trip that
/// "ended in the future" (a clock a little off) counts as just ended.
bool canCallPassenger({
  required DateTime? endedAt,
  required String? phone,
  required DateTime now,
}) {
  if (endedAt == null || phone == null || phone.trim().isEmpty) return false;
  return now.difference(endedAt) < passengerCallWindow;
}
