# QA Mock / Demo Mode (driver app)

A fake backend that lets the **whole driver flow** run with no API, no socket
server and no GPS, so the existing UI can be tested and polished while the
backend is unavailable. No screen was changed to support it, and the real API
code is untouched and still the default.

## Turn it on / off

```sh
# on — debug (or profile) build only
fvm flutter run --dart-define-from-file=dart_defines.json --dart-define=USE_MOCK_DATA=true

# optional: start in a scenario and/or at a speed
fvm flutter run --dart-define-from-file=dart_defines.json \
  --dart-define=USE_MOCK_DATA=true \
  --dart-define=MOCK_SCENARIO=PAYMENT_FAILED \
  --dart-define=MOCK_SPEED=5

# off — just leave USE_MOCK_DATA out (the normal command)
fvm flutter run --dart-define-from-file=dart_defines.json
```

In Android Studio, pick the **dev | mock** run configuration
(`.run/dev _ mock.run.xml`). It runs the first command above. To start in a
scenario or at a speed, add the extra `--dart-define`s under
**Edit Configurations → Additional run args**.

A red **MOCK** tab on the left edge of every screen shows mock mode is on.
Tap it to open the developer controls.

**It can't reach production.** `MockMode.enabled` is the compile-time constant
`USE_MOCK_DATA && !kReleaseMode`. In a `--release` build it is `false` even if
the define is passed, every mock branch is dead code, and the mock layer is
tree-shaken out. `USE_MOCK_DATA` is deliberately not in
`dart_defines.example.json`, for the same reason `DEBUG_OTP_BYPASS` isn't.

Inside a mock build, **Use mock backend** in the panel turns mock mode off at
runtime (after restarting the app), so one install can talk to either backend.

## Developer controls (MOCK tab)

| Control | Values | Effect |
|---|---|---|
| Send ride request | button | Dispatches a request now (replaces a pending one; never interrupts a trip) |
| Passenger cancels | button | Pushes `onPassengerCancelDrive` for the current ride |
| Reset trip | button | Drops the current ride; keeps history/wallet/online |
| Reset all mock data | button | Offline, no ride, re-seeded history and wallet |
| Scenario | see below | Backend behaviour |
| Simulation speed | 1x · 2x · 5x · 10x | Divides every delay in `MockTimings` |
| Ride requests | Auto · Manual | Auto: a request arrives a few seconds after going online / finishing a ride |
| Passenger pays with | Cash · Wallet · Card | `payment_method` on the receipt and in history; wallet entry type |
| Driver approval | Approved · Pending · Rejected | `driver.status` → the approval gate (applies next time Home loads) |
| Ride has a destination | on/off | Off: no route; the trip screen runs its live distance/fare meter |
| Use mock backend | on/off | Runtime kill switch, applies after restart |

Settings persist across restarts. A `MOCK_SCENARIO` / `MOCK_SPEED` define
wins over the saved value at launch.

## Scenarios

The QA brief described the passenger flow. This is the driver app, so each
scenario is the driver-side equivalent.

| `MOCK_SCENARIO` | What happens | Driver-side equivalent of |
|---|---|---|
| `NORMAL_FLOW` | Everything succeeds | NORMAL_FLOW |
| `NO_RIDE_REQUEST` | Online, but no request is ever dispatched automatically | NO_DRIVER_AVAILABLE |
| `RIDE_ALREADY_TAKEN` | Accept → `RIDE_ALREADY_ACCEPTED` dialog | (driver-only) |
| `BOOKING_FAILED` | Accept → "can't confirm" dialog; request stays open for retry | BOOKING_FAILED |
| `PASSENGER_CANCELLED` | Passenger cancels a few seconds after accept | DRIVER_CANCELLED |
| `PAYMENT_FAILED` | Collect payment → 500 → error dialog; retry works once switched back | PAYMENT_FAILED |
| `NETWORK_ERROR` | Every request fails as a dropped connection | NETWORK_ERROR |
| `SESSION_EXPIRED` | Every authenticated request → 401 → signed out | (extra) |
| `LOCATION_ERROR` | GPS never returns a fix → Home's location error state | LOCATION_ERROR |

Also available regardless of scenario:
- OTP **`9999`** is rejected (wrong-code dialog). Any other code signs in as
  **Dara Sok** (Toyota Prius, white, 2AB-1234).

## The flow and its timings

All delays live in **`lib/mock/mock_timings.dart`**, and the speed setting
divides them.

