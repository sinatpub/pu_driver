# 06 — Implementation Plan

**What this is:** a sequence for a future implementation agent. No code has been written. Paths are relative to `lib/` unless noted.

## Ground rules (from `../.agent/RULES.md` and this analysis)

- **One screen (or one shared layer) per change.**
  - Never mix redesign with architecture, migration or new behaviour (RULES, "Anti-goals").
  - Behavioural issues found here are listed in §4 and go into **separate** changes.
- **Visual-only diffs.** Controllers, datasources, services, routes, route args and bindings stay untouched. Where a view must read one more existing `Rx` value (e.g. `isLoading` into the sheet), that's allowed; new logic isn't.
- **Light theme, installed once** (DD-34):
  - The app is already light, so the new `ThemeData` is installed in step 1 and screens migrate under it.
  - No per-route theme wrappers are needed.
- **Verification bar:**
  - `dart analyze <path>` must be clean. Plain `flutter analyze` is broken in this environment (RULES).
  - The existing tests stay green where they can run. `flutter test` can't run locally (`docs/reverse-engineering/01 §10`), so run it in CI or on a machine with `flutter_tester`.
  - Check behaviour on a real device against the step-0 baseline (Definition of Done).
- **Branch naming:** `refactor/<id>-<short-name>` (RULES). Suggested ids: `UX-00` … `UX-16`.

---

## 1. Sequence

### Step 0 — Pre-flight (no code)
- **Goal:** unblock decisions and capture a baseline to compare against.
- **Docs:** `07` (OPEN items), `05 §11`.
- **Actions:**
  - Get sign-off on DD-02 (action colour), DD-05 (logout), DD-13 (drop confirmation), DD-33 (error-dialog semantics), and the brand logo asset.
  - Record a device video of every screen and state in `05 §1–§4`.
  - Capture the `tlog` output of one full trip (request → payment) as the **socket-emit oracle**.
- **Files:** none.
- **Dependencies:** none.
- **Risk:** skipping this leaves regressions undetectable.
- **Verification:** the baseline artefacts exist and are linked in the tracking issue.

### Step 1 — Design foundation (P0)
- **Goal:** tokens, a light `ThemeData`, the type scale with Khmer line heights, the icon set, a themed EasyLoading.
- **Docs:** `02` (all), DD-01/02/03/28/30/34.
- **Files:**
  - `core/theme/{colors,text_styles,app_theme}.dart`, plus a new `core/theme/tokens.dart` (ThemeExtension).
  - `main.dart` `configLoading` (`:60-74`).
  - New assets: `assets/icon/ds/*.svg` (pubspec **asset lines only**; no packages).
- **Dependencies:** step 0 sign-offs DD-01/02.
- **Risk:** medium. The font-weight registration (O-2) and tabular figures (O-1) may force fallbacks.
- **Verification:**
  - A small pure-Dart test that asserts the contrast ratios in `02 §1.1` (optional, recommended).
  - A token sampler page, run in debug only, on a device in EN and KM.

### Step 2 — Shared components (P0)
- **Goal:** build the A-tier components from `04`, and re-skin the existing dialog functions without changing their signatures.
- **Docs:** `04 A`, `02 §7–§13`.
- **Files:**
  - New `presentation/widgets/ds/*`.
  - Re-skin in place: `presentation/widgets/{yesno_dialog_widget,error_dialog_widget,cancel_book_dialog_widget,process_book_dialog_widget,simmer_widget}.dart`.
- **Dependencies:** step 1.
- **Risk:** **high for the dialogs.** `showErrorCustomDialog`'s double pop (DD-33) and `showCancelBookingDialog`'s timer must survive byte-for-byte in behaviour.
- **Verification:**
  - Widget tests per component (states).
  - For each dialog: trigger it on a device and compare the navigation with the baseline.

