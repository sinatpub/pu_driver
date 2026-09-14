# 03 — Screen Redesign (main document)

- **Paths:** unless noted, they're relative to `lib/presentation/screens/`. `HTML:<line>` = `docs/taarraa-driver-prototype.html`.
- **Cross-references:** components are specified in `04`, states and the preserve-list in `05`, decisions in `07`.

---

## 0. Screen mapping

### 0.1 Screens

| # | Existing `pu_driver` | HTML | Relationship | Action |
|---|---|---|---|---|
| S01 | Splash `/splash` | `s-splash` | Partial — HTML adds a boot log and Skip | Redesign; preserve the delay and routing |
| S02 | Login `/login` | `s-login` | Match — HTML adds step dots | Redesign |
| S03 | OTP `/otp` | `s-otp` | Partial — HTML adds a manual "New driver? Register" link | Redesign; omit the link |
| S04 | Register `/register` | `s-register` | Partial — HTML validates more strictly | Redesign; preserve validation |
| S05 | Shell `/home` → `DrawerScreen` (app bar, drawer, overlays) | `s-shell` + drawer + overlays | Match | Redesign |
| S06 | Home tab | `shell:home` | Partial — earnings card and QR FAB have no data | Adapt |
| S07 | Trip `/booking` | `s-booking` | Same flow; partial data | Redesign; behaviour frozen |
| S08 | Payment `/calculate-fee` | `s-fee` + `#paySuccess` | Partial | Redesign; no success overlay |
| S09 | History tab | `shell:history` | Match | Redesign |
| S10 | History detail `/map-history-detail` | `s-hdetail` | Partial — invoice header and replay can't be filled from today's args | Adapt |
| S11 | Wallet tab | `shell:wallet` | Partial — HTML adds withdraw | Redesign; no withdraw |
| S12 | Announcements `/notification` | `shell:news` | Partial — pushed route vs tab | Redesign as a route |
| S13 | Announcement detail `/notification-detail` | `s-newsdetail` | Match | Redesign |
| S14 | Terms tab | `shell:terms` | Match | Redesign |
| S15 | Contact tab | `shell:contact` | Match | Redesign |
| S16 | Profile header (in the drawer) | drawer `.prof-head` | Match — HTML adds rating and trip count | Redesign; no rating |
| — | Force-update overlay (`WidgetUpdate`) | — | Missing in HTML | New, in the design system |
| — | Resume dialog (`IN_PROCESS_BOOKING`) | — | Missing in HTML | New |
| — | Home location states | — | Missing in HTML | New |
| — | Language bottom sheet | Segmented control (drawer, login) | Partial | Adapt |
| — | — | Referral tab, QR dialog, transfer, withdraw sheet | New (no backend) | **Not adopted** (DD-21, DD-22) |
| — | — | `#ticker` alerts marquee | New (no data source) | **Not adopted** (DD-05) |

### 0.2 States

| Existing state (source) | HTML state | Relationship | Action |
|---|---|---|---|
| Approval `unknown` before first fetch, the default (`app/state.dart`) | — | Missing | New neutral "checking" state (DD-08) |
| Approval `pending` (0) | `approval='pending'` HTML:867 | Match | Adopt the visual; gate unchanged |
| Approval `rejected` (2) | `approval='rejected'` HTML:870 | Partial — today it shows the same overlay as pending | Distinct visual, driven by the existing enum |
| `isOnline` true / false | `#onlinePill` on / off | Match | Pill |
| `DrawerState.connection` false | `#offlineBar` | Match | Amber banner |
| `LocationLoadStatus` inProgress / permissionDenied / failure | — | Missing | New states |
| `HomeState.updateVersion` | — | Missing | Blocking dialog |
| `TripStage.requestReceived / enRouteToPickup / waitingAtPickup / inProgress` | Stages 0 / 1 / 2 / 3 (`STAGES`, HTML:884-888) | Match | Preserve |
| `TripStage.completing` (transient) | `dropRide` → fee | Match | Drop-off button in loading state |
| `BookingState.isLoading` | — | Missing | Loading inside the button (DD-17) |
| `TripActionError` × 3 | — | Missing | Error dialogs |
| Countdown: running / expired (silent) | Ring / `.warn` ≤10 s / "expired" toast | Partial | Adopt the visual; optional toast (DD-16) |
| Passenger cancelled | Dialog with auto bar | Match | DD-25 |
| `PaymentStatus` initial / loading / success / error | Fee screen / `#paySuccess` | Partial | DD-18 |
| History, wallet, announcements: loading / error / empty | None (`docs/ui-reference/05 §3`) | Missing in HTML | Use the design-system states |

### 0.3 Flows

| Flow | Existing (CONFIRMED) | HTML | Same / Different | Decision |
|---|---|---|---|---|
| Auth | Splash → Login → OTP → Home, or → Register when OTP returns no driver or token (`otp/logic.dart:71-74`) | Adds a manual Register link on OTP | Different | Preserve existing (DD-24) |
| Go online | Pill → `set-status`; approval-gated, optimistic, rolls back | Same, plus blocks while the network is down | Different | Preserve; no network block (DD-09) |
| Receive request | Socket `newRide` / FCM → `Get.toNamed('/booking')` | Simulated 4.5 s after going online | Same concept | — |
| Trip | Accept → Arrive → Start → Drop; advances only when REST succeeds | Same, driver-driven only | Same | — |
| Decline | Request stage only; confirm dialog → socket emit → REST | Same dialog → home | Same | Preserve the emit order (DD-11) |
| Expiry | Countdown ends → `offAllNamed(home)`, silently | → home + toast | Same flow, different feedback | DD-16 |
| Passenger cancel | Dialog; 10 s auto → home | Same, plus a progress bar | Same | DD-25 |
| Resume | Home → 2 s dialog → `/booking` at the mapped stage, or `/calculate-fee` | None | Missing in HTML | Preserve; restyle (DD-32) |
| Payment | REST → emit → home immediately | 1.6 s success overlay → home | Different timing | Preserve (DD-18) |
| History detail | Tap the map thumbnail (completed trips only) | Tap the card | Different trigger | Tap the card, completed only (DD-19) |
| Announcements | Bell → `/notification` | Drawer tab + ticker | Different entry | Preserve the route (DD-06) |
| Logout | Unreachable (UI commented out) | Drawer → dialog → login | Different | OPEN (DD-05) |

