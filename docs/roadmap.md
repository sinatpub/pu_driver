# pu_driver UI Redesign — Implementation Roadmap

**Purpose:** what to implement, in what order, and how to verify each step.
**Status:** planning only. No Dart, pubspec, asset or HTML file has been changed.

- **Behaviour truth:** `docs/reverse-engineering/` + the Flutter source.
- **Visual truth:** `docs/taarraa-driver-prototype.html` and `docs/ui-reference/`.
- **Approved translation between them:** `docs/ux-redesign/` (decisions are `DD-xx` in `07-design-decision-log.md`).

---

## 0. Rules that apply to every task

**Change only presentation:** widgets, layout, theme, components, visual hierarchy, copy keys.

**Never change** (verify your diff before opening a PR):

| Preserved | Lives in |
|---|---|
| Business logic, driver state machine, ride lifecycle | `features/trip/domain/`, `presentation/screens/booking/logic.dart` |
| API contracts, models, repositories, datasources | `features/*/data/`, `data/`, `core/network/` |
| Realtime: socket event names, payloads, emit order | `services/socket_service.dart`, `test/taxi_single_ton/` |
| Location services and reporting | `services/location_service.dart`, `data/datasources/update_driver_location_api.dart` |
| Auth and session | `services/session_service.dart`, `core/storage/` |
| Routes, route arguments, bindings | `routes/` |

**If a task appears to need a behaviour change: stop.** Mark it `REQUIRES EXPLICIT DECISION`, add it to `docs/ux-redesign/06-implementation-plan.md §4`, and ship the visual part without it.

**Working rules:**
- One task per PR. Never bundle redesign with refactoring, migration or a new feature.
- No new packages. Everything needed already exists (`flutter_svg`, `shimmer`, `google_maps_flutter`, `pinput`). The only permitted `pubspec.yaml` edits are **asset path lines** in F1.
- Reuse components from `docs/ux-redesign/04-component-specification.md`. Don't create a second button, card or dialog.
- Every screen handles loading, empty, error and offline states before it is "done".
- The light `ThemeData` lands in F1 and every screen migrates under it (`DD-34`). S5 only deletes the legacy tables.

**Verification tooling:**
- `dart analyze <path>` must be clean. Plain `flutter analyze` is broken in this environment.
- `flutter test` cannot run locally (`flutter_tester` is missing from the SDK cache); run it in CI or on another machine.
- Baseline artefacts from G0 are the regression oracle.

---

## 1. Gate — do this before writing any code

### G0 — Decisions and baseline
Three decisions are **OPEN** and block the tasks that depend on them. `DD-01` (light theme) and `DD-02` (action fill `#CC3700`) were settled by the user on 2026-09-12.

| Decision | Question | Blocks |
|---|---|---|
| `DD-05` | Does Logout come back into the drawer? | C1 |
| `DD-13` | Add a confirmation before Drop off? | C4 |
| `DD-33` | Should the trip error dialog keep closing the trip screen? | C5 |

Also `REQUIRES EXPLICIT DECISION`: the approval screen's new **Retry** and **Contact support** actions (`DD-08`). Both only call existing methods, but they are new user-facing actions.

**Baseline to record before the first PR:**
1. A device video of every screen and state listed in `docs/ux-redesign/05-interaction-and-states.md §1–§4`.
2. The `tlog` output of one complete trip (request → accept → arrive → start → drop → payment). **This is the socket-emit oracle** every trip task is verified against.

---

## 2. Dependency order

```
G0  decisions + baseline
 │
F1  tokens · light theme · typography
 │
F2  shared components ─────────────┐
 │                                 │
F3  sheets · dialogs · states      │
 │                                 │
C1  shell (app bar, drawer, pill, approval, offline banner)
 │
C2  home (map, status card, location states)
 │
C3  trip scaffold + request stage        ← highest risk
 │
C4  trip stages: to pickup · at pickup · in progress
 │
C5  trip dialogs and errors
 │
C6  payment
 │
 ├── S1 history + detail ── S2 wallet ── S3 announcements/terms/contact ── S4 auth
 │        (these four are independent of each other; all need F1–F3)
 │
S5  legacy token cleanup
 │
P1 motion · P2 copy/localization · P3 accessibility
 │
Q1 visual QA · Q2 functional regression · Q3 performance
```

