# 04 — Realtime Architecture (Socket.IO + FCM)

**Scope:** how the driver app stays connected to the trip broker: the `SocketEvent` wire contract, connect/reconnect policy, the buffered-emit behaviour, listener wiring, and the FCM parallel channel.

**Status:** READ-ONLY. Claims carry `CONFIRMED` / `INFERRED` / `UNCLEAR — NEEDS CONFIRMATION` + `file:line`. Wire event strings and payload shapes are pinned by dedicated characterization tests (`test/taxi_single_ton/`) and were confirmed against the live server on 2026-09-07 (see `socket_event_contract_test.dart:13-16`).

---

## 1. Components

- **`services/socket_service.dart`** — `BaseSocketService` (socket lifecycle + `emitEvent`) and `DriverSocketService` singleton (register + listeners + per-event emit helpers).
- **`taxi_single_ton/taxi.dart`** — legacy `Taxi.shared` (notifications only; the old `connectAndEmitEvent` path is commented out, `ride_request_bottom_pop_widget.dart:359-366`).
- **`services/notification_logic.dart`** — FCM foreground/background/terminated handlers.
- Socket.IO server lives on the REST host under `/socket.io/`; `SOCKET_BASE_URL` default `https://taxi-api.simpledevelopertools.com` (`app_config.dart:36-39`).

---

## 2. The wire contract

`enum SocketEvent` (`socket_service.dart:14-24`) with wire strings pinned in `test/taxi_single_ton/socket_event_contract_test.dart:20-28` (**CONFIRMED** — 9 events, asserted via `.name`):

| Wire event | Direction | Used for |
|---|---|---|
| `registerDriver` | out | identifies the driver to the broker; payload = **raw driver id string**, not an object (`socket_service.dart:122-124`, `socket_emit_contract_test.dart:56-62`) |
| `newRide` | **in** | a ride request arrives → open `/booking` (`socket_service.dart:150-169`) |
| `acceptRide` | out | after `confirm-drive-request` succeeds (`socket_service.dart:278-300`) |
| `rideArrival` | out | after `drive-arrive` succeeds; identified by `booking_code` **only** (`socket_service.dart:186-199`) |
| `startDrive` | out | after `start-drive` succeeds (`socket_service.dart:217-238`) |
| `dropDrive` | out | after `complete-drive` succeeds; same shape as `startDrive` (`socket_service.dart:240-261`, mirrored in `socket_emit_contract_test.dart:182-204`) |
| `acceptPayment` | out | after `accept-payment` REST succeeds (`socket_service.dart:263-276`) |
| `driverCancelDrive` | out | driver cancels a pending request (`socket_service.dart:201-214`) |
| `onPassengerCancelDrive` | **in** | passenger cancelled → dialog + home (`socket_service.dart:172-184`) |

**Important naming facts (pinned by tests):**
- The passenger-cancel listener keeps the `on` prefix. `passengerCancelDrive` (no `on`) is the *passenger's outbound* event and is **not** the one the driver listens to — the old typo `passangerCancelDrive` was dead code that never matched the wire (F-01, `socket_event_contract_test.dart:37-46`; `socket_service.dart:11-13`).
- The listener-flag removal (F-03) is why the two `_socket?.on(...)` listeners for `newRide` and `onPassengerCancelDrive` are attached freshly inside `connectToSocket` after every reconnect (`socket_service.dart:137-147`).

---

## 3. Connect / register lifecycle

- **Entry points:** `home/logic.dart:122-132` (after first frame, `home/view.dart:35`) and `booking/view.dart:110-120` — both read `StorageGet.getDriverData().data.driver.id` and call `connectToSocket(socketBaseUrl, driverId, "Driver", context)`.
- **`DriverSocketService.connectToSocket` (**`socket_service.dart:126-147`):** re-entrancy guard — if already connected, skip; otherwise build a fresh socket, attach listeners, register. This replaced a one-shot `_listenersSetup` flag that left every post-reconnect socket deaf (comment `:138-144`).
- **`register(id)`** emits `registerDriver` with the raw id (`:122-124`).
- Logging on connect/error/disconnect via `tlog` (`:52-63`).

---

## 4. Reconnection policy (F-03)

`buildSocketOptions()` (`socket_service.dart:36-42`), pinned in `socket_emit_contract_test.dart:36-54` (**CONFIRMED**):

- Transport: `websocket` only (matches the server probe, `:37-39`).
- `enableAutoConnect` + `enableReconnection`.
- Reconnect delay backs off `2000ms → 30000ms` (`:41-43`, replacing a flat 60s).
- **No `reconnectionAttempts` cap.** The absence of the key is load-bearing: the old `setReconnectionAttempts(10)` gave up permanently after ~10 minutes offline and the app went deaf mid-trip; the client's default infinite retries apply only while the key is absent (`comment :26-34`; test asserts absence `:46-53`).

---

## 5. Emit behaviour (buffering on disconnect)

`emitEvent` (`socket_service.dart:85-98`) — **CONFIRMED**:

- Only fails if `_socket` was never created (`:86-90`); otherwise queues the emit through `Socket.emit`, letting Socket.IO buffer it and flush on reconnect (`emitBuffered`).
- The old guard (`if (!connected) log + return`) permanently dropped `startDrive`, `acceptPayment`, `driverCancelDrive`, `acceptRide` on any blip — the exact events that carry trip state and money (comment `:68-84`).
- Logs whether the event was sent live or buffered (`:93-97`).

Payload inconsistencies are *characterized, not fixed* (**CONFIRMED**, `socket_emit_contract_test.dart`):
- `acceptRide` stringifies coordinates (`"11.5564"`) while `startDrive` sends numbers (`11.5564`) (`:117-136`).
- A missing `acceptRide` destination sends the literal string `"null"` (`:138-155`).
- `arrivedSocket`/`rideArrival` omits `booking_id` entirely — the only trip-state emit keyed by `booking_code` alone (`:163-180`).
- `acceptPayment` has an asymmetric `.toString()` on `booking_code` (already a String) while `booking_id` passes through raw (`:94-113`).

---

## 6. Inbound handling

Two listeners (`socket_service.dart:150-184`), both attached per-connection by `connectToSocket`:

1. **`newRide`:** parse via `parseNewRideArgs` (D-05, `features/trip/data/new_ride_payload_parser.dart:34-61`); on success `Get.toNamed('/booking', arguments)`. On parse failure the ride is *not* silently dropped — `Taxi.shared.notifyBooking(...)` still fires ("NEWREQUEST"/"DESREQUEST") so the driver knows a request arrived (`:161-168`).
2. **`onPassengerCancelDrive`:** `AlertWidget().cancelBooking(context)` → 10s auto-dismiss dialog ("BOOKINGS_CANCELED"/"PASSENGER_CANCEL"), returns to home (`:172-184`; `app/alert_widget.dart:33-49`; `presentation/widgets/cancel_book_dialog_widget.dart`).

Notification helper `Taxi.shared.notifyBooking(...)` (`taxi.dart:69-82`) plays `booking_sound.wav` via `flutter_local_notifications`.

---

## 7. FCM parallel channel

`services/notification_logic.dart` (**CONFIRMED**):

- Setup in `main.dart:25` → `setupInteractedMessage()` = `Firebase.initializeApp()` + `registerNotification()` (channel `"booking_channel"`, sound `booking_sound`, importance max) + iOS foreground-banner options off (`notification_logic.dart:15-20, 24-31, 137-152`).
- **Foreground** messages: `FlutterFirebaseMessaging.onMessage` — ignored *only* for `notification_type == 'service_booking'` (booking is pushed out-of-process by the socket at `socket_service.dart:165-168`); others routed via `handleOnNotificationPress` → `routeByNotificationTime(..., 1)` (`:35-44`).
- **Background/terminated:** `onMessageOpenedApp` (`durationRoute:6`) and `getInitialMessage` (`isTerminate: true` → 2s delay then return so the home screen handles it) (`:47-63`; `routeByNotificationTime` at `:200-235`).
- `routeByNotificationTime`: `service_booking` → `parseNewRideArgs(message.data)` (FCM strings) → `/booking`; anything else → `/notification-detail` with `NotificationDetailArgs(notification_id, appOpened)` (`:209-233`).
- Local-notification tap handler also routes via `handleOnNotificationPress` (`:173-179`).
- `NotificationLogic` guards the previous bug where *every* non-booking notification crashed the JSON-decode branch — the parser is now self-guarding (`:210-216`).

FCM payload shape = same fields as the socket but JSON-encoded under `passenger`/`location`/`destination`; the D-05 parser accepts both (**CONFIRMED**, `new_ride_payload_parser.dart:65-78`).

---

## 8. Post-render listeners on the booking screen

The booking view re-registers the socket (`booking/view.dart:110-120`) and reacts to trip results with the outbound emits (full map in doc 03 §3.1): `acceptRide` on `TripAccepted`, `rideArrival` on `TripArrived`, `startDrive` on `TripStarted`, `dropDrive` on `TripCompleted`, and `acceptPayment` from the calculate-fee logic (`calculate_fee/logic.dart:68-77`) (**CONFIRMED**).

---

## 9. Confidence summary

- **CONFIRMED:** the 9-event wire contract (test-pinned + live probe), websocket transport, infinite-reconnect backoff policy, buffered emits, listener re-attachment per connect, the two inbound handlers, FCM routing incl. `service_booking`, the cross-channel parser.
- **INFERRED:** that `newRide`/`onPassengerCancelDrive` are the *only* inbound events the broker needs to deliver to the driver (nothing else has a `_socket.on`).
- **UNCLEAR — NEEDS CONFIRMATION:** whether the server re-sends `newRide` for a same driver on reconnect (relies on buffer rather than resend); the exact server-side event names for passenger→driver `acceptRide` confirmation (client never listens for one); whether `registerDriver` must be re-emitted after reconnection broadcasts (it is: `onConnect → register`, `socket_service.dart:52-55`).