**Merges and splits:**
- The HTML splits Payment into a receipt plus a success overlay; today it's one screen.
- The HTML folds Announcements into the shell; today it's a pushed route.
- The HTML gives "Go to pickup" and "At pickup" the same blue pill palette but separate labels; that matches today's two stages.

---

# Screen: Splash (S01)

## Current Behavior
- 3 s delay (`splashDelay`) while the location permission is requested.
- With a token: `Taxi.shared.checkDriverAvailability()` → `/home`. Without a token, or on any storage error: `/login`.
- The token check is exception-safe (`splash_screen/logic.dart:25-57`). CONFIRMED.

## Current UI
White background, `CircleAvatar` with `Tara2.png`, and "TARA DRIVER - តារា តាក់សុី" in `AppTextStyles.heading` (`splash_screen/view.dart`).

## HTML Target
- A 96 px orange-gradient logo badge with glow.
- "TAARRAA" 30/800 with 3 px tracking and a brand subtitle.
- A boot-steps log and a "Skip →" link (HTML:119-125).

## Gap Analysis
- Today's splash is light and off-brand.
- The HTML boot log is simulated.
- Skip would cut short the permission and session sequence.

## Proposed Redesign
- `bg.page`, `SplashMark` (logo badge + wordmark).
- Which logo asset goes inside the badge (`Tara2.png` or `logo_app.jpg`) is UNCLEAR; the brand owner decides.
- No Skip and no fake log (DD-23).

## States
Default; the OS permission prompt shown over the splash.

## Interactions
None.

## Behavior to Preserve
Delay, permission request, routing, exception safety.

## Relevant Flutter Files
`splash_screen/{view,logic}.dart`

## Implementation Notes
View-only swap.

---

# Screen: Login (S02)

## Current Behavior
- Validation:
  - Empty field → shake + `isInvalidPhone`.
  - Fewer than 10 characters **of the formatted text** → shake + `isRequired8Digit`.
- The number is normalised to digits only before `login-phone` is called. Success → `/otp` with `OtpPageArgs(onResend)` (`login/logic.dart:68-125`).
- Full-screen `LoadingWidget` while submitting (`login/view.dart:211`).
- Language chooser (`:238`). Server errors → `showErrorCustomDialog` (in the logic file).

## Current UI
- `LOGINTITLE` / `LOGINDES`.
- An `XTextField` wrapped in `ShakeWidget`, with a `+855` prefix and `CardNumberInputFormatter` (`:127-188`).
- A 42 px `FBTNWidget` "Next" (`:190-197`).

## HTML Target
- Top row: step dots + an EN / ខ្មែរ segmented control.
- Headline "Welcome back", then the label and a `.field` with `+855` prefix.
- An error line, then a full-width Next at the bottom (HTML:340-348).

## Gap Analysis
- The theme is light and the button 42 px.
- The language chooser is hidden in a separate sheet.
- The full-screen overlay hides which part of the form is busy.

## Proposed Redesign
- **Layout:** full screen on `bg.page`. Top row: `LanguageSegment` on the right. Then the headline (existing keys), the description and a `TTextField.phone`.
- **Validation display:** inline error under the field, using the existing `CHECK_YOUR_PHONE_NUMBER_ERROR` / `CHECK_PHONE_NUMBER_DIGIT_ERROR` keys.
- **Next button:** primary, 56 px, pinned above the keyboard and safe area. Loading shows as a spinner in the button with the field disabled; the controller is untouched.
- **Omitted:** no step dots (DD-24).

## States
Initial · typing · invalid-empty · invalid-short · submitting · server-error dialog · language switched.

## Interactions
- Next, or keyboard "done" → `submit()`.
- Segmented control → the same `context.setLocale` that `ChangeLanguage` calls.

## Behavior to Preserve
- The `<10` check on unnormalised text. The hint says "8 digits"; keep the check, not the label (RULES quirk).
- Shake, normalisation, `onResend` binding.

## Relevant Flutter Files
`login/{view,logic,state}.dart`, `widgets/x_text_field.dart`, `widgets/shake_widget.dart`, `widgets/widget_change_laguage.dart`, `widgets/loading_widget.dart`.

## Implementation Notes
`LoadingWidget` stays in the tree only if other screens still need it. Here, loading inside the button replaces it.

---

# Screen: OTP (S03)

## Current Behavior
- 4-digit `Pinput` with autofocus. `onCompleted` → `verify` (`otp/view.dart:81-100`).
- The countdown runs from `seconde ?? 60`. Resend is enabled at 0 (`otp/logic.dart:47-67`; view `:148-152`).
- Success → `/home`; no driver or token → `/register`. Failure clears the pin and shows an error dialog.
- A debug bypass exists.

## Current UI
Back button, `OTP_VERIFICATION` + description, pin row, `UNRECEIVED_OTP` + `RESEND_CODE`.

## HTML Target
- Back icon-button, step dots, the phone number in bold.
- Four 64 px boxes, a timer pill plus a "Send again" link.
- A "New driver? Register →" link (HTML:351-362).

## Gap Analysis
- The visuals need updating.
- The HTML Register link would skip server verification.

## Proposed Redesign
- **Header:** 48 px back icon-button, headline.
- **Description:** "Enter the 4-digit code sent to" (new key `OTP_SENT_TO`, from HTML `otpDesc`) + the phone number in `text.primary` bold, taken from the args.
- **Pin row:** `OtpInput`, a Pinput theme per `02 §8`.
- **Resend:** a timer pill (`brand.tint` background, `brand.text` tabular text), which becomes the tertiary "Resend code" when enabled.
- **Verifying:** the pins are disabled and a small spinner appears below the row.
- **Omitted:** no Register link (DD-24).

## States
Entering · verifying · error (dialog, pin cleared) · counting down · resend available · resending.

## Interactions
Auto-submit on the 4th digit; resend; back.

## Behavior to Preserve
Auto-submit, `onResend`, countdown source, debug bypass, register branch.