### Step 3 — Shell (P1)
- **Goal:** app bar, `DriverDrawer`, `OnlineStatusPill`, `ApprovalGate`, `OfflineBanner`.
- **Docs:** `03 S05`, `04 B`, DD-05/06/08/09/26.
- **Files:** `presentation/screens/drawer/view.dart`, `home/widgets/switch_online_widget.dart`, `profile/widgets/profile_header_widget.dart`, `widgets/widget_change_laguage.dart` (logic reused).
- **Dependencies:** step 2.
- **Risk:** medium.
  - The gate must stay fail-closed.
  - The pill must still refuse when unapproved.
  - `fetchCurrentDriveInfo` must still fire exactly once from `DrawerLogic.onInit`.
- **Verification:**
  - Test the approval states with a pending test account, and by forcing `unknown` (airplane mode at launch).
  - Toggle online/offline, including a failure with the network off (the rollback must be visible).
  - Language switch; drawer navigation to every tab.

### Step 4 — Home tab (P1)
- **Goal:** map overlays, `DriverStatusCard`, `LocationStateView`, force-update dialog, resume dialog.
- **Docs:** `03 S06`, DD-07/28/32.
- **Files:** `home/view.dart`, `widgets/widge_update.dart`, `widgets/process_book_dialog_widget.dart`.
- **Dependencies:** steps 1–3.
- **Risk:** low to medium. Map padding and style application; `HomeLogic` stays untouched.
- **Verification:**
  - Deny, then grant, the location permission.
  - Online/offline card.
  - Force update: point at a test version response, or temporarily edit the constants **on a local build only**.
  - Resume with an active trip (kill the app mid-trip).

### Step 5 — Trip screen: scaffold and request stage (P1) — highest risk
- **Goal:** `TripScreenScaffold`, `TripHeader`, `RequestCountdown` (new `build` only), `TripSheet`, `TripTimeline`, `PassengerRow`, `TripActionBar`.
- **Docs:** `03 S07`, `05 §2`, DD-10/11/15/16/17.
- **Files:**
  - `booking/view.dart` — `build()`, the AppBar removal and imports only.
  - `booking/widgets/ride_request_bottom_pop_widget.dart` (same class and constructor, plus `isLoading`).
  - `widgets/count_down_widget.dart` (`build` only).
- **Dependencies:** steps 1–2.
- **Risk:** **high.**
  - Must be preserved:
    - `_onTripAction` and `_onTripError` untouched.
    - Emit order.
    - Countdown expiry.
    - `PopScope`.
  - New requirement: **Cancel disabled while `isLoading`**, replacing the full-screen overlay's blocking role.
- **Verification:**
  - A full request → accept → cancel matrix on a device against the step-0 `tlog` oracle: accept; accept conflict (two devices); cancel; expiry; passenger cancel during the request.
  - Rapid double-taps on Accept, and Cancel during an in-flight accept.

### Step 6 — Trip screen: pickup, arrived, in progress (P1)
- **Goal:** stage content, `TripMeterStrip`, estimate labelling, spinner-from-tap for Drop off.
- **Docs:** `03 S07` stages, `05 §3`, DD-12/13/14.
- **Files:** `booking/view.dart` (build), `booking/widgets/{ride_request_bottom_pop_widget,show_distand_and_price_widget}.dart`.
- **Dependencies:** step 5.
- **Risk:** **high.** The meter values must equal today's expressions (`view.dart:661-676`). Drop off must still call `getLocation(TripStage.completing)`.
- **Verification:**
  - A trip **with** a destination and one **without**. Check the distance, fare and timer on screen against the baseline video.
  - Resume at each stage (statuses 2 / 8 / 3).
  - `tlog` emits match the oracle.

### Step 7 — Trip dialogs (P1)
- **Goal:** restyle the decline confirm, the three trip errors, passenger-cancel and resume. Most of the work is already done by step 2; this step applies copy and icons.
- **Docs:** `05 §8`, DD-25/33.
- **Files:** `booking/view.dart` (call sites unchanged), `app/alert_widget.dart`.
- **Dependencies:** step 2.
- **Risk:** medium (navigation semantics).
- **Verification:** trigger each dialog and compare the post-dismiss route with the baseline.

