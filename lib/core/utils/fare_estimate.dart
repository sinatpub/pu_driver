/// D-07 (docs/12) — `booking_screen.dart` had two on-screen fare formulas:
/// one over GPS-accumulated meters (used while the passenger set no
/// destination), one over a Google Directions km figure (used when they
/// did). Both did the same arithmetic on different units. Collapsed here
/// so the two call sites differ only in how they arrive at `distanceKm`.
///
/// Display-only: the server recomputes the billed fare on `complete-drive`
/// and ignores whatever distance/fare the client sends (Q-2, `docs/13`).
double estimateFare({
  required double distanceKm,
  required int pricePerKm,
  required int minimumFare,
}) {
  if (distanceKm <= 1.0) return minimumFare.toDouble();
  return (distanceKm - 1.0) * pricePerKm + minimumFare;
}