## Relevant Flutter Files
`otp/{view,logic}.dart`, `routes/route_arguments.dart` (read-only).

## Implementation Notes
Only `PinTheme`s change.

---

# Screen: Register (S04)

## Current Behavior
- **Fields:** name; vehicle type (`SearchableDropdown<SingleVehical>`, from `get-vehical`); colour; plate; 4 uploads (`CardUploadAttachment` → gallery/camera `xShowModalBottomSheet`).
- **Submit button:** enabled **unless name and plate are both empty** (`register/view.dart:408-411`), with the hardcoded label "Create - បង្កើត".
- **Submission:** full-screen loading while it runs; success → `checkDriverAvailability` + `/home`.

## Current UI
Light form, 42 px button.

## HTML Target
- Back + step dots; headline "Driver registration".
- Colour and plate on a 2-column row.
- A 2×2 photo grid: dashed slots that turn solid green once attached.
- "Submit for review", plus the note "Admin usually reviews within 24 hours" (HTML:365-381, 667-672).

## Gap Analysis
- The visuals need updating.
- The HTML's enable rule (name ≥2 characters and all 4 photos) is **stricter** than today's, which is a behaviour change.
- "24 hours" is an unverified promise.

## Proposed Redesign
- Form: `TTextField` fields, plus a vehicle field that opens the existing searchable dropdown.
- Colour and plate on a 2-column row.
- `PhotoSlotGrid` 2×2, wrapping the existing `CardUploadAttachment` callbacks. The "attached" state comes from the existing image state.
- The submit label moves to a new key `REGISTER_SUBMIT` ("Submit for review").
- No "24 hours" note unless Ops confirms it (UNCLEAR).
- The enable rule is **unchanged** (DD-24).

## States
Empty · partial · photo attached / replace · vehicles loading / error · submitting · error dialog.

## Interactions
Tap a photo slot → the existing picker sheet; select a vehicle; submit.

## Behavior to Preserve
Multipart fields, the enable rule, picker behaviour, post-success calls.

## Relevant Flutter Files
`register/{view,logic}.dart`, `widgets/card_atta_widget.dart`, `widgets/x_dropdown_search.dart`, `widgets/x_showmodal_bottom.dart`, `widgets/x_button.dart`, `controllers/vehicle_controller.dart`.

## Implementation Notes
Khmer labels inside the 2×2 slots are the tightest fit; test at text scale 1.3.

---

# Screen: App shell — `DrawerScreen` + global overlays (S05, S16)

## Current Behavior
- **Tabs:** `DrawerTab` has `home, history, wallet, termCondition, contactUs, announcement`; `announcement` is never selected. `selectTab` swaps the body (`drawer/view.dart:46-61, 306-311`).
- **App bar:** tab title, bell → `/notification`, and `SwitchOnlineWidget` on the home tab only (`:69-101`).
- **Drawer:** `ProfileHeaderWidget` + Home, History, Wallet, Terms, Contact, Language. CHANNEL and Logout are commented out (`:102-305`).
- **Offline banner:** driven by `InternetConnection` (`drawer/logic.dart`; view `:321-343`).
- **Approval overlay:**
  - Shown whenever `!isApproved`, which includes `unknown` before the first fetch. It's a translucent cover over the body plus a 250 px white bottom panel reading "WAITING_APPROVED_FROM_ADMIN" (`:344-379`).
  - The app bar and drawer stay usable.
- **Startup:** `DrawerLogic.onInit` → `AppLogic.fetchCurrentDriveInfo()`. This feeds both the approval gate and resume routing.

## Current UI
- A light Material app bar, a 44 px Cupertino bell and a 110×30 `FlutterSwitch`.
- Drawer items in 20 px text with orange icons; a solid orange header block; a red banner.

## HTML Target
- **Dark app bar:** menu, TAARRAA wordmark with "DRIVER · តារា", online pill.
- **Drawer:** initials avatar with rating and trip count; 7 items with an active highlight; online row; sound row; language segmented control; logout; version (HTML:384-395, 833-849).
- **Overlays:**
  - Full-screen approval overlay for pending and rejected, with "Contact support" (HTML:863-873).
  - Floating offline pill (HTML:147, 874).
  - Ticker (HTML:390).

## Gap Analysis
- The driver's status is shown by a small third-party switch.
- **One approval panel covers three different states:**
  - A rejected driver is told to "wait".
  - Every driver briefly sees "waiting approval" on each launch. INFERRED: `isApproved` is false while `unknown`.
  - If the fetch fails, `unknown` is permanent, because the error is swallowed (`app/logic.dart:43`).
- The red banner reads as a crash.
- The drawer doesn't mark the active tab.

## Proposed Redesign
- **App bar:** `[menu] [wordmark | tab title] [bell] [OnlineStatusPill, home only]`.
- **`DriverDrawer`:**
  - Profile head: network photo with an initials fallback; name; phone; vehicle type · driver id.
  - Items: Home, Riding history, My wallet, Terms & conditions, Contact us. The active item uses `brand.tint`.
  - Language row: `LanguageSegment` (EN / ខ្មែរ, the only two entries in `presentation/repository/language_data.dart`).
  - Optional version caption (P3).
  - **Not included:** Referral, an Announcements tab, Sound, an online toggle in the drawer, Logout (OPEN, DD-05).
- **`ApprovalGate`** over the body. The app bar stays usable, as today (DD-08):
  - `unknown`: neutral card "Checking your account…" + spinner + a secondary "Retry" that calls the existing `AppLogic.fetchCurrentDriveInfo` (PROPOSED).
  - `pending`: amber clock, "Waiting for admin approval" (existing `WAITING_APPROVED_FROM_ADMIN`), plus body `WAITING_DES` (exists in `en.json:83` but is unused today). Secondary "Contact support" → `tel:` through the existing `ContactUsLogic.callPhone` (PROPOSED).
  - `rejected`: `danger` X, new copy "Application not approved" + "Contact support to re-submit". There's no reason field in the payload, so no reason text.
- **`OfflineBanner`:** an amber pill under the app bar, "No internet — reconnecting…". The copy is truthful: the socket retries forever (`docs/reverse-engineering/04 §4`). It renders nothing while connected.