### Step 8 — Payment (P1)
- **Goal:** `ReceiptCard`, `TotalBox`, the success button, the "Collect payment" title, the payment method from the payload.
- **Docs:** `03 S08`, DD-04/18.
- **Files:** `calculate_fee/view.dart` (and copy in `calculate_fee/logic.dart:78-81` error strings → existing keys).
- **Dependencies:** step 2.
- **Risk:** medium. Money display must show the server `payment.amount` exactly as `formatRielAmount` does today.
- **Verification:** drop-off path and resume path (status 6); the error path with the network off; the `acceptPayment` emit in `tlog`.

### Step 9 — History and history detail (P2)
- **Docs:** `03 S09–S10`, DD-19/20.
- **Files:** `history/view.dart`, `history/widgets/history_card_widget.dart`, `history_detail/view.dart`.
- **Dependencies:** step 2.
- **Risk:** low. The card's tap must pass the same `MapHistoryDetailArgs`.
- **Verification:** paging, refresh, empty account, error (offline), tapping a completed card vs a cancelled one.

### Step 10 — Wallet (P2)
- **Docs:** `03 S11`, DD-21.
- **Files:** `wallet/view.dart`.
- **Dependencies:** step 2.
- **Risk:** low. Don't style amounts by sign (UNCLEAR sign convention).
- **Verification:** loaded, empty and error states; filters; a USD balance formats correctly.

### Step 11 — Announcements, Terms, Contact (P2)
- **Docs:** `03 S12–S15`, DD-06.
- **Files:** `announcement/view.dart`, `announcement_detail/view.dart`, `term_condition/view.dart`, `contact_us/view.dart`.
- **Dependencies:** step 2.
- **Risk:** low.
- **Verification:** an FCM tap opens the detail (terminated and background); unread styling; call and email work.

### Step 12 — Auth: splash, login, OTP, register (P2)
- **Docs:** `03 S01–S04`, DD-23/24.
- **Files:** `splash_screen/view.dart`, `login/view.dart`, `otp/view.dart`, `register/view.dart`.
- **Dependencies:** step 2.
- **Risk:** medium. Validation quirks must be preserved (`05 §11` rows 14–16).
- **Verification:**
  - `test/presentation/screens/login/logic_test.dart` stays green.
  - Manual: an empty phone, a 9-character phone, a formatted phone, a wrong OTP, resend, register enable/disable.

### Step 13 — Legacy token cleanup (P0 close-out)
- **Goal:** delete `ThemeConstands`, `AppTextStyles` and the superseded `AppColors` members once nothing references them.
- **Files:** `app/root_main.dart`, `core/theme/*`.
- **Dependencies:** steps 3–12.
- **Risk:** medium. 307 `Colors.*` literals and 111 `ThemeConstands` references remain today; find them with a `grep` for `Colors\.`, `Color(0x` and `ThemeConstands` under `lib/presentation`.
- **Verification:** screen walk-through in both locales.

### Step 14 — Polish (P3)
- **Scope:**
  - Optional "Request expired" toast (DD-16).
  - Version caption in the drawer.
  - Micro-interactions from `02 §15`.
  - Empty-state copy review.
  - Reduced-motion pass.
  - Accessibility labels.
- **Risk:** low.

### Step 15 — Visual QA
EN and KM at text scale 1.0 and 1.3, on a 360 dp-wide Android and a small iPhone. Check:
- daylight legibility of the map and the route line;
- 48 px targets (Flutter inspector);
- Khmer line heights with no clipping;
- no text below 12 px.

### Step 16 — Regression QA
- **A full trip lifecycle ×3:** with a destination, without one, and resumed mid-trip.
- **Error cases:** accept conflict, passenger cancel, expiry, network loss at each stage.
- **The rest:** payment, wallet, history.
- **Emits:** socket emits compared with the step-0 oracle; the `test/taxi_single_ton/*` contract tests stay green.

---

## 2. Priority classification (Phase 7)

