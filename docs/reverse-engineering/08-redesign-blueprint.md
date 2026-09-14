# 08 — Red Flags and Redesign Blueprint

**Scope:** weaknesses (technical and UX) evidenced this session, and a prioritized redesign blueprint for the `pu_driver` app.

**Status:** READ-ONLY. Findings carry `CONFIRMED` / `INFERRED` / `UNCLEAR — NEEDS CONFIRMATION` + `file:line`. This is a *blueprint*, not a change order — nothing here has been implemented.

---

## 1. Red flags (evidence-backed)

### 1.1 Realtime & money-in-transit
- **R1. Socket emit asymmetry (trip-state events)**: `acceptRide` stringifies coordinates, `startDrive`/`dropDrive` send numbers, and a missing destination ships the literal string `"null"` — all characterized, not fixed (`test/taxi_single_ton/socket_emit_contract_test.dart:117-155`). Server accepted these in the live probe, but the wire is fragile by construction. **CONFIRMED**.
- **R2. `rideArrival` keyed by `booking_code` alone** — the only trip-state emit without `booking_id` (`socket_emit_contract_test.dart:163-180`); typos in that string are unguarded by any compile check. **CONFIRMED**.
- **R3. Payment happens before any socket ACK.** `accept-payment` REST → `acceptPayment` emit → navigate home, with no inbound confirmation that the emit was delivered (the app relies on Socket.IO buffering, `socket_service.dart:85-98`). **CONFIRMED** (behaviour) / **INFERRED** (risk).

### 1.2 State & navigation
- **R4. Resume routing maps unknown statuses to `enRouteToPickup`** — `cancel`(5)/`completed`(4/7) fall through to the same branch (documented quirk M-21, `home/logic.dart:265-277`). A driver landing on a cancelled trip sees the driving-to-passenger UI. **CONFIRMED**.
- **R5. Booking-stage ints 0–6 with `5` unused** (`trip_state_machine.dart:19-20`) and a duplicate "completed" (`4` vs `7`, `booking_status.dart:19-24`) — both awaiting backend clarification; a schema drift here breaks resume silently. **CONFIRMED** / **UNCLEAR** with backend.
- **R6. Screen-local mutable routing state** (`latDriver/lngDriver/refreshApp` on `_BookingScreenState`) is thinner than the old 21-mutable-fields widget but still bleeds into map logic (`booking/view.dart:59-102`). **CONFIRMED** (improvement, residual).
- **R7. No BLoC leftovers, but hybrid GetX + service singletons + legacy `Taxi`/`TaxiLocation` coexist** (F-05 migration partially landed). **CONFIRMED**.

### 1.3 Data correctness
- **R8. Fare shown to the driver mid-trip is *client-estimated*** (`estimateFare`, `fare_estimate.dart:14-15`); the server recomputes at `complete-drive` and the calculate-fee screen shows the server value (`calculate_fee/view.dart:71-72`). Discrepancy between the two is today accepted, not reconciled. **CONFIRMED**.
- **R9. Distance accumulation without a destination is a UI float-sum** with a 10 m threshold, not odometer-authoritative (`booking/view.dart:147-171`). **CONFIRMED**.
- **R10. Legacy `register_data` blob remains the original token store** with a one-time migration bridge (`session_service.dart:29-35`) — drift risk until fully drained. **CONFIRMED**.