## States
- Tab: one of 5.
- Approval: unknown, pending, rejected or approved.
- Online: on, off or toggling.
- Network: online or offline.
- Drawer: open or closed.
- Profile: loading, error or loaded.

## Interactions
- Menu → drawer. Item → `selectTab` + close.
- Bell → `Get.toNamed('/notification')`.
- Pill → `AppLogic.toggle`. If unapproved, the existing toast appears (`switch_online_widget.dart:32-35`).
- Language → `setLocale`.

## Behavior to Preserve
- The `fetchCurrentDriveInfo` trigger point.
- The gate fails closed.
- The pill appears on home only.
- Tabs have no routes.
- The connectivity subscription is cancelled in `onClose`.
- `/home` uses no transition.

## Relevant Flutter Files
`drawer/{view,logic,state}.dart`, `home/widgets/switch_online_widget.dart`, `profile/widgets/profile_header_widget.dart`, `widgets/widget_change_laguage.dart`, `app/{logic,state}.dart`, `contact_us/logic.dart`, `presentation/repository/language_data.dart`.

## Implementation Notes
- Replacing `SwitchOnlineWidget` removes the last use of `flutter_switch`. The dependency stays in the pubspec until a separate cleanup; the UI change doesn't touch the pubspec.
- The gate reads `AppState.approvalStatus` (all three values already exist); no controller change.

---

# Screen: Home tab (S06)

## Current Behavior
- **Location:** `initLocation` requests permission, primes a fix, sets the marker, starts the stream and moves the camera on every tick (`home/logic.dart:156-189`).
- **Socket:** registered after the first frame (`home/view.dart:35`).
- **Version check** sets `updateVersion`.
- **Resume redirect:** via `ever(currentDriveInfo)` → `/calculate-fee`, or a 2 s dialog → `/booking` (`home/logic.dart:88-93, 204-263`).
- `AppLogic.checkStatus()` runs on init.

## Current UI
- A full map with traffic and the custom marker.
- Location states: spinner; raw "Location permission denied"; a failure message + "Open location permission" (`openAppSettings`) (`home/view.dart:67-117`).
- A white update box with hardcoded English (`:47-58`, `widge_update.dart`).

## HTML Target
- A full-bleed dark map with a radar pulse while online.
- A floating earnings card ("Today · N trips", ៛ amount, online badge) and a QR FAB (HTML:680-686).

## Gap Analysis
- Nothing on the map states the driver's status.
- Location errors are raw English strings.
- **The earnings card has no data:**
  - N-09 `TripEarningBasis` is an open business question (`features/earnings/domain/earnings.dart:37-47`).
  - There is no earnings endpoint.
- The QR code has no backend.

## Proposed Redesign
- **Map:** full-bleed, default light styling. No radar animation.
- **`DriverStatusCard`:** floats at the bottom with a 16 px inset (`.earn-card` geometry, HTML:150). It isn't interactive; the pill stays the single toggle (DD-09). No money (DD-07).
  - Online: success badge, "You're online", "Receiving requests" (from HTML `onlineSub`).
  - Offline: neutral badge, "You're offline", "Go online to receive requests" (`offlineSub`).
  - Unapproved: hidden, because the gate covers it.
- **`LocationStateView`** replaces the map until `success`:
  - Loading: map skeleton + "Finding your location…".
  - Permission denied: icon, explanation, secondary "Open settings" → `openAppSettings`. Adding this button to the denied state is PROPOSED; failure already has it.
  - Failure: the error, plus "Open settings".
- **Force update:** `TDialog.blocking` with logo, "Update required" (new key), the existing `UPDATE_VERSION_DISCRIPTION`, and a primary "Update now" to the same store URLs.
- **Resume:** `TDialog.progress` "Resuming your trip…". It stays barrier-dismissible and keeps the 2 s timing (DD-32).

## States
- Location: inProgress, success, permissionDenied or failure.
- Online or offline.
- Update required.
- Resuming.

## Interactions
Map gestures; open settings; update now.

## Behavior to Preserve
- The camera follows every tick (U7 is a separate change).
- The marker is regenerated when the profile loads.
- Socket registration happens after the first frame.
- The version-comparison logic.
- Resume timing and the M-21 stage mapping.

## Relevant Flutter Files
`home/{view,logic,state}.dart`, `widgets/widge_update.dart`, `widgets/process_book_dialog_widget.dart`, `app/alert_widget.dart`.

## Implementation Notes
Set the map's bottom padding to the card height so the Google logo stays visible.

---

# Screen: Trip — `/booking` (S07)

## Current Behavior (CONFIRMED)
- **Entry:**
  - Socket `newRide` or FCM → `Get.toNamed('/booking', BookingScreenArgs(processStepBook: 1))` (`services/socket_service.dart:150-169`).
  - Resume → `Get.offNamed` with step 2, 3 or 4 (`home/logic.dart:224-277`).
- **Actions:** each `BookingLogic` action does the same thing (`booking/logic.dart`):
  1. Returns if `isLoading`.
  2. Calls REST.
  3. On success, advances the machine and sets `lastResult`. On failure, sets `lastError`.
- **The view reacts:**
  - `_onTripAction` emits the socket event, re-geocodes and redraws the polyline, and navigates (`booking/view.dart:407-466`).
  - `_onTripError` opens one of three error dialogs (`:468-482`).
- **GPS listener:** moves the marker and camera on every tick. While `inProgress` with no destination, it adds up distance (`:133-173`).
- **Route and fare:** polyline plus distance/fare, once, at waiting or in progress when there's a destination (`:297-364`).
- **Other:**
  - `PopScope(canPop:false)` (`:623-624`); fixed zoom 19 (`:575-596`).
  - The stage title lives in the AppBar (`:611-621`).
  - The countdown sits at top 60 during a request (`:681-691`).
  - Sheet: `ModelBottomSheetNewRequestWidget` (`:692-717`). In-trip strip: `ShowDistandWidget` (`:661-680`).
  - Full-screen `LoadingWidget` while `isLoading` (`:718`).

## Current UI
- Light AppBar; a white `ExpansionTile` sheet; 42 px buttons.
- Addresses printed as "LABEL: (address)".
- A red polyline.
- A 100 px white countdown circle labelled "seconds", hardcoded in English (`count_down_widget.dart:87-90`).

