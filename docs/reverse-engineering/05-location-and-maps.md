# 05 — Location and Maps

**Scope:** GPS ownership, permission handling, the driver-location reporting pipeline, and every map/marker/polyline use.

**Status:** READ-ONLY. Claims carry `CONFIRMED` / `INFERRED` / `UNCLEAR — NEEDS CONFIRMATION` + `file:line`.

---

## 1. GPS ownership — `LocationService`

Single owner of the live GPS subscription (**CONFIRMED**, `services/location_service.dart:6-13` & F-05 noted in the header): previously `HomeScreen`, `BookingScreen`, `LocationBloc` and `TaxiLocation` each opened their own `Geolocator.getPositionStream` and posted independently.

- `LocationService.instance` — static singleton (`:15-17`).
- `positionStream` — broadcast `StreamController<Position>`, **does not** start the subscription itself (`:20-28`).
- `requestPermission()` — `checkPermission`/`requestPermission`; allowed = `always | whileInUse` (`:30-37`).
- `getCurrentPosition()` — `getLastKnownPosition()` first, falling back to `getCurrentPosition(timeLimit 15s, accuracy best)` (`:39-45`).
- `primeCurrentLocation()` — one-shot fetch that also `_emit`s (updates the server) so screens have a fix before the live stream ticks (`:50-56`).
- `start()` — idempotent; opens `getPositionStream(accuracy best, distanceFilter 10m)` once (`:59-67`).
- `stop()` — cancels; called on logout/unauthorized (`session_service.dart:49`, `app/alert_widget.dart:23`).
- `_emit(position)` — updates `lastPosition`, broadcasts, and `unawaited` posts `updateDriverLocationApi(lat, lng, heading)` (`:74-82`).

### 1.1 Location reporting endpoint

`data/datasources/update_driver_location_api.dart` — **CONFIRMED**: `POST /taxi-driver/update-driver-location` with `{latitude, longitude, heading}` via the legacy `BaseApiService`, returns `UpdateDriverLocationModel` (`update_driver_location_api.dart:7-29`; model `data/models/driver_location_model.dart`). Historic plaintext bearer token is commented out (`:22`).

### 1.2 Where the stream is used

- **Home** (`home/logic.dart:156-189`): `initLocation()` requests permission, `primeCurrentLocation()`, builds the map marker, then `start()` + subscribes to update the marker/camera per tick.
- **Booking** (`booking/view.dart:133-173`): `_startLocationListener()` subscribes, updates driver lat/lng/`bearing`, syncs the marker + camera (`_turnRight`), and — while `inProgress` with no destination — accumulates `totalDistanceCount` when the driver has moved ≥ `_distanceThreshold` (10 m) (`view.dart:72, 147-171`).
- **Splash** requests permission up-front (`splash_screen/logic.dart:30-33`).

### 1.3 Legacy singletons

- `taxi_single_ton/taxi.dart` (`Taxi`): `location`, `locationPermissionStatus`, `driverLocation`, `currentLocation`, `passengerLocation`, plus dead/legacy helpers `simulateTrackingDistance()` and `getRealTimePassengerLocation()` (redundant `Geolocator.getPositionStream` at `taxi.dart:110-116`) — these are not used by the current flows (**INFERRED**: no call sites besides the dead methods).
- `taxi_single_ton/taxi_location.dart` (`TaxiLocation`): `onInit()` from `main.dart:44`; pre-migration location holder (F-05 target).

---

## 2. Google Maps usage

Three `GoogleMap` instances (**CONFIRMED**):

| Screen | File:line | Purpose |
|---|---|---|
| Home tab | `home/view.dart:72-92` | Live driver map, `trafficEnabled: true`, custom driver marker, camera follows driver |
| Booking | `booking/view.dart:630-660` | Trip map: passenger/driver/destination markers, route polyline, camera follows pickup or driver by stage |
| History detail | `history_detail/view.dart:44-67` | Completed trip replay: start/end markers + stored route polyline |

Common settings: `mapType normal`, `myLocationButtonEnabled true`, `EagerGestureRecognizer` to allow gesture competition with the bottom sheet (`booking/view.dart:631-635`, `home/view.dart:73-77`).

---

## 3. Markers

`core/utils/load_custom_marker.dart` (**CONFIRMED**):

- `loadCustomMarker()` — `passenger_marker.png` at 90×90 (`:11-15`).
- `loadCustomMarkerTukTuk(typeVehicleId)` — vehicle type → iconic marker (30×50): `1=Rickshaw, 2=Classis Car, 3=Mini Van, 4=SUV, 5=Alphard VIP` (`:20-36`); assets listed in `pubspec.yaml:101-107`.

Marker placement logic on the booking screen (`booking/view.dart:511-568`): passenger marker shown from `requestReceived`; driver marker added at `enRouteToPickup`+; markers swap from passenger to destination after pickup; driver marker rotates by GPS `heading` with `flat:true`.

---

## 4. Routing (polylines) and distance

- `_drawPolylines` (`booking/view.dart:297-364`): clears, requests `PolylinePoints.getRouteBetweenCoordinates` (`TravelMode.driving`, `googleApiKey`), renders red width-5 polylines, and — when a destination exists and stage is waiting/inProgress — computes `totalDistance` + `totalFee` once (`laodCalculateDistance` flag).
- `core/utils/calculate_distance.dart` (`AsyncDistance.calculateDistance`): calls the Google Directions API and reads `routes[0].legs[0].distance.value` (meters) (`:17-22`), plus `convertDistanceToKM` / `convertSecondsToHoursMinutes`.
- History detail redraws the route with the same Directions API (`history_detail/logic.dart:80-101`, `:82` API key).

---

## 5. Reverse geocoding / addresses

- `core/helper/get_address_latlng_helper.dart` (`getAddressFromLatLng`): `placemarkFromCoordinates` forced to locale `"km"`, concatenates `name, street, subLocality, locality, postalCode, country` (`:5`).
- Used for the driver's current address, the passenger/destination place labels (`booking/view.dart:184-270`), the drop address at completion (`:267-284`), and the calculate-fee start/end addresses (`calculate_fee/logic.dart` / `view.dart`).
- **Passenger-only** street search: the app has no Places autocomplete; the driver reads pickup/destination from the request payload (`app_config.dart:46-47` notes the driver app has no Places key).

---

## 6. Camera control on the booking screen

- `_turnRight` (`booking/view.dart:575-596`): animates to a fixed zoom `19.0`, target = passenger for `requestReceived`/`enRouteToPickup`, else the driver.
- Called from the position listener (`:144`) and after delayed marker sync (`:285-290`).

---

## 7. Confidence summary

- **CONFIRMED:** single-subscription model + idempotent start, permission gating, `update-driver-location` payload, home/booking/history consumers, in-progress distance accumulation rules, marker mapping for vehicle types 1–5, Directions-API polyline approach, km-locale reverse geocoding, no Place search.
- **INFERRED:** that `convertSecondsToHoursMinutes`/duration display is cosmetic (server also returns `duration`); that the dead `Taxi` position stream helpers are indeed unused.
- **UNCLEAR — NEEDS CONFIRMATION:** whether `distanceFilter 10` is enough freshness for the broker's driver matching; whether the server accepts `heading` from `update-driver-location` (client always sends it); the accuracy/spoofing expectations of the backend (client uses `LocationAccuracy.best`).