### 1.4 UX problems observed in source
- **U1. No rating anywhere on the driver app** — `profile_header_widget.dart:42-85` shows no rating, `set_status_model.dart` has a `rating` field (`:31`) but nothing surfaces it. **CONFIRMED**.
- **U2. No earnings/balance summary for drivers** — wallet shows balance + commission + transactions (`wallet/view.dart:76-96`), but the earnings domain (`features/earnings/domain/earnings.dart`) is pure scaffolding with no backend and no screen. **CONFIRMED**.
- **U3. Booking screen `PopScope(canPop:false)` traps the driver** with no secondary escape (cancel only offered pre-accept); an in-progress trip can only be left by completing or killing the app (`booking/view.dart:623-624`). **CONFIRMED**.
- **U4. Progress was previously driven by blind timers** (`Future.delayed(...processStepBook=N)`) so the UI could advance without server truth — now fixed in `TripStateMachine` (`trip_state_machine.dart:8-14`), but the resume path (`R4`) still reintroduces drift. **CONFIRMED**.
- **U5. Drawer logout is disabled in UI** while the backend session continues (`drawer/view.dart:252-298`); `wpired` 401 handling covers auth failure but the user-facing gap is a brand/runtime decision. **CONFIRMED**.
- **U6. `font10SemiBold` renders at 14.0** — an obvious token bug (`text_styles.dart:17-62`). **CONFIRMED**.
- **U7. Driver marker/camera zoom hardcoded 19.0** and fairly aggressive re-centring (every GPS tick `booking/view.dart:144, 575-596`) — likely distracting while driving. **CONFIRMED** / **INFERRED** (impact).
- **U8. No passenger/driver route-preference UX** (no fares preview before accept; price comes from the request payload only). **INFERRED** from feature absence.

---

## 2. Redesign blueprint (prioritized)

**P0 — Reliability/money (do first; silent corruption today):**
1. _Harden the wire contract._ Standardize coordinate encoding (numbers everywhere), stop shipping `"null"` destinations, and add `booking_id` to `rideArrival`. Enforce with the existing characterization tests (`socket_emit_contract_test.dart`).
2. _Reconcile fare display._ Replace client-entid `estimateFare` on the trip screen with the server-authoritative price where available, or visibly mark the estimate; never let a dead float diverge at payment time.
3. _Remove the status-int ambiguity._ Resolve `7` vs `4`, and make resume routing raise/fail explicitly for `cancel`/`completed` instead of spawning `enRouteToPickup` (`home/logic.dart:268-277`).

**P1 — Driver day-to-day confidence:**
4. _Add an earnings surface._ Wire `features/earnings/domain` to `history-drive-info`/`wallet` data; move the pure domain to a real screen (today + week + month + all-time, net-of-commission toggle).
5. _Surface rating._ Show driver rating in the profile header + a monthly rating trend using the already-present `rating` field (`set_status_model.dart:31`).
6. _Re-enable / redesign logout_ (currently commented out) and add an "end trip / contact support" escape on the booking screen for at-pickup/at-passenger edge cases.

**P2 — UX polish:**
7. _Calm the map:_ gentler camera behaviour (animate on significant change only), configurable zoom, distance-aware views instead of every-tick re-centre.
8. _Fix token table_ (`font10SemiBold`), complete `km.json` coverage, and add a smoke check that no screen mixes `ThemeConstands` and `AppTextStyles`.
9. _Approval-status UX:_ distinct pending/rejected states with an explanation + support path (currently a single red overlay).
10. _Wallet UX:_ clarify commission-fare vs balance card meaning; add pull-to-refresh + total-transaction summary.

**P3 — Architecture debt (already mid-flight):**
11. Finish the `BaseApiService → ApiClient/Result` migration (persistent references to a now-absent `confirm_booking_api.dart` in `trip_datasource.dart:7-8`), drain the legacy `register_data` token path, and retire the dead `Taxi` GPS helpers (`taxi.dart:91-131`).

---

## 3. Open questions for stakeholders
- Q1: booking-status `7` semantics (`booking_status.dart:19-24`); driver approval `0/1/2` mapping server-side (`app/state.dart:4-9`).
- Q2: intended earnings/referral scope — is a backend planned, or are they speculative domain scaffolds (`features/earnings`, `features/referral`)?
- Q3: should `CHANNEL` (announcements) become a drawer tab again (`drawer/view.dart:202-218`)?
- Q4: what is the expected multi-flavour / staging story (deferred pending Q-12/Q-13, `app_config.dart:8-12`)?

---

## 4. Confidence summary
- All R1–R10 and U1–U8 findings are source-backed and marked. Redesign items are proposals; their sequencing (P0>P1>P2>P3) is an editorial recommendation, not a committed plan. **UNCLEAR** items flagged per section.