## HTML Target
- A full-bleed dark map.
- A floating trip card (car icon, title, booking code) plus a stage pill.
- A floating countdown ring.
- A bottom sheet: grabber → 4-step timeline → stage content → CTA (HTML:398-409, 907-944).

## Gap Analysis
- The stage is conveyed only by AppBar text.
- **The CTA:** it's small and identical at every stage. On a request, Cancel is a 1/3-width filled dark button right next to Accept, which invites mis-taps (`ride_request_bottom_pop_widget.dart:341-398`).
- The in-trip price is labelled "TOTAL_PRICE" but it's a client estimate (R8).
- The grey full-screen loading hides the map and doesn't say which action is running.

## Proposed Redesign

```
Stack
 ├─ GoogleMap                (logic unchanged; light styling; padding.bottom = sheet height)
 ├─ SafeArea ─ TripHeader    [● pulse] {stage title} ........ #{bookingCode}   (stage palette)
 ├─ RequestCountdown         (request stage only, centred under the header)
 └─ TripSheet (persistent)
      grabber
      TripTimeline(stage)
      collapsible stage content      (TripMeterStrip stays visible when collapsed)
      TripActionBar (pinned)         primary CTA  [+ "Cancel request" on the request stage]
```

`TripHeader` merges the prototype's trip card and status pill into **one** floating element, to keep fewer things over the map (DD-10).

| `TripStage` | Header (new keys, DD-29) | Palette | Current timeline step | Primary CTA (variant) | Secondary |
|---|---|---|---|---|---|
| requestReceived | New request | `stage.request` | 1 Accept | Accept (primary) | Cancel request (tertiary, danger) |
| enRouteToPickup | Go to passenger | `stage.pickup` | 2 Arrive | I've arrived (primary) | — |
| waitingAtPickup | At pickup | `stage.pickup` | 3 Start | Start ride (success) | — |
| inProgress | On trip | `stage.onTrip` | 4 Drop | Drop off (primary) | — |
| completing | On trip | `stage.onTrip` | 4 | Drop off, loading | — |

## States
Per stage below. Across all stages:
- **`isLoading`:** the tapped CTA shows a spinner. **Every other trip action, including Cancel, is disabled.** Call passenger stays enabled (DD-17).
- **`lastError`:** the matching `TDialog.error` (§ Trip dialogs).

## Interactions
- CTA → the same `onTap` stage switch that exists today (`view.dart:706-716`).
- Cancel → confirm → the same `onYes` body as today.
- Call → `tel:`.
- Grabber or header chevron → collapse / expand.

## Behavior to Preserve
- Everything in "Current Behavior".
- The `ever()` wiring and the emit sequence inside `_onTripAction` must not be moved or reordered.
- The `refreshApp` handling.
- The `dropDrive` longitude quirk: `currentLng: currentLatDriver` (`view.dart:460`) is documented, not fixed.

## Relevant Flutter Files
`booking/view.dart`, `booking/widgets/ride_request_bottom_pop_widget.dart`, `booking/widgets/show_distand_and_price_widget.dart`, `widgets/count_down_widget.dart`, `widgets/error_dialog_widget.dart`, `widgets/yesno_dialog_widget.dart`, `widgets/loading_widget.dart`. Read-only: `booking/{logic,state,binding}.dart`, `features/trip/domain/trip_state_machine.dart`.

## Implementation Notes
- **Restyle by swapping widgets, not logic.** Replace the AppBar and the three child widgets and keep every `_BookingScreenState` method as it is.
- **The new sheet takes the same inputs as today** (`bookingId … processType, onTap, onCancel`) plus `isLoading`, read from `tripController.state.isLoading`.
- `booking/view.dart` is a 725-line `State` that also owns GPS, polylines and socket calls. Keep the diff to `build()` and imports.

### Stage: Request received
- **Current:**
  - Sheet content:
    - passenger photo, name and phone, with a call button;
    - "PASSENGER_LOCATION: (reverse-geocoded pickup)";
    - "WHERE_TO_GO" only when the payload has a destination.
  - **No distance or fare** at this stage (`ride_request_bottom_pop_widget.dart:268-271`).
  - Cancel: confirm dialog → socket `driverCancelDrive` → `tripController.cancel()` (`:349-368`).
  - Countdown `args.timeOut` → home.
- **HTML:**
  - Title "New request · 0.4 km away".
  - Passenger row with rating; pickup and destination rows.
  - Distance and est. fare; Accept; a Cancel text link.
  - A 30 s ring that turns amber at ≤10 s, with a tick sound.
- **Gap:** "away", passenger rating and a request-stage fare don't exist in the data (DD-15).
- **Proposed sheet:**
  - `PassengerRow`.
  - `TAddressRow` Pickup, from `currentPassengerPM`; a skeleton line while it's empty.
  - `TAddressRow` Destination, only when `desLatPassenger` is present — omitted otherwise, as today.
  - Pinned: Accept (primary, 56, full width) → 16 px gap → "Cancel request" (tertiary danger, 48 high).
  - `RequestCountdown` sits under the header.
- **States:**
  - received · address geocoding · accepting (Accept spinner, Cancel disabled)
  - accept errors: already accepted / confirm failed / generic
  - declining (the dialog closes, Cancel shows a spinner, Accept is disabled) · declined → home
  - expired → home · passenger cancelled → dialog
- **Preserve:**
  - Countdown expiry navigation.
  - The order inside `onYes`: emit first, then `onCancel`.
  - `canCancel` is only true at this stage.
  - The accept guard.
- **Critical note (DD-17):**
  - Today the full-screen overlay blocks the Cancel tap while `isLoading`.
  - Without the overlay, a Cancel tapped during an in-flight Accept would emit `driverCancelDrive`, but the REST `cancel()` would return early (`booking/logic.dart:61`).
  - So Cancel **must** be disabled while `isLoading`.

### Stage: Going to pickup (accepted)
- **Current:**
  - `GO_TO_PASSENGER`; polyline from driver to passenger.
  - Sheet: "DRIVER_LOCATION: (driver's own address)" + "PASSENGER_LOCATION".
  - CTA ARRIVE. Camera on the passenger.