**20 tasks.** C3 → C4 → C5 → C6 is the critical path; S1–S4 can run in parallel with each other once F3 lands.

---

# Phase 1 — Design Foundation

## F1 — Design tokens, light theme, typography

### Goal
One token source for colour, type, spacing, radius and elevation, plus a light `ThemeData` and the icon assets.

### Scope
- New: `lib/core/theme/tokens.dart` (`ThemeExtension`).
- The DS icon set moved to F2: no component consumes an icon until then, and bundling ~24 SVGs here would make this PR hard to review.
- Edit: `core/theme/{colors,text_styles,app_theme}.dart`, `main.dart` `configLoading` (`:60-74`, currently yellow on green).
- `pubspec.yaml`: asset path lines only.
- `app/root_main.dart:53` switches to the new light theme here (DD-34): the app is already light, so there is no mixed-theme period.

### Design References
- `docs/ux-redesign/02-design-system.md` (whole file — this task *is* that file)
- `docs/ux-redesign/07-design-decision-log.md` → `DD-01`, `DD-02`, `DD-03`, `DD-28`, `DD-30`, `DD-34`

### Behavior References
`docs/reverse-engineering/07-design-tokens-and-assets.md` (what exists today, and the `font10SemiBold` = 14 px bug)

### Dependencies
G0 (`DD-01`, `DD-02` — both settled)

### Risk
**Medium.** Two unknowns: whether Kantumruy Pro ships tabular figures (O-1) and whether the variable face is registered so `FontWeight.w700` resolves (O-2). Both have documented fallbacks in `02 §2`.

### Verification
- A debug-only token sampler screen rendered on a device in EN and KM.
- Every pair in `02 §1.1` re-measured with a contrast checker; no text pair below 4.5:1, no border below 3:1.
- `dart analyze lib/core/theme`.