| Priority | Changes |
|---|---|
| **P0 — Foundation** | Tokens (colour, type, spacing, radius, elevation) · light `ThemeData` · Khmer line heights · icon set · EasyLoading theme · shared components A-tier · dialog re-skin with preserved semantics · legacy token cleanup |
| **P1 — Core driver experience** | Shell (app bar, drawer, online pill, approval gate, offline banner) · Home (status card, location states, update, resume) · Trip (scaffold, header, countdown, timeline, sheet, action bar, meter, stage content) · Trip dialogs · Payment |
| **P2 — Supporting** | History + detail · Wallet · Announcements + detail · Terms · Contact · Splash · Login · OTP · Register |
| **P3 — Polish** | Expiry toast · drawer version · micro-interactions · empty-state copy · reduced motion · accessibility labels · optional card tap-to-toggle (not recommended) |

---

## 3. New translation keys (en; km drafts come from the prototype's `I18N`, HTML:475-538 — native review required)

**Rule:** add keys, don't edit existing values. `ACCEPT`, `ARRIVE` and `START_RIDE` are reused as notification titles (`booking/logic.dart:46-112`), so changing their values changes notifications too (DD-29).

| Key | en | Prototype source |
|---|---|---|
| `STAGE_NEW_REQUEST` / `STAGE_GO_TO_PICKUP` / `STAGE_AT_PICKUP` / `STAGE_ON_TRIP` | New request / Go to passenger / At pickup / On trip | `newReq`, `goToPickup`, `atPickup`, `onTrip` |
| `ACTION_ARRIVED` / `ACTION_START_RIDE` / `ACTION_DROP_OFF` | I've arrived / Start ride / Drop off | `arrived`, `startRide`, `dropOff` |
| `TIMELINE_ACCEPT` / `…_ARRIVE` / `…_START` / `…_DROP` | Accept / Arrive / Start / Drop | `phAccept…phDrop` |
| `CANCEL_REQUEST` / `CANCEL_REQUEST_TITLE` / `CANCEL_REQUEST_MSG` / `YES_CANCEL` / `STAY` | Cancel request / Cancel request? / The passenger is waiting. Cancel this request? / Yes, cancel / Stay | `cancelReq`, `cancelMsg`, `yesCancel`, `stay` |
| `TO_DECIDE` | to decide | `toDecide` |
| `PICKUP` / `DESTINATION` | Pickup / Destination | `pickup`, `destination` |
| `EST_FARE` / `EST_NOTE` | Est. fare / ≈ estimated — final fare is confirmed after drop-off | `estFare`, `estNote` (reworded) |
| `COLLECT_PAYMENT_TITLE` / `TOTAL_TO_COLLECT` / `COLLECT_HINT` | Collect payment / Total to collect / Collect the fare from the passenger, then confirm. | `paymentTitle`; the rest are new |
| `ONLINE_SUB` / `OFFLINE_SUB` / `YOU_ARE_ONLINE` / `YOU_ARE_OFFLINE` | Receiving requests / Go online to receive requests / You're online / You're offline | `onlineSub`, `offlineSub` |
| `NO_INTERNET_RECONNECTING` | No internet — reconnecting… | `noInternet` |
| `APPROVAL_CHECKING` / `APPROVAL_REJECTED_TITLE` / `APPROVAL_REJECTED_DESC` / `CONTACT_SUPPORT` / `RETRY` | Checking your account… / Application not approved / Contact support to re-submit your documents. / Contact support / Retry | `appeal` (others new; the prototype's rejection *reason* isn't adopted) |
| `UPDATE_REQUIRED` / `UPDATE_NOW` | Update required / Update now | new (replaces hardcoded English in `widge_update.dart`) |
| `LOCATION_FINDING` / `LOCATION_DENIED` / `LOCATION_FAILED` / `OPEN_SETTINGS` | Finding your location… / Location permission is off / Couldn't get your location / Open settings | new (replaces hardcoded English in `home/view.dart:94-111`) |
| `RESUMING_TRIP` | Resuming your trip… | new (supersedes `IN_PROCESS_BOOKING` display) |
| `OTP_SENT_TO` | Enter the 4-digit code sent to | `otpDesc` |
| `REGISTER_SUBMIT` | Submit for review | `create` (replaces hardcoded "Create - បង្កើត") |
| `ANNOUNCEMENTS` / `TRIP_DETAILS` | Announcements / Trip details | `announcements` / new |
| `EMPTY_COMPLETED` / `EMPTY_CANCELLED` / `EMPTY_ANNOUNCEMENTS` | No completed trips yet / No cancelled trips / No announcements yet | new |
| `SECONDS` | seconds | new (replaces hardcoded `"seconds"`, `count_down_widget.dart:87-90`) |
| `REQUEST_EXPIRED` (P3) | Request expired | `reqExpired` |