- **HTML:** the pickup address in focus at 18 px, then the passenger row, then "I've arrived".
- **Proposed:**
  - `TAddressRow` Pickup in `title` size, then `PassengerRow`, then the pinned "I've arrived".
  - Drop the driver's own-address line; it's little use while driving (PROPOSED).
- **States:** navigating · arriving · error.
- **Preserve:** the `acceptRide` emit (it fires on `TripAccepted`), the polyline, the camera.

### Stage: At pickup (arrived)
- **Current:**
  - `PREPAIR_TO_GO`.
  - "START_LOCATION" + "WHERE_TO_GO".
  - Distance + ៛ fee once computed (only with a destination).
  - CTA START_RIDE.
- **HTML:** passenger row, destination in focus with distance, green "Start ride".
- **Proposed:**
  - `PassengerRow`.
  - `TAddressRow` Destination in `title` size, with distance meta once known.
  - A `TKeyValueRow` "≈ Est. fare", only after `totalFee` is computed (DD-14).
  - Pinned "Start ride" (success).
- **States:** waiting · fare computing (row absent until known) · starting · error.
- **Preserve:** the `rideArrival` emit; the destination polyline.

### Stage: Trip in progress
- **Current:**
  - `CARRYING_PASSENGER`.
  - A top strip: DURATION (Hour) / DISTANCE (km) / TOTAL_PRICE (khr) in blue.
  - Sheet: start + destination + distance / fee.
  - CTA DROP → `getLocation(completing)` → reverse geocode → `complete()`.
  - The sheet starts collapsed only when the screen is **entered** at this stage (`ride_request_bottom_pop_widget.dart:55-64`).
- **HTML:** a green fare strip (time / distance / ≈ fare) + estimate note, destination in focus, a red "Drop off".
- **Proposed:**
  - `TripMeterStrip` at the top of the sheet, visible even when collapsed:
    - Time: `formatDuration(remaining)`.
    - Distance: same branches as `view.dart:663-668`.
    - "≈ Fare": same branches as `view.dart:669-675`.
    - Plus the note "≈ estimated — final fare is confirmed after drop-off" (new key `EST_NOTE`, from HTML `estNote`).
  - Then `TAddressRow` Destination, when there is one, and the pinned "Drop off" (primary, DD-12).
  - The strip moves from the top of the map into the sheet. Values and formatters are unchanged.
- **States:** meter running · dropping (spinner) · error.
- **Dropping — how the spinner starts:**
  - Today `isLoading` only turns true inside `complete()`, which runs after `getCurrentPosition` and reverse geocoding.
  - That leaves a gap with no feedback (INFERRED).
  - Use a view-local "drop pending" flag so the spinner starts at the tap.
  - It's purely visual: a second tap still reaches `complete()`, which returns early once `isLoading` is set.
- **Preserve:** distance accumulation, fare computation, the `dropDrive` emit, navigation to payment.
- **Open:** a confirmation before Drop off (DD-13).

### Stage: Completing → Payment
- **Flow:** `TripCompleted` → `dropDrive` emit → reverse-geocode the start and end → `Get.offNamed('/calculate-fee')` (`view.dart:450-500`).
- **UI:** the Drop off spinner stays until navigation.

### Trip dialogs and events
- **Error dialogs** (`_onTripError`):
  - The three variants use the existing keys: `RIDE_ALREADY_ACCEPTED` / `BOOKING_ALREADY_ACCEPTED`, `COMFIRM_ERROR` / `CAN_NOT_CONFIRM_BOOKING`, `PLEASE_TRY_AGAIN` / `PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG`.
  - All pass `comfirmBook: true`. CONFIRMED in `error_dialog_widget.dart`: OK then calls `Navigator.pop` **twice**, which closes the dialog and pops the route beneath it (the trip screen). A barrier tap only closes the dialog.
  - INFERRED impact:
    - A failed arrive, start or complete throws the driver out of the trip screen.
    - On the resume path, `/booking` replaced `/home`, so the stack may end up empty.
  - The redesign **keeps these semantics** (DD-33); fixing them is a separate behaviour change.
- **Passenger cancelled** (`onPassengerCancelDrive` → `AlertWidget.cancelBooking`):
  - `TDialog.autoDismiss`: `danger` icon, the existing `BOOKINGS_CANCELED` / `PASSENGER_CANCEL`, a 10 s progress bar (visual only), and an "OK" primary (existing YES → home).
  - Existing quirks (CONFIRMED in `cancel_book_dialog_widget.dart:16-48`), preserved (DD-25):
    - The 10 s navigation is scheduled inside `builder`.
    - `close` is never set, so it fires even after OK.
    - The listener is global and fires on any screen.
- **Expiry:** see the request stage and DD-16.
- **Second `newRide` while on a trip:** GetX's default `preventDuplicates` ignores the push (INFERRED), but the sound/notification still fires. No UI change.

---

# Screen: Payment — `/calculate-fee` (S08)

## Current Behavior
- **Two entry payloads:** `FromDropBooking` (`CompleteDriverModel`) and `FromHome` resume (`DataDriverInfo`) (`calculate_fee/logic.dart:34-60`).
- **Button:** `PAYMENT_DONE` calls `accept-payment`.
- **On success:** `acceptPayment` socket emit → `ProfileLogic.fetchProfile()` → `offAllNamed(home)`.
- **On error:** a dialog with hardcoded English "Please Try Again!" (`logic.dart:68-91`).

## Current UI
- Title `CALCULATE_FEE`.
- A card containing:
  - passenger photo and name;
  - "METHOD Unknown Payment" — **the literal string is hardcoded** (`view.dart:186`);
  - `PAYMENT_COLLECTION`;
  - server distance, duration and ៛ amount;
  - `DATE_TIME`;
  - start and end addresses;
  - a red `TOTAL_PRICE` bar.
- A red 200 px button with a spinner (`:108-117`).

## HTML Target
- App bar "Collect payment".
- **Receipt:** passenger row with a Cash badge; dashed dividers; key-values for distance, duration and date; pickup and destination.
- **Total box:** green, with "Trip fare · Cash", an estimate line and the big amount.
- Hint "Collect cash…", a green "Payment done", and a 1.6 s success overlay (HTML:981-1003).