### Done When
- Tokens exist as semantic names; no component references a primitive.
- The new `ThemeData` is installed app-wide and no screen regresses visually.
- `ThemeConstands` and `AppColors` still compile untouched (they're removed in S5).

## F2 — Shared components

### Goal
Build the A-tier components so no screen invents its own button, field or row.

### Scope
`assets/icon/ds/*.svg` (moved from F1), then `lib/presentation/widgets/ds/`: `TButton`, `TIconButton`, `TTextField` (+ phone variant), `TCard`, `TBadge`, `TSegmented`, `TTabs`, `TChip`, `TAvatar`, `TKeyValueRow`, `TAddressRow`, `TAmount`.

### Design References
- `docs/ux-redesign/04-component-specification.md § A`
- `docs/ux-redesign/02-design-system.md §7–§9, §13`

### Behavior References
None. These are presentational. (`TTextField` takes formatters as a parameter; it never owns validation.)

### Dependencies
F1

### Risk
**Low.**

### Verification
- Widget tests for each component's states: default, pressed, disabled, loading, error, selected.
- Touch targets ≥48 px, checked in the Flutter inspector.

### Done When
- Every variant in `02 §7` renders.
- `TAmount` never formats money itself; it takes pre-formatted strings from the existing helpers.

## F3 — Sheets, dialogs, toast, banner, state views

### Goal
Re-skin the overlay layer **without changing how any dialog dismisses or navigates.**

### Scope
- New: `TSheet`, `TToast`, `TBanner`, `TEmptyState`, `TErrorState`, `TSkeleton`.
- Re-skin in place, keeping the existing function signatures: `widgets/{yesno_dialog_widget,error_dialog_widget,cancel_book_dialog_widget,process_book_dialog_widget,simmer_widget}.dart`.

### Design References
- `docs/ux-redesign/04-component-specification.md § A` (TDialog entry)
- `docs/ux-redesign/02-design-system.md §10–§11`
- `07` → `DD-25`, `DD-27`, `DD-33`

### Behavior References
`docs/ux-redesign/05-interaction-and-states.md §8` (the dialog catalogue: trigger, dismissibility, navigation, per dialog)

### Dependencies
F1, F2

### Risk
**High** — this is the easiest place to silently break navigation.
- `showErrorCustomDialog(..., comfirmBook: true)` pops **twice**: it closes the dialog *and* the route beneath it. Keep that.
- `showCancelBookingDialog` owns a 10 s timer that navigates home. The new progress bar is **decoration only**; do not add a second timer.

### Verification
For each of the six dialogs: trigger it on a device and confirm the route afterwards matches the G0 baseline video.

### Done When
- No call site changed.
- Dismissal, barrier behaviour and navigation are identical to the baseline.

---

# Phase 2 — Core Driver Experience

Driver flow, taken from the real state machine (`TripStage` in `features/trip/domain/trip_state_machine.dart`):

```
offline ⇄ online  →  requestReceived  →  enRouteToPickup  →  waitingAtPickup
                                                                   ↓
                          payment (pendingPayment) ← completing ← inProgress
```
There is no separate "accepted" state: accepting moves straight to `enRouteToPickup`.

## C1 — App shell

### Goal
App bar, drawer, online pill, approval gate and offline banner.

### Scope
`presentation/screens/drawer/view.dart`, `home/widgets/switch_online_widget.dart`, `profile/widgets/profile_header_widget.dart`. Logic files are read-only.

### Design References
- `docs/ux-redesign/03-screen-redesign.md § Screen: App shell`
- `docs/ux-redesign/04-component-specification.md § B` (OnlineStatusPill, ApprovalGate, OfflineBanner, DriverDrawer)
- `07` → `DD-05`, `DD-06`, `DD-08`, `DD-09`, `DD-26`

### Behavior References
- `docs/reverse-engineering/02-auth-and-session.md §8` (approval mapping, online gating)
- `docs/ux-redesign/05-interaction-and-states.md §1`

### Dependencies
F1–F3, G0 (`DD-05`)

### Risk
**Medium.** The approval gate must keep failing closed: `unknown` is not approved. The pill must keep refusing while unapproved, and `fetchCurrentDriveInfo` must still fire exactly once from `DrawerLogic.onInit`.

### Verification
- Approval: a pending account; a rejected account; `unknown` forced by launching in airplane mode.
- Toggle online and offline, including a failure with the network off — the optimistic value must visibly roll back.
- Drawer navigation to all five tabs; language switch.

### Done When
- Pending, rejected and still-checking each look different.
- The online pill is still only on the home tab.
- The banner renders nothing while connected.

## C2 — Home tab

### Goal
Map overlays, driver status card, real location states, force-update and resume dialogs.

### Scope
`home/view.dart`, `widgets/widge_update.dart`, `widgets/process_book_dialog_widget.dart`. `home/logic.dart` is read-only.

### Design References
- `docs/ux-redesign/03-screen-redesign.md § Screen: Home tab`
- `07` → `DD-07` (no earnings card — there is no endpoint and the earnings basis is an open business question), `DD-28`, `DD-32`

### Behavior References
- `docs/reverse-engineering/05-location-and-maps.md §1–§2`
- `docs/reverse-engineering/03-driver-and-ride-domain-model.md §4` (resume routing)

### Dependencies
C1

### Risk
**Medium.** Map style and padding only; the camera keeps following every GPS tick (changing that is `B12`, a separate change).

### Verification
- Deny then grant location permission; kill GPS.
- Online and offline card states.
- Resume: kill the app mid-trip and reopen it — the 2 s dialog then `/booking` at the correct stage.

### Done When
- No hardcoded English remains on this screen.
- The map's bottom padding keeps the Google logo visible.

## C3 — Trip screen: scaffold and request stage

### Goal
Full-bleed map, floating stage header, countdown, persistent sheet with timeline, and the Accept/Cancel action bar.

### Scope
- `booking/view.dart` — **`build()`, the AppBar removal and imports only.**
- `booking/widgets/ride_request_bottom_pop_widget.dart` (same class name and constructor, plus an `isLoading` input).
- `widgets/count_down_widget.dart` — **`build()` only**; `initState` and the expiry listener are untouched.

### Design References
- `docs/ux-redesign/03-screen-redesign.md § Screen: Trip` + `§ Stage: Request received`
- `docs/ux-redesign/04-component-specification.md § B` (TripScreenScaffold, TripHeader, RequestCountdown, TripTimeline, PassengerRow, TripSheet, TripActionBar)
- `07` → `DD-10`, `DD-11`, `DD-15`, `DD-16`, `DD-17`

### Behavior References
- `docs/ux-redesign/05-interaction-and-states.md §2` (the full request lifecycle)
- `docs/reverse-engineering/03-driver-and-ride-domain-model.md §3` (lifecycle ↔ REST ↔ socket map)

### Dependencies
F1–F3, C1

### Risk
**High — the highest in the project.**
- `_onTripAction` and `_onTripError` must not move or be reordered; they carry the socket emits.
- **Cancel must be disabled while `isLoading`.** Today a full-screen overlay blocks that tap. The redesign removes the overlay, and Cancel emits `driverCancelDrive` *before* the controller guard runs — so an enabled Cancel during an in-flight Accept would tell the passenger the trip was cancelled while the REST call never happens.
- Countdown expiry must still call `Get.offAllNamed('/home')`.
- `PopScope(canPop: false)` stays.

### Verification
Against the G0 `tlog` oracle, on a device:
- accept; accept conflict (two drivers, one ride); cancel; expiry; passenger cancel during the request;
- rapid double-tap on Accept;
- tap Cancel while Accept is in flight — **no `driverCancelDrive` may be emitted.**

### Done When
- Emitted events and payloads are byte-identical to the oracle.
- Accept is full width; Cancel is a text action ≥16 px below it.
- No fare, distance or rating is shown on the request (that data does not exist).

## C4 — Trip stages: going to pickup, at pickup, in progress

### Goal
Per-stage sheet content, the live meter strip, and estimate labelling.

### Scope
`booking/view.dart` (build), `booking/widgets/{ride_request_bottom_pop_widget,show_distand_and_price_widget}.dart`.

### Design References
- `docs/ux-redesign/03-screen-redesign.md § Stage:` (the three stage sections)
- `docs/ux-redesign/04-component-specification.md § B` (TripMeterStrip)
- `07` → `DD-12` (Drop off is not red), `DD-14` (label estimates as estimates)

### Behavior References
- `docs/reverse-engineering/03-driver-and-ride-domain-model.md §3.2` (fare and distance handling)
- `docs/reverse-engineering/05-location-and-maps.md §4, §6`

### Dependencies
C3

### Risk
**High.** The meter's three values must equal today's expressions in `booking/view.dart:661-676` exactly — the distance branch differs depending on whether the ride has a destination. Drop off must still call `getLocation(TripStage.completing)`, which reverse-geocodes before `complete()`.

`REQUIRES EXPLICIT DECISION` (`DD-13`): whether to add a confirmation before Drop off. Default is no — ship without it unless Product says otherwise.

### Verification
- One trip **with** a destination and one **without**; compare duration, distance and fare against the baseline video at the same points.
- Resume directly into each stage (server statuses 2, 8, 3).
- `tlog`: `rideArrival`, `startDrive`, `dropDrive` match the oracle.

### Done When
- The in-trip price reads "≈ Est. fare" with the estimate note; it is no longer labelled "TOTAL_PRICE".
- The meter stays visible when the sheet is collapsed.
- The Drop off spinner starts on tap, not after geocoding.

## C5 — Trip dialogs and errors

### Goal
Apply copy and icons to the trip dialogs; wire the three `TripActionError` variants.

### Scope
`booking/view.dart` call sites (unchanged signatures), `app/alert_widget.dart`.

### Design References
- `docs/ux-redesign/03-screen-redesign.md § Trip dialogs and events`
- `07` → `DD-25`, `DD-33`

### Behavior References
`docs/ux-redesign/05-interaction-and-states.md §8`

### Dependencies
F3, C3

### Risk
**Medium.** `REQUIRES EXPLICIT DECISION` (`DD-33`): today, tapping OK on any trip error closes the trip screen as well. That is right for "ride already accepted" and probably wrong for a failed arrive/start/drop. **Default: preserve it.** Only change it if Engineering and Product decide to, and then as its own PR with its own tests.

### Verification
Force each error: accept a ride already taken; pull the network during arrive, start and complete. Confirm the resulting route matches the baseline.

### Done When
All three error dialogs use localized keys, and dismissal behaviour matches the baseline.

## C6 — Payment

### Goal
Receipt, total box, success button, and the real payment method.

### Scope
`calculate_fee/view.dart`; error copy in `calculate_fee/logic.dart:78-81`.

### Design References
- `docs/ux-redesign/03-screen-redesign.md § Screen: Payment`
- `docs/ux-redesign/04-component-specification.md § B` (ReceiptCard + TotalBox)
- `07` → `DD-04` (money is neutral), `DD-18`

### Behavior References
`docs/reverse-engineering/03-driver-and-ride-domain-model.md §6` (both entry payloads, and the emit-after-REST order)

### Dependencies
F3, C4

### Risk
**Medium.** The amount must stay exactly `payment.amount` through the existing formatter. Navigation stays immediate — do not add the prototype's 1.6 s success overlay.

### Verification
- Both entry paths: drop-off, and resume with server status 6.
- The error path with the network off.
- `tlog`: `acceptPayment` fires after the REST call succeeds.

### Done When
- "Unknown Payment" is gone; the badge shows `payment.paymentMethod` or nothing.
- The total reads "Total to collect" in neutral text, not on a red bar.

---

# Phase 3 — Supporting Screens

These four are independent of each other. Any order; they can run in parallel.

## S1 — History and history detail

### Goal
Restyle the list and the detail screen.

### Scope
`history/view.dart`, `history/widgets/history_card_widget.dart`, `history_detail/view.dart`.

### Design References
`docs/ux-redesign/03-screen-redesign.md § Screen: History tab` and `§ Screen: History detail`; `07` → `DD-19`, `DD-20`

### Behavior References
`docs/reverse-engineering/06-screen-and-ui-inventory.md §2.7`

### Dependencies
F1–F3

### Risk
**Low.** The tap target moves from the fake map thumbnail to the whole card; it must pass the same `MapHistoryDetailArgs`, and cancelled trips must stay non-tappable.

### Verification
Paging, pull-to-refresh, an empty account, offline error; tap a completed card and a cancelled one.

### Done When
Completed and cancelled tabs both have real empty and error states, and the detail screen opens with identical arguments.

## S2 — Wallet

### Goal
Restyle balance cards, filter chips and transaction rows.

### Scope
`wallet/view.dart`.

### Design References
`docs/ux-redesign/03-screen-redesign.md § Screen: Wallet tab`; `07` → `DD-21`

### Behavior References
`docs/reverse-engineering/06-screen-and-ui-inventory.md §2.8`

### Dependencies
F1–F3

### Risk
**Low.** No withdraw UI (there is no API). Don't colour amounts by sign — the debit convention is unconfirmed.

### Verification
Loaded, empty and error states; every filter chip; a USD balance formats correctly.

### Done When
Cards use the existing labels only, with no invented sub-labels, and amounts render neutral and tabular.

## S3 — Announcements, Terms, Contact

### Goal
Restyle the three remaining content screens plus the announcement detail.

### Scope
`announcement/view.dart`, `announcement_detail/view.dart`, `term_condition/view.dart`, `contact_us/view.dart`.

### Design References
`docs/ux-redesign/03-screen-redesign.md § Screens: Announcements` and the Terms/Contact sections; `07` → `DD-06`

### Behavior References
`docs/reverse-engineering/04-realtime-architecture.md §7` (FCM routing into the detail screen)

### Dependencies
F1–F3

### Risk
**Low.** The bell entry point and the FCM deep link must keep working; no drawer tab is added.

### Verification
Open the detail from an FCM tap in both background and terminated states; unread styling; call and email launch.

### Done When
The list has an empty state, and unread items use the border-and-dot treatment.

## S4 — Auth: splash, login, OTP, register

### Goal
Restyle the four auth screens.

### Scope
`splash_screen/view.dart`, `login/view.dart`, `otp/view.dart`, `register/view.dart`.

### Design References
`docs/ux-redesign/03-screen-redesign.md` → the four sections `# Screen: Splash (S01)`, `# Screen: Login (S02)`, `# Screen: OTP (S03)`, `# Screen: Register (S04)`; `07` → `DD-23`, `DD-24`

### Behavior References
`docs/reverse-engineering/02-auth-and-session.md §3, §5–§7`

### Dependencies
F1–F3

### Risk
**Medium** — validation quirks are easy to "fix" by accident:
- The phone check rejects under **10 characters of the formatted text**, even though the flag is named for 8 digits. Keep the check.
- Register is enabled unless name **and** plate are both empty. Do not adopt the prototype's stricter rule.
- No "New driver? Register" link, and no Skip on splash.

### Verification
- `test/presentation/screens/login/logic_test.dart` stays green.
- Manual: empty phone, 9-character phone, formatted phone with spaces, wrong OTP, resend, register enable and disable.

### Done When
Validation behaviour is identical to the baseline, and the OTP still auto-submits on the 4th digit.

## S5 — Legacy token cleanup

### Goal
Delete the superseded style tables now that every screen uses tokens.

### Scope
`core/theme/*` — remove `ThemeConstands`, `AppTextStyles` and the superseded `AppColors` members.

### Design References
`07` → `DD-34`

### Behavior References
None.

### Dependencies
**All of C1–C6 and S1–S4.**

### Risk
**Medium.** There are ~307 `Colors.*` literals and ~111 `ThemeConstands` references in `lib/presentation` today; stragglers surface as off-palette greys and oranges.

### Verification
`grep -rn 'Colors\.\|Color(0x\|ThemeConstands\|AppTextStyles' lib/presentation` returns nothing meaningful, then walk every screen in both locales.

### Done When
`ThemeConstands` and `AppTextStyles` are deleted rather than left commented out, and no screen references a legacy colour.

---

# Phase 4 — Polish

## P1 — Motion and micro-interactions

### Goal
Apply the motion spec, and honour reduced motion.

### Scope
Transitions in the components from F2–F3 and the trip stage changes.

### Design References
`docs/ux-redesign/02-design-system.md §15`

### Behavior References
None.

### Dependencies
S5

### Risk
**Low.** `/home` must keep `Transition.noTransition`. Money values never animate.

### Verification
Enable "Remove animations" in OS accessibility settings: pulses stop, sheets and dialogs fade only.

### Done When
Nothing animates longer than 300 ms except the map camera.

## P2 — Copy and localization sweep

### Goal
Land the new translation keys in EN and KM, and remove the remaining hardcoded English.

### Scope
`assets/translations/{en,km}.json`; the call sites listed in `docs/ux-redesign/06-implementation-plan.md §3`.

### Design References
`docs/ux-redesign/06-implementation-plan.md §3` (the full key table with KM drafts from the prototype)

### Behavior References
`docs/reverse-engineering/07-design-tokens-and-assets.md §4` (which keys double as notification titles)

### Dependencies
The screen tasks that introduce each key.

### Risk
**Medium.** `ACCEPT`, `ARRIVE` and `START_RIDE` are reused as local-notification titles. **Add new keys; never edit those values.**

### Verification
A native Khmer reviewer signs off the drafts; run the app fully in KM at text scale 1.3.

### Done When
No hardcoded user-facing English remains, and the notification titles are unchanged.

## P3 — Accessibility pass

### Goal
Labels, targets and contrast verified on real screens.

### Scope
All redesigned screens.

### Design References
`docs/ux-redesign/02-design-system.md §1.2, §13`

### Behavior References
None.

### Dependencies
S5

### Risk
**Low.**

### Verification
TalkBack or VoiceOver through the full trip flow; every icon-only button announces a label; no target under 48 px; no text under 12 px.

### Done When
The trip flow is completable with a screen reader, and the text-scale clamp of 1.0–1.3 clips nothing.

---

# Phase 5 — QA

## Q1 — Visual QA against the prototype

### Goal
Confirm the Flutter UI matches the target direction.

### Scope
Every redesigned screen.

### Design References
`docs/taarraa-driver-prototype.html` (open in a browser at ~400 px wide), `docs/ui-reference/02-screen-map.md`

### Behavior References
None.

### Dependencies
S5, P1–P3

### Risk
**Low.**

### Verification
Side-by-side screenshots per screen. Check spacing, radius, type scale and state colours. Any deliberate divergence must already be a `DD-xx` entry — if it isn't, it's a bug.

### Done When
Every screen in `docs/ux-redesign/03-screen-redesign.md` has a side-by-side pair, and divergences are all traceable to decisions.

## Q2 — Functional regression

### Goal
Prove no behaviour changed.

### Scope
Whole app, on a real device.

### Design References
None.

### Behavior References
- `docs/ux-redesign/05-interaction-and-states.md §11` (the 23-row preserve checklist — **this is the test plan**)
- G0 baseline video and `tlog` oracle

### Dependencies
S5

### Risk
**High** if skipped; this is the task that catches everything else.

### Verification
| Area | Cases |
|---|---|
| Driver states | offline ⇄ online, approval pending/rejected/unknown, toggle failure rollback |
| Ride lifecycle | full trip with destination; without destination; decline; expiry; passenger cancel; accept conflict |
| Realtime | socket emits vs oracle; kill the network mid-trip and confirm emits are buffered and flushed; reconnect after 10+ minutes offline |
| Network failure | REST failure at every trip action; offline banner; wallet and history error states |
| Location / GPS | permission denied, then granted; GPS off mid-trip; distance accumulation on a no-destination trip |
| Navigation | resume into each stage; back behaviour; FCM deep links cold and warm; `/home` stack clearing |
| Session | 401 handling still logs out and stops GPS |

### Done When
Every row of the preserve checklist is ticked with evidence, and `flutter test` passes in CI (including the socket contract tests).

## Q3 — Performance review

### Goal
Confirm the redesign didn't make the map screens heavier.

### Scope
Home and trip screens.

### Design References
None.

### Behavior References
None.

### Dependencies
Q1, Q2

### Risk
**Low.**

### Verification
DevTools on a mid-range Android: frame timings while panning the map with the sheet open; check for rebuild storms in the trip screen (the GPS listener calls `setState` on every tick today — that is pre-existing; don't fix it here, just measure it).

### Done When
No sustained jank above 16 ms on the trip screen, and memory is stable across a full trip.

---

## Appendix — Known issues deliberately out of scope

These were found during analysis and are **not** part of the redesign. Each needs its own decision, PR and tests. Full list with evidence in `docs/ux-redesign/06-implementation-plan.md §4`.

| ID | Issue |
|---|---|
| B1 | The trip error dialog's OK also closes the trip screen (`DD-33`) |
| B2 | `driverCancelDrive` is emitted before the REST cancel, and regardless of its result |
| B3 | The countdown can expire while an Accept is in flight |
| B4 | The passenger-cancel dialog navigates home even after OK is tapped |
| B5 | Approval stays `unknown` forever if the fetch fails |
| B7 | Connectivity is only observed in the shell, so no offline banner on the trip screen |
| B12 | The camera re-centres at zoom 19 on every GPS tick |
| B13 | Resume maps cancelled and completed rides to "go to passenger" (M-21) |