---

## 4. Issues found that need code changes (not part of the redesign)

Each is a **separate** behavioural change with its own tests. The redesign keeps today's behaviour in every case.

| # | Issue | Evidence | Why it matters | Suggested owner step |
|---|---|---|---|---|
| B1 | The trip error dialog's OK pops the trip route | `error_dialog_widget.dart` (double `pop`), `booking/view.dart:468-482` | A failed arrive/start/complete ejects the driver from an active trip; on the resume path the stack may be empty (INFERRED) | DD-33 follow-up, before or after step 7 |
| B2 | `driverCancelDrive` is emitted before the REST cancel and regardless of its result | `ride_request_bottom_pop_widget.dart:355-367` | The passenger may be told the trip was cancelled when the server still has it | Trip-lifecycle change |
| B3 | The countdown can expire during an in-flight accept | `count_down_widget.dart:32-37` vs `booking/logic.dart:33-58` | The driver is sent home while assigned | Trip-lifecycle change |
| B4 | The passenger-cancel dialog's timer is scheduled in `builder`, `close` is never set, and the listener is global | `cancel_book_dialog_widget.dart:16-48`, `socket_service.dart:172-184` | Double navigation; the dialog appears on any screen | Realtime change |
| B5 | Approval `unknown` persists on fetch error (the error is swallowed) | `app/logic.dart:36-45` | The driver is stuck behind the gate | Partly mitigated by the Retry button (PROPOSED); a proper error state needs a controller change |
| B6 | Socket connection state isn't observable | `services/socket_service.dart:52-63` | No "connecting…" indicator is possible | Realtime change |
| B7 | Connectivity is only observed in the shell | `drawer/logic.dart` | No offline banner on trip or payment | Lift into `AppLogic` or a service |
| B8 | Hardcoded English strings | `count_down_widget.dart:87-90`, `calculate_fee/view.dart:186`, `calculate_fee/logic.dart:79-80`, `widge_update.dart:42,77`, `home/view.dart:94-111`, `register/view.dart` label, `error_dialog_widget.dart` "Try Again" | Khmer users see English | Copy change; mostly absorbed by steps 4/5/8/12 |
| B9 | `getLocation` doesn't handle `getCurrentPosition` throwing | `booking/view.dart:182-295` | Silent failure on the trip screen | Robustness change |
| B10 | Payment-screen back navigation is undefined on the resume path | `home/logic.dart:213` (`offNamed`) | Back may exit the app (INFERRED) | Navigation change |
| B11 | Driver rating isn't surfaced (U1) | `set_status_model.dart:31`, `app/logic.dart:47-53` | Blueprint P1 item 5 | Small `AppLogic` change, then DD-31 |
| B12 | The camera re-centres every GPS tick at zoom 19 (U7) | `booking/view.dart:144, 575-596` | Distracting while driving | Map-behaviour change |
| B13 | Resume maps cancel/completed to "Go to passenger" (R4 / M-21) | `home/logic.dart:265-277` | Wrong screen after a cancelled trip | Needs a backend answer (Q-1) |
| B14 | EasyLoading is called inside `AppLogic.toggle` | `app/logic.dart:65-74` | RULES Definition of Done: "no ad hoc EasyLoading in controllers" | Controller change after the pill ships |
