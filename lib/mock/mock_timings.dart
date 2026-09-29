/// Every delay the mock backend uses, in one place. Edit these to change the
/// pace of the simulation; the dev panel's speed multiplier (1x/2x/5x/10x)
/// divides all of them except [gpsTick] and [rideRequestTimeoutSeconds].
///
/// Trip time is compressed on purpose: a 10 km ride plays out in under a
/// minute at 1x. The *receipt* still reports a realistic city duration
/// (see [assumedCitySpeedKmh]) so copy and layout are tested with real-world
/// values, not "0 m 45 s".
class MockTimings {
  MockTimings._();

  // ---- Network latency (so spinners, disabled buttons and skeletons show) --
  static const Duration latency = Duration(milliseconds: 700);
  static const Duration authLatency = Duration(milliseconds: 1200);
  static const Duration tripActionLatency = Duration(milliseconds: 1000);
  static const Duration paymentLatency = Duration(milliseconds: 1500);

  /// Latency never drops below this, even at 10x, so loading states are
  /// still visible for at least a frame or two.
  static const Duration minLatency = Duration(milliseconds: 150);

  // ---- Server-side simulation ---------------------------------------------
  /// Going online (or finishing a ride) → the next ride request arrives.
  static const Duration rideRequestAfterOnline = Duration(seconds: 5);

  /// Accepted → driver reaches the pickup (GPS travel time).
  static const Duration driveToPickup = Duration(seconds: 20);

  /// Trip started → driver reaches the destination (GPS travel time).
  static const Duration tripInProgress = Duration(seconds: 45);

  /// `PASSENGER_CANCELLED`: accepted → passenger cancels.
  static const Duration passengerCancelsAfterAccept = Duration(seconds: 8);

  // ---- Not scaled by simulation speed -------------------------------------
  /// How often the simulated GPS reports a position.
  static const Duration gpsTick = Duration(seconds: 1);

  /// The request countdown on the ride-request sheet (`timeout` field).
  static const int rideRequestTimeoutSeconds = 30;

  /// Used for the realistic trip duration on the receipt and in history.
  static const double assumedCitySpeedKmh = 22;
}