## Gap Analysis
- "Calculate fee" is jargon.
- Every driver sees "Unknown Payment".
- A red total reads as an error.
- Nothing tells the driver what to do next.
- The HTML's "Cash" is an assumption.

## Proposed Redesign
- **App bar:** "Collect payment" (new key `COLLECT_PAYMENT_TITLE`).
- **`ReceiptCard`:**
  - `PassengerRow` without the call button.
  - A payment-method badge from `payment.paymentMethod` **only when it's present**. The field exists on the `CompleteDriverModel` Payment (`data/models/complete_driver_model.dart:432`) and on the `current_driver_info_model` Payment (`docs/reverse-engineering/03 §1`). Otherwise, no badge.
  - `TKeyValueRow` Distance / Duration / Date & time, using the existing formatters.
  - Start and end address rows.
- **`TotalBox`:**
  - `bg.raised` surface, a `caption` "Total to collect", and the amount in `display`, tabular `text.primary`.
  - **Server `payment.amount` only** — no estimate line (DD-18).
- **Hint caption:** "Collect the fare from the passenger, then confirm." (new key).
- **Button:** pinned success "Payment done", full width, 56, with a spinner.
- **After success:** no overlay; navigation is immediate, as today.
- **Error:** `TDialog.error` with the existing localized `PLEASE_TRY_AGAIN*` keys. This is a copy-only fix.

## States
Initial · submitting · success (navigates) · error.

## Interactions
Payment done.

## Behavior to Preserve
- Both `routFrom` branches and the `rideId` / `passengerId` / `bookingCode` / `bookingId` getters.
- Emit only after REST success; profile refetch; `offAllNamed`.
- Back-navigation behaviour, which isn't changed. INFERRED: from the resume path the stack is `[/calculate-fee]` only.

## Relevant Flutter Files
`calculate_fee/{view,logic,state,binding}.dart`, `data/models/{complete_driver_model,current_driver_info_model}.dart`.

## Implementation Notes
Showing the real payment method replaces a hardcoded string. It's a display fix; call it out in the PR.

---

# Screen: History tab (S09)

## Current Behavior
- **Tabs:** `COMPLETED` (status 4) and `CANCELLED` (5).
- **Loading and errors:**
  - Infinite scroll when the list reaches its max extent; pull-to-refresh.
  - Shimmer while empty and loading; error text while empty with an error (`history/view.dart:34-105`).
- **Card** (`history_card_widget.dart`):
  - passenger image, invoice, status name, method, distance, duration, amount, date;
  - addresses, or "UNKNOWN" when the trip isn't completed;
  - a **static asset** `image_map.png` thumbnail, which is the only tap target → `/map-history-detail` with `MapHistoryDetailArgs`. Completed trips only (`:199-229`).

## Current UI
Underline tabs; white cards.

## HTML Target
- `h2` + refresh icon; segmented tabs.
- `.hcard`: avatar; invoice (mono) with "passenger · date"; amount on the right; status badge; route box with pickup and destination dots; distance and duration meta (HTML:699-709).

## Gap Analysis
- A fake map image is the only tap target.
- Dense text.
- No empty state.

## Proposed Redesign
- **Tabs:** `TTabs` (Completed / Cancelled).
- **`HistoryCard`** per the HTML:
  - photo, falling back to initials;
  - `#invoice` in tabular figures;
  - amount on the right in `text.primary`;
  - a success or danger badge with the `statusName` label;
  - route box and meta.
- **Tapping:**
  - The whole **completed** card taps through to the same `Get.toNamed(mapHistoryDetail, MapHistoryDetailArgs(...))`.
  - Cancelled cards stay non-tappable.
  - The thumbnail is removed (DD-19).
- **Refresh:** pull-to-refresh, as today, plus an optional refresh icon → `logic.reload`.
- **Empty and error states:**
  - Empty: `TEmptyState` "No completed trips yet" / "No cancelled trips" (new keys).
  - Error: `TErrorState` with Retry → `logic.reload`.
- **Paging:** the footer spinner stays as today.

## States
Loading (skeleton cards) · loaded · empty · error · paging · refreshing.

## Interactions
Switch tab · pull to refresh · tap a completed card · scroll to page.

## Behavior to Preserve
Status filters, the paging trigger, argument construction, the completed-only tap target.

## Relevant Flutter Files
`history/{view,logic,state}.dart`, `history/widgets/history_card_widget.dart`, `widgets/simmer_widget.dart` (`ShimmerBookStory`).

## Implementation Notes
Move the `onTap` from `_mapThumbnail` to the card root, unchanged.

---

# Screen: History detail (S10)

## Current Behavior
- A full-screen `GoogleMap` with start and end markers plus a Directions polyline (`history_detail/logic.dart:80-101`).
- `ShowDistandWidget` overlay and a back button.
- The args carry only: vehicle type, cost, distance, duration and coordinates.

## Current UI
Light, map-only.

## HTML Target
- App bar with the invoice id; a 200 px minimap.
- Detail card: avatar, invoice, passenger, date, amount, badge, key-values.
- "Replay route" (HTML:419-425, 1006-1014).

## Gap Analysis
- The args have no invoice, passenger or date.
- Replay is a new feature.

## Proposed Redesign
- **Map** in the top ~55% (default light styling, brand-coloured route).
- **`TCard`** below with `TKeyValueRow` Distance / Duration / Amount (from the args) and a completed badge.
- **App bar:** back + "Trip details" (new key). No replay (DD-20).
- **Later, as a separate change:** add invoice and date to `MapHistoryDetailArgs`.

## States
Map loading (polyline pending) · loaded · route fetch failed (map without a polyline, as today).

## Interactions
Back; map gestures.

## Behavior to Preserve
Args, Directions call, markers.

## Relevant Flutter Files
`history_detail/{view,logic,state,binding}.dart`, `routes/route_arguments.dart` (read-only).

## Implementation Notes
The in-trip `TripMeterStrip` isn't reused here. The key-value card replaces `ShowDistandWidget`.

---

