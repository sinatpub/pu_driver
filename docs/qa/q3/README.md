# Q3 — Performance review

Generated 2026-09-15. Deterministic reactive-behaviour measurements for the
trip and home map screens, run under the widget-test binding
(`test/qa/performance_review_test.dart`); the roadmap's on-device numbers are
recorded as carry-over.

> Roadmap target (`docs/roadmap.md` §Q3): *"No sustained jank above 16 ms on
> the trip screen, and memory is stable across a full trip."*
>
> This environment has **no reachable backend** (`api.tara-taxi.com` and
> `socket.tara-taxi.com` time out on TLS) and **no attached device**, so the
> roadmap's literal method (DevTools on a mid-range Android, panning the map
> with the sheet open) cannot run here. What is deterministic in a widget test
> is measured and captured; everything that needs a real map rasterizer or a
> real GPS/service is listed under **Device carry-over**.

---

## Method

`test/qa/performance_review_test.dart` — 6 tests, 3 groups.

| Group | What is measured |
|---|---|
| Trip screen — per-tick reactive work | The GPS listener's work from `booking/view.dart` (`_startLocationListener`), replayed on the **real** overlay widgets (`TripHeader`, `SmoothCircularCountdown`, `ModelBottomSheetNewRequestWidget`) composed exactly as the screen composes them inside the Stack — the `GoogleMap` platform view is stood in by a plain coloured layer because the widget-test binding cannot rasterise platform views. Counts the whole-overlay rebuild per `setState`, per tick. |
| Trip lifecycle | A full legal `TripStateMachine` walk, and `LocationService`'s single-subscription idempotence / cancel-on-stop against a fake geolocator platform. |
| Home map — marker churn | `HomeState` driven exactly like `HomeLogic.initLocation`'s listener (`updateMarker` + `currentLocation` + camera), counting marker-set growth per GPS tick. |

Capture: `artifacts/performance_review_<timestamp>.json` (machine-readable,
written by the harness) and the summary below. Script geometry: positions
advance ~11 m per tick (above geolocator's `distanceFilter: 10`), six ticks a
second, `heading` rotating.

---

## Findings

### Trip screen — one whole-screen rebuild per GPS tick (measured)

| Metric | Value |
|---|---|
| Position ticks scripted | 60 |
| Whole-overlay `setState` rebuilds | **60** (1 per tick) |
| Camera animations (`_turnRight` → `animateCamera`, zoom 19) | **60** (1 per tick) — B12 |
| Reverse-geocode calls (`syncMarker` → `getAddressFromLatLng`) | **60** (1 per tick) |
| In-progress distance/fare branch (no-destination trip, ≥ 10 m) | 59 |
| 1 s meter timer rebuilds over 5 s | 5 |

Every `setState` rebuilds the **whole** `Stack` — the map plus every overlay —
once. There are three such rebuild sources on the trip screen: the GPS
listener (every tick), the 1 s meter timer (`startTimer`), and the map camera
`onCameraMove` callback (`booking/view.dart:717`). `WidgetsBinding
.addTimingsCallback` does not fire under the widget-test binding (verified
empirically), so the **raster cost** of each whole-screen rebuild — and the
16 ms gate — is device-measured. The per-tick storm is pre-existing
(`/home`'s `Transition.noTransition` and this listener predate the redesign)
and is reported, not fixed, per the roadmap.

### Home map — the marker set grows unboundedly while idling (measured)

| Metric | Value |
|---|---|
| GPS ticks scripted | 120 |
| `state.markers` after 120 ticks | **120 distinct `Marker`s, 1 distinct `MarkerId`** |
| `currentLocation` notifications per tick | 120 |
| Camera animations per tick | 120 |
| Set growth with no positions arriving | 0 |

`HomeLogic.updateMarker` (`home/logic.dart:191`) does `state.markers.add(
Marker(...))` with the constant id `driverMarker` but a new position/rotation
each tick. `Marker.==` includes `position` and `rotation`, so every tick adds
a **distinct** element — the `RxSet` grows one per tick forever while the app
is idle on `/home`, and `markers: logic.state.markers.toSet()` re-diffs the
full set through `Obx` on every notification. Each tick also runs
`loadCustomMarkerTukTuk` (an asset decode) again. This is the "memory stable
across a full trip" risk on the home side; the growth is bounded only by time
online. Finding recorded, not fixed, per the roadmap.

### Trip lifecycle / GPS hygiene — PASS (measured)

| Metric | Value |
|---|---|
| Legal stage walk | `requestReceived → enRouteToPickup → waitingAtPickup → inProgress → completing` |
| Geolocator streams for two `LocationService.start()` calls | **1** (idempotent) |
| Streams adopted after `stop()` + fresh `start()` | 1 |
| Cancels recorded on `stop()` | 2 |

`LocationService` keeps exactly one live GPS subscription even when several
screens call `start()` (F-05), and `stop()` releases it. Position ingestion
itself is recorded as device carry-over because `_emit` posts to
`update-driver-location` through a `late dio` that the test binding must not
construct.

---

## Device carry-over (Q3's on-device numbers)

These need the roadmap's mid-range Android + a live backend/OTP login; they
are what `IMPLEMENTATION_PROGRESS.md` treats as recorded-per-task rather than
done here:

- **Frame timings while panning the map with the sheet open** — GPU/raster
  frame times above 0 are unavailable under `AutomatedTestWidgetsFlutterBinding`
  (no real rasterizer). The 16 ms gate on the trip screen is the unmeasured
  half of Q3's Done When.
- **Raster cost of the whole-screen rebuild per GPS tick** on a mid-range
  Android — the trip listener and meter timer fire the same `setState`
  structure measured above; only the pixel cost is missing.
- **Real-pan smoothness** on `/home` with the marker set growing — confirms
  how early the unbounded marker accumulation starts to bite.
- **`LocationService` ingestion** (dio → `update-driver-location`) once per
  emitted position.

## Decision log

- **`Q3-01`** — Map-screen rebuild storms are measured here at the reactive
  level (rebuilds/notifications/camera/geocode per tick) and left unfixed, as
  the roadmap instructs. Separate fixes (e.g. marker-set churn on `/home`)
  belong in their own PRs with their own tests.
- **`Q3-02`** — The `GoogleMap` platform view in the harness is replaced by a
  flat coloured layer; the overlay composition is otherwise byte-for-byte the
  screen's Stack. Pixel/GPU effects of the map itself are device-measured.