```
Splash → Login (any phone) → OTP (any code but 9999)       auth latency 1.2 s
Home → toggle Online                                        latency 0.7 s
  ↓ rideRequestAfterOnline            5 s
Ride request sheet (30 s countdown, not scaled)
  → Accept                                                  trip action 1.0 s
Go to pickup — car drives Wat Phnom → Central Market
  ↓ driveToPickup                    20 s
  → Arrived
At pickup
  → Start trip
On trip — car drives Central Market → Airport (≈10 km), timer runs,
          meter updates (no-destination rides)
  ↓ tripInProgress                   45 s
  → Drop off
Collect payment receipt (distance, realistic duration, fare in riel, method)
  → Payment done                                            payment 1.5 s
Home (history + wallet updated; next request in 5 s if Auto)
```

The driver still taps each trip action (Accept, Arrived, Start, Drop off,
Payment done). Those buttons *are* the UI under test, so the simulation
doesn't press them. What runs on its own is everything the server,
passenger and GPS would do.

Trip time is compressed. The receipt reports the realistic duration for the
distance at 22 km/h, not the ~45 s it took in the simulator.

**Mock data is easy to spot:** ride ids and booking codes start at `990001`
(the app parses them as integers, so a `MOCK-` prefix isn't possible). The
seeded history uses `980001+`, and the token is `mock-token-qa-only`.

## Persistence (kill and relaunch)

The mock backend saves its state to SharedPreferences after every change
(online flag, ride and its phase timestamps, history, wallet). Relaunching the
app goes through the app's **real** resume path: `get-current-drive-info`
returns the ride, and Home redirects into the trip screen at the right stage
(or to Collect Payment if the drop-off already happened). The simulated car
position is recomputed from the phase timestamps, so it has moved on while the
app was closed. A request that was never accepted is dropped on relaunch, as
the server would have expired it.

## Architecture

```
Screens / controllers / repositories / datasources / models   ← unchanged
        │                    │                 │              │
   BaseHttpClient.dio   DriverSocketService  LocationService  RouteService
        │                    │                 │              │
 MockHttpInterceptor    mock event stream  MockLocationSource MockRouteProvider
        └────────────── MockBackend (lib/mock/mock_backend.dart) ─┘
```

- **REST**: `MockHttpInterceptor` on the shared Dio client answers from
  `MockBackend`. Both HTTP stacks (`ApiClient`, legacy `BaseApiService`) use
  that client, so every model parses mock JSON exactly as it parses the real
  API. Errors are real `DioException`s (connection / bad response), so the
  app's own error mapping runs.
- **Socket**: in mock mode `DriverSocketService` subscribes to
  `MockBackend.socketEvents` instead of opening Socket.IO. `newRide` and
  `onPassengerCancelDrive` go into the same handlers as the real events.
  Outgoing emits are logged, not sent.
- **GPS**: `LocationService.source` is a `PositionSource`. Normally it's
  `GeolocatorPositionSource`; the mock source follows the ride's phase.
- **Directions**: `RouteService.provider` is Google normally. The mock
  provider returns the same route the simulated car drives.
- **Addresses**: known mock landmarks resolve to fixed names. Anything else
  falls through to the platform geocoder.
- **Map**: still the real Google Map (needs `GOOGLE_MAPS_API_KEY` for tiles).
  Only its data is mocked.

To remove mock mode entirely: delete `lib/mock/`, `test/mock/` and this file.
Then drop the `MockMode` lines from `main.dart`, `app/root_main.dart`,
`core/api_service/client/dio_http_client.dart`,
`core/helper/get_address_latlng_helper.dart` and `services/socket_service.dart`.
The `PositionSource` and `RouteService` seams are ordinary code and can stay.

## Known limits

- **Not simulated because the driver app has no such screen or data:** passenger-side
  steps (choosing pickup/destination, vehicle type, fare estimate before
  booking), payment-method *selection* (the driver only collects), rating or
  review, tips, and a remaining-distance or ETA readout during the trip.
- **Registration** (`/register`) returns a signed-in approved driver.
  Because mock OTP never reports a new driver, the register screen is only
  reachable by navigating to it directly.
- **Push notifications (FCM)** are not mocked. The ride request comes through
  the socket path, which is what the app uses while in the foreground.
- **App update prompt** is not simulated (the version endpoint matches the
  build).
- **Telegram error reporting** still calls Telegram if its token is set.
- **Map tiles** need a valid Google Maps key and a network connection.