# Screen: Wallet tab (S11)

## Current Behavior
- `logic.fetch()` runs every time the tab opens (`initState`).
- **Balance cards:** two — `COMMISSION_FARE` (orange) and `WALLET` (green `#01b951`), formatted with `formatWalletAmountWithSymbol`.
- **Loading and error:** shimmer for loading and initial; an error message + a `PLEASE_TRY_AGAIN` retry.
- **History list:**
  - Type-filter chips come from the data and only show when there's more than one type.
  - Empty state: `NO_TRANSACTIONS_YET`.
  - Rows show typeName, date, status and a **neutral** amount (`wallet/view.dart`).
- Top-up UI is commented out.

## Current UI
Heavy coloured cards on a light background.

## HTML Target
- `h2` + refresh.
- Gradient cards:
  - "Wallet balance · Available to withdraw"
  - "Commission owed · Owed to Taarraa"
- A Withdraw button → sheet with KHQR / ABA / Wing.
- All / In / Out chips; rows with green and red signed amounts (HTML:710-718, 816-830).

## Gap Analysis
- **The HTML sub-labels assert meanings that are UNCLEAR**: what the commission card means is an open question (`docs/reverse-engineering/06 §5`).
- There's no withdraw API.

## Proposed Redesign
- **Header:** "My wallet" + a refresh icon-button → `logic.fetch`.
- **`WalletBalanceCard` ×2**, in a 2-column grid:
  - Wallet: `success.tint` fill with a `success` label.
  - Commission fare: `brand.tint` fill with a `brand.text` label.
  - Amounts in `title`, tabular `text.primary`.
  - Labels use the existing keys, with **no invented sub-labels** (DD-21).
- **Chips:** the existing dynamic filters (All + type names), in the design-system chip style.
- **`TransactionRow`:** wallet icon; typeName; a "date · status" caption; the amount right-aligned in `text.primary` (DD-04).
- **No withdraw or top-up.**

## States
Loading (skeleton cards and rows) · loaded · empty list · error · refreshing.

## Interactions
Refresh · select a filter.

## Behavior to Preserve
Fetch on open, the filter logic (`features/wallet/wallet_presentation.dart`), USD/riel formatting.

## Relevant Flutter Files
`wallet/{view,logic,state}.dart`, `features/wallet/wallet_presentation.dart`, `widgets/simmer_widget.dart` (`ShimmerWalletCard`).

## Implementation Notes
UNCLEAR: whether debits arrive as negative amounts. Don't derive in/out styling until that's confirmed.

---

# Screens: Announcements (S12) and Announcement detail (S13)

## Current Behavior
- A pushed route from the bell, with AppBar `CHANNEL`.
- A paginated list with shimmer, error text and pull-to-refresh; unread = `status == 0` background (`announcement/view.dart:52-94`).
- The detail screen shows images.
- FCM taps route to the detail screen with `NotificationDetailArgs` (`services/notification_logic.dart:209-233`).

## Current UI
Light list and light detail.

## HTML Target
- News cards: 15/700 title, 13 px `sub` body clamped to 2 lines, date. Unread = brand border + dot (HTML:241-246, 719-721).
- A detail card with an image placeholder.

## Gap Analysis
- Unread status is barely visible.
- No empty state.

## Proposed Redesign
- **List:**
  - App bar: back + "Announcements" (new key).
  - `NewsCard` per the HTML. Unread uses the brand border and dot, with the same `status == 0` rule.
  - `TEmptyState` "No announcements yet".
- **Detail:**
  - Back; title 17/700; `caption` date; body 14/1.65 in `text.secondary`.
  - The **existing** images, full width with `r.md` corners.

## States
Loading · loaded · empty · error · refreshing · paging; detail loading / error.

## Interactions
Tap → detail; pull to refresh; back.

## Behavior to Preserve
Routes, args, pagination, FCM deep links, `appOpened` handling.

## Relevant Flutter Files
`announcement/*`, `announcement_detail/*`.

## Implementation Notes
The drawer tab stays out (DD-06).

---

# Screen: Terms & conditions (S14)

## Current Behavior
A static numbered list from `TermConditionLogic.state.terms`.

## Current UI
A grey background with numbered text.

## HTML Target
`.term` rows: a numbered badge in `brand.tint`, on a surface card (HTML:248-249).

## Gap Analysis
Visual only.

## Proposed Redesign
A `TermRow` list with 16 px padding. **The content is unchanged**; the HTML's terms are prototype text.

## States
Static.

## Interactions
Scroll.

## Behavior to Preserve
Content source.

## Relevant Flutter Files
`term_condition/*`.

## Implementation Notes
—

---

# Screen: Contact us (S15)

## Current Behavior
Logo, blurb, Smart and Cellcard phone rows (`tel:`), email (`mailto:`), address, copyright (`contact_us/view.dart`, `ContactUsState`).

## Current UI
`ListTile`s on white.

## HTML Target
Logo badge; `.prow` rows with chevrons (HTML:722-728).

## Gap Analysis
Visual only.

## Proposed Redesign
- The existing `company_logo.png` inside a badge, then the blurb.
- `ContactRow` for the two phones and the email; the address row isn't tappable.
- A copyright caption.

## States
Static.

## Interactions
Call, email.

## Behavior to Preserve
`callPhone` and `sendEmail`, and the data source.

## Relevant Flutter Files
`contact_us/*`.

## Implementation Notes
This is also the target for the approval gate's "Contact support" (DD-08).

---

## Prototype elements not adopted (summary)

| Prototype element | Why it's not adopted |
|---|---|
| Referral tab, QR, transfer | DD-22 |
| Withdraw sheet | DD-21 |
| Ticker; sound toggle; drawer online toggle | DD-05 |
| Earnings card; QR FAB | DD-07 |
| Pay-success overlay | DD-18 |
| Replay route | DD-20 |
| Logout | OPEN, DD-05 |
| "New driver? Register"; step dots | DD-24 |
| Skip; boot log | DD-23 |
| Passenger and driver ratings | DD-15, DD-31 |
| Request "away" distance and request-stage fare | DD-15 |
| Countdown tick sound | DD-16 |
| Emoji toasts | DD-27 |
