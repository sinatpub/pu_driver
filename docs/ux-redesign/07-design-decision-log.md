# 07 — Design Decision Log

Each decision is recorded once. Other docs reference them as `DD-xx`. **Status** is DECIDED (made in this analysis, reversible only with a new entry) or OPEN (needs the named owner). Don't re-open a DECIDED entry without adding a superseding one.

**OPEN, needing an owner before the related step:**

| Decision | Topic | Owner |
|---|---|---|
| DD-05 | Logout | Product |
| DD-33 | Error-dialog semantics | Engineering + Product |
| DD-45 | Invite: what a driver earns for inviting a passenger; code format; link domain; the referral endpoints | Product + Backend |

---

## Decision DD-01: The app stays light

**Supersedes the original dark-theme decision (2026-09-11). Settled by the user on 2026-09-12.**

### Context
Three sources disagreed on the theme. The user has now settled it: the mobile app is light mode.

### Existing Behavior
- `AppTheme.lightTheme` only (`core/theme/app_theme.dart`, `app/root_main.dart:53`).
- `../ux_ui_design/ui-layout-system.md` is "Light only" (§14).

### HTML Design
A single dark palette (HTML:9-19, `theme-color #101216`).

### Decision
- **Light is the target.** The prototype supplies layout, structure, components, hierarchy and interaction patterns; **not** its surface colours.
- Colour is rebuilt as a measured light palette from the app's existing `AppColors` plus `ui-layout-system.md` (`02 §1`).
- Dark mode is not built. Semantic tokens keep it reachable later.

### Reason
- The user's direction.
- It matches both the shipped app and the repo's own design system, so the earlier conflict disappears.
- The prototype's value was never its darkness — it is the map-first shell, the sheet-driven trip flow, the timeline and the status language, all of which survive the change.

### Impact
- `02 §1` and §5 were rewritten; every colour pair re-measured on light surfaces.
- Several prototype colours become graphics-only on white: `#FF4500` (3.44), `#10CF7C` (2.05), `#FFB020`.
- No dark map style is needed, which removes an asset and an open question (DD-28).
- No per-route theme migration is needed, because the app is already light (DD-34).

## Decision DD-02: Split the brand into identity `#FF4500` and action fill `#CC3700`

### Context
Readable button labels. There are three brand values:
- Flutter and HTML: `#FF4500`.
- `ux_ui_design`: `#DB4C25` identity / `#BA401F` action.

### Existing Behavior
`FBTNWidget` draws white on `AppColors.main #FF4500`: 3.44:1, which fails AA.

### HTML Design
White on a gradient `#FF6A00→#FF4500`: 2.87–3.44:1.

### Decision
- Identity stays `#FF4500` for **graphics only**: logo, route line, markers, countdown arc — 3.44 on white, which clears the 3:1 non-text floor but not the text floor.
- Brand-coloured **text** and links use `#CC3700` (5.10).
- Button fill is `#CC3700` — already `AppColors.darker` — with an optional gradient top `#D93B00`. White label: 5.10 / 4.59.
- `#DB4C25` isn't adopted for the driver app.
- **DECIDED by the user, 2026-09-12.**

### Reason
- It keeps the prototype's white-on-orange look and passes AA.
- It reuses an existing token.
- The alternatives were rejected:
  - Dark text on `#FF4500` (5.45) reads as a warning chip, not a button.
  - A 19 px "large text" label is fragile once Khmer is rendered.

### Impact
All primary buttons; `02 §1`.

## Decision DD-03: The accessibility floors override prototype values

### Context
The prototype falls below several measured floors.

### Existing Behavior
- 42 px buttons (`fbtn_widget.dart`).
- A `font10SemiBold` 14 px bug.
- No Khmer line heights.

### HTML Design
- 11 px uppercase labels; a 46 px small button; a 42 px icon button.
- Muted text at 3.66:1; borders at 1.45:1.

### Decision
- Minimum 12 px.
- 48 px targets; 56 px CTAs.
- No all-caps.
- Secondary text `#6B7588`; control borders `#8F90A6`.
- Khmer line heights.
- Tabular numerals.

### Reason
- `ui-layout-system.md §3, §4, §13`.
- Drivers read at arm's length, in motion.

### Impact
- A few values differ from the prototype; the look is kept.
- See `02 §1.2`.

## Decision DD-04: Money renders neutral

### Context
Colour on money.

### Existing Behavior
- Wallet amounts are neutral (`wallet/view.dart:299-303`).
- The payment total sits on a red bar (`calculate_fee/view.dart:369-393`).
- The in-trip price is blue.

### HTML Design
- In/out amounts are green / red.
- A green total box.
- Green meter values.

### Decision
- Ledgers, receipts and totals use `text.primary`, tabular.
- The in-trip meter keeps a green **stage-tinted container**, because it marks the stage, not the money.
- The success colour is reserved for confirmation.

### Reason
- `ui-layout-system.md §2` rule 3 and constraint C2: next to a red-orange brand, red reads as failure.
- The wallet's debit sign convention is UNCLEAR.

### Impact
Wallet, history, payment.

## Decision DD-05: Drawer contents

### Context
The prototype's drawer has more items than the app supports.

### Existing Behavior
- Items: Home, History, Wallet, Terms, Contact, Language.
- CHANNEL and Logout are commented out (`drawer/view.dart:202-218, 252-298`).
- `AlertWidget.logout` exists and works: it clears storage, stops GPS and goes to `/login`.

### HTML Design
Adds Referral, Announcements, an online row, a sound toggle, a language segmented control, Logout, a version line, and a ticker under the app bar.

### Decision
- Keep today's items, in the new style.
- Language becomes a segmented control.
- **Not added:**
  - Referral (DD-22).
  - Announcements tab (DD-06).
  - Online row: a second entry point to the same action.
  - Sound toggle: no setting exists.
  - Ticker: no data source, and it distracts while driving.
- **Logout stays hidden — OPEN (Product).** If approved, use the prototype pattern: a red row at the bottom and a confirm dialog that says GPS will stop. That's accurate, because logout calls `LocationService.instance.stop()`.

### Reason
Adding items adds behaviour. Logout's removal was a product choice (U5).

### Impact
`03 S05`.

## Decision DD-06: Announcements stay a pushed route from the bell

### Context
Where Announcements live.

### Existing Behavior
- Bell → `/notification` (`drawer/view.dart:84-93`). FCM deep links go to `/notification-detail`.
- The drawer tab is commented out (Q3 open).

### HTML Design
A drawer tab and a ticker.

### Decision
Keep the route and the bell (restyled as a 48 px icon button). No drawer tab until Q3 is answered.

### Reason
The route is also the FCM target; moving it changes navigation.

### Impact
`03 S12`.

## Decision DD-07: No earnings card or QR FAB on Home

### Context
The prototype's Home content.

### Existing Behavior
- No earnings UI.
- The earnings domain is pure. `TripEarningBasis` has no default by design, and no endpoint exists (`features/earnings/domain/earnings.dart:26-47`).

### HTML Design
A "Today · N trips · ៛amount" card and a referral QR FAB.

### Decision
- Replace the card with `DriverStatusCard`: online / offline, no money.
- No QR.

### Reason
Showing earnings would mean guessing the money — an open business question. The referral backend doesn't exist.

### Impact
`03 S06`. Revisit when N-09's basis is decided.

## Decision DD-08: Approval gate shows three distinct states

### Context
Presenting approval.

### Existing Behavior
- Any `!isApproved` — `unknown` pre-fetch, `pending`, `rejected` — shows the same "WAITING_APPROVED_FROM_ADMIN" panel (`drawer/view.dart:344-379`).
- The gate fails closed.
- A fetch error leaves the state at `unknown` (`app/logic.dart:43`).

### HTML Design
Pending (amber clock) and rejected (red X, with a reason), plus "Contact support". Full-screen, covering the app bar.

### Decision
- The body-only gate uses `approvalStatus`:
  - unknown → "Checking…" + Retry (`fetchCurrentDriveInfo`)
  - pending → amber + `WAITING_DES`
  - rejected → danger + generic copy (no reason field)
- "Contact support" → `ContactUsLogic.callPhone`.
- The app bar stays reachable.

### Reason
- A rejected driver being told to wait is wrong.
- Everything needed is in the existing enum.
- A reachable app bar preserves today's access to the drawer.

### Impact
`03 S05`. Retry calls an existing method (PROPOSED, low risk: an idempotent read, INFERRED).

## Decision DD-09: Online pill keeps today's toggle logic

### Context
The online toggle.

### Existing Behavior
- `FlutterSwitch`.
- Unapproved → `EasyLoading.showToast`.
- `AppLogic.toggle` is optimistic, shows EasyLoading and rolls back on error.
- No check on network state.

### HTML Design
A pill. Toggling is blocked with a toast when there's no internet.

### Decision
- Pill visual with a busy state.
- The same `onToggle` code path.
- **No new network block.**
- EasyLoading is kept, re-themed through `configLoading`.
- The status card is informational only, so there's a single toggle entry point.

### Reason
Blocking on connectivity is new behaviour. Removing EasyLoading means changing the controller (B14).

### Impact
`03 S05`.

## Decision DD-10: Trip screen layout

**Partly superseded by DD-35 (2026-09-29):** at the request stage there is no floating header and no stepper.

### Context
The trip screen's layout.

### Existing Behavior
- A stage title AppBar.
- A white `ExpansionTile` sheet.
- A strip at the top of the map.
- A floating countdown circle.

### HTML Design
- A full-bleed map.
- A floating trip card **and** a separate status pill.
- A countdown ring.
- A sheet with a timeline and a CTA.

### Decision
- A full-bleed map.
- **One** floating `TripHeader`: the trip card and status pill merged, with stage palette, pulse, title and `#code`.
- The countdown under it.
- A persistent sheet: timeline → collapsible content (the meter stays visible) → **pinned** action bar.
- The collapse default mirrors today's `isExpanded` init.

### Reason
- Less over the map while driving.
- The primary action never scrolls away (layout-system §7).

### Impact
`03 S07`, `04 B`.

## Decision DD-11: Accept and Cancel are separated

### Context
Mis-tap risk on the request stage.

### Existing Behavior
- Cancel (a 1/3-width filled dark button) sits next to Accept (2/3), 18 px apart.
- There's a confirm dialog.
- The socket emit fires before the REST call (`ride_request_bottom_pop_widget.dart:341-398`).

### HTML Design
Accept full width; a red text "Cancel" below; a confirm dialog with "Yes, cancel" (danger) and "Stay" (primary).

### Decision
- Adopt the prototype.
- Cancel is a 48 px tertiary-danger action, ≥16 px below Accept.
- In the dialog, "Stay" is the primary.
- `onYes` is unchanged.

### Reason
An accidental decline is costly and can't be undone.

### Impact
`TripActionBar`.

## Decision DD-12: CTA styling per stage

### Context
CTA colour by stage.

### Existing Behavior
Every CTA is orange at 42 px.

### HTML Design
- Accept and Arrived: orange.
- Start ride: green.
- Drop off: a filled red gradient.

### Decision
- Accept, I've arrived and Drop off: `primary`.
- Start ride: `success` fill with a white label.
- **Drop off is not red.**

### Reason
- Red means error or destructive.
- Drop off is a forward action.
- Keeping the colour consistent builds muscle memory.
- The stage is already shown by the header and timeline.

### Impact
`02 §7`.

## Decision DD-13: Drop-off confirmation — settled by DD-38

**Settled by the user on 2026-09-30: hold-to-confirm. See DD-38.**

### Context
Drop off is irreversible. It completes the trip at the current GPS point and triggers fare computation.

### Existing Behavior
A single tap; no confirmation.

### HTML Design
A single tap.

### Decision
**Default: no extra step** (preserve). A confirmation dialog, or hold-to-confirm, is recommended for review by Product/Ops.

### Reason
Adding a step changes the interaction flow and adds friction at every trip end.

### Impact
If approved, a `TDialog.confirm` goes before `getLocation(TripStage.completing)`. No logic change.

## Decision DD-14: Estimates are labelled as estimates

### Context
In-trip price labelling (R8).

### Existing Behavior
The in-trip price is labelled `TOTAL_PRICE` but comes from client-side `estimateFare` (`booking/view.dart:669-675`, `core/utils/fare_estimate.dart`).

### HTML Design
"≈ Est. fare" + "≈ estimated — server confirms the final fare".

### Decision
- Adopt the "≈" prefix, the "Est. fare" label and the note.
- Values and formatting are unchanged.
- The payment screen shows only the server amount (DD-18).

### Reason
Fixes the misleading label at zero logic cost.

### Impact
`TripMeterStrip`, the at-pickup key-value row.

## Decision DD-15: Request-stage content is limited to real data

**Superseded by DD-35 (2026-09-29).** The request stage now shows the time and distance to the pickup, and the trip distance and an estimated fare, all from Directions routes.

### Context
The prototype's request stage shows data the app doesn't have.

### Existing Behavior
- The payload has: passenger name, phone and photo; pickup and destination coordinates; the booking code.
- No rating, no pickup distance.
- Fare and distance are only computed from waiting-at-pickup onward.

### HTML Design
Passenger rating, "0.4 km away", distance and est. fare at request.

### Decision
- Show the passenger, the pickup address, the destination address (when present) and the booking code.
- No rating, "away", distance or fare.

### Reason
- These would need new data or new API calls (Directions at request time).
- The rule is to show no fabricated numbers.

### Impact
`03 S07` request stage.

## Decision DD-16: Countdown is re-skinned only

**Partly superseded by DD-35 (2026-09-29):** the countdown is now drawn inside Accept instead of floating over the map. The timer, the expiry navigation and the no-sound rule are unchanged.

### Context
The request countdown.

### Existing Behavior
- `SmoothCircularCountdown`: a 100 px white circle, English "seconds".
- On expiry, `offAllNamed(home)`, silently.

### HTML Design
- A ring pill with "to decide"; amber at ≤10 s plus a tick sound.
- An "expired" toast.

### Decision
- A new `build()` inside the same `State`.
- The amber ≤10 s change is **visual only**.
- **No sound.**
- The expiry toast is optional, P3.

### Reason
Sound is new behaviour. The timer engine and navigation have to stay identical.

### Impact
`count_down_widget.dart`.

## Decision DD-17: In-flight trip actions disable all trip actions

### Context
What happens while a trip action is in flight.

### Existing Behavior
A full-screen `LoadingWidget` blocks all input while `isLoading` (`booking/view.dart:718`).

### HTML Design
No loading state.

### Decision
- The tapped CTA shows a spinner.
- Every other trip action, **including Cancel**, is disabled.
- Call stays enabled.
- The full-screen overlay is removed.

### Reason
- The overlay hides the map and doesn't say what's running.
- **Cancel emits the socket event before the controller guard.** Without the overlay, an enabled Cancel during an accept would emit `driverCancelDrive` while `cancel()` returns early (`booking/logic.dart:61`).

### Impact
The sheet receives `isLoading`. This is a required acceptance check in step 5.

## Decision DD-18: Payment screen shows server figures, no success overlay

**Still in force; the layout and wording are reworked by DD-39 (2026-09-30).** Server amount only, method badge only when present, immediate navigation.

### Context
The payment screen's figures and completion flow.

### Existing Behavior
- The server `payment.amount`.
- A hardcoded "Unknown Payment" method.
- Immediate `offAllNamed(home)` after success.

### HTML Design
- Server fare plus an estimate line.
- A "Cash" badge.
- A 1.6 s success overlay.

### Decision
- The server amount only.
- A method badge from `payment.paymentMethod` when present.
- Immediate navigation, as today.

### Reason
- Two numbers on a money screen invite disputes.
- The estimate isn't passed to this route.
- A delay changes timing.
- Layout-system §11: no full-screen success moments.

### Impact
`03 S08`. The method display replaces a hardcoded string (a display fix).

## Decision DD-19: The history card replaces the map thumbnail as the tap target

**Still in force; the card's layout is reworked by DD-40 (2026-10-01).** The whole completed card is the tap target; cancelled cards are not tappable.

### Context
How a history card opens its detail.

### Existing Behavior
- A static `image_map.png` thumbnail is the only tap target.
- Completed trips only (`history_card_widget.dart:199-229`).

### HTML Design
The whole card is tappable; no thumbnail.

### Decision
- The whole **completed** card is tappable, with the same args.
- Cancelled cards aren't tappable.
- The thumbnail is removed.

### Reason
The thumbnail is a fake image. A bigger target is better.

### Impact
`HistoryCard`.

## Decision DD-20: History detail shows only what its args carry

**Superseded by DD-42 (2026-10-01).** The route args now carry the whole trip. Still no replay.

### Context
What the history detail screen can display.

### Existing Behavior
- `MapHistoryDetailArgs` carry no invoice, passenger or date.
- A full-screen map.

### HTML Design
- An invoice header, a minimap and a detail card.
- Replay route.

### Decision
- Map at the top, a key-value card below, title "Trip details".
- No replay.
- Extending the args is a separate change.

### Reason
No route-arg changes in a redesign. Replay is a new feature.

### Impact
`03 S10`.

## Decision DD-21: Wallet — no withdraw, no invented sub-labels

**Partly superseded by DD-43 (2026-10-01):** the user defined what the commission card and `debted` mean, so the wallet is one balance with a commission-rate note and a debt warning. Still no withdraw and no top-up — there is no API.

### Context
The prototype's wallet features and labels.

### Existing Behavior
- Commission-fare and wallet cards; dynamic filters.
- Top-up commented out.
- No withdraw API.

### HTML Design
- A Withdraw sheet (KHQR / ABA / Wing).
- "Available to withdraw" and "Owed to Taarraa" sub-labels.
- In/Out chips.

### Decision
- The prototype's card visuals, with the existing labels only.
- The existing dynamic filters.
- No withdraw.

### Reason
- There's no API.
- What the commission card means is UNCLEAR (`docs/reverse-engineering/06 §5`).
- The in/out sign convention is UNCLEAR.

### Impact
`03 S11`.

## Decision DD-22: Referral isn't part of this redesign

**Superseded by DD-45 to DD-47 (2026-10-01): the invite QR, the rewards and the sign-up invite code are built, on mock data. The rules are the user's, not the copy deck's.**

### Context
The prototype's referral tab.

### Existing Behavior
- Pure domain only (`features/referral/domain/*`), with open questions U1–U3.
- No backend (Q-4).
- Transfer is blocked (`../.agent/DECISIONS.md`).

### HTML Design
A full Refer & Earn tab, with invented rules: 1% reward, $5 minimum top-up, 7-day hold, $2.50 minimum transfer, 1 USD = ៛4,100, a decorative QR.

### Decision
- Not built.
- When it is built, it follows `ux_ui_design/referral-ux-copy-deck.md` + `ui-layout-system.md §9` + the referral domain.
- **The prototype's referral business rules aren't requirements.** Only its visual components (cards, tabs, rows) may be reused.

### Reason
Showing unconfirmed money rules to drivers is a trust and legal risk.

### Impact
None in this phase.

## Decision DD-23: Splash has no Skip and no fake boot log

### Context
The prototype's splash extras.

### Existing Behavior
3 s, permission request, token routing.

### HTML Design
A boot log (simulated) and "Skip →".

### Decision
A logo and wordmark only.

### Reason
Skip would shortcut the permission/session sequence. A fake log misstates what the app is doing.

### Impact
`03 S01`.

## Decision DD-24: Auth flow deviations from the prototype are rejected

### Context
The prototype's auth flow differs from the app's.

### Existing Behavior
- Register is reached only when OTP returns no driver or token.
- The register button is enabled unless name **and** plate are both empty.
- Phone check: `<10` characters.

### HTML Design
- A "New driver? Register" link.
- Step dots (1/3, 2/3, 3/3).
- Register requires name ≥2 characters and 4 photos.
- Phone check: 8 digits.

### Decision
- No link.
- No step dots: the flow's length isn't known at login.
- Validation rules unchanged.

### Reason
All three would change behaviour. The phone check is a documented quirk (RULES).

### Impact
`03 S02–S04`.

## Decision DD-25: Passenger-cancel dialog — new visual, same timer

### Context
The passenger-cancel dialog.

### Existing Behavior
A 10 s `Future.delayed` inside `builder` → `offAllNamed(home)`. `close` is never set; the YES button → home; the barrier isn't dismissible.

### HTML Design
A red title, a draining progress bar (`.autobar`), OK.

### Decision
- Adopt the visual.
- The progress bar is a purely visual animation over the same 10 s.
- **No second navigating timer.**
- The quirks are preserved and logged as B4.

### Reason
Fixing the timer is a realtime behaviour change.

### Impact
`TDialog.autoDismiss`.

## Decision DD-26: The offline banner is amber and lives in the shell only

### Context
The offline banner.

### Existing Behavior
- A red full-width "No internet connection" banner.
- Shell only (`drawer/view.dart:321-343`).
- Socket state isn't observable.

### HTML Design
A floating red pill, "No internet — reconnecting…".

### Decision
- An amber pill with the prototype's copy. It's truthful: the socket retries forever.
- Shell only, for now.
- No socket indicator.

### Reason
- Red next to the brand reads as a crash (layout-system §11 uses warning).
- Extending it to other routes needs shared state (B7).
- A socket indicator needs an exposed stream (B6).

### Impact
`OfflineBanner`.

## Decision DD-27: Feedback channels

### Context
In-app feedback for events.

### Existing Behavior
- Trip transitions post local notifications (`Taxi.shared.notifyBooking`).
- The toggle refusal uses `EasyLoading.showToast`.

### HTML Design
Toasts for ~40 events, many with emoji.

### Decision
- Keep the local notifications.
- **No duplicate toasts** for the same events.
- `TToast` is only for new presentation feedback: the optional expiry notice, or a toggle refusal once migrated.
- No emoji.

### Reason
Double feedback is noise while driving.

### Impact
`04 TToast`.

## Decision DD-28: Map presentation

**Superseded for every trip stage by DD-35–DD-38 (2026-09-30):** each stage frames its route (or, on a trip with no destination, follows the car at a neighbourhood zoom) instead of zoom 19, and hides the zoom buttons.

### Context
How the map looks and behaves.

### Existing Behavior
- Google Maps, light.
- A red 5 px polyline.
- Default controls, zoom 19, the camera following every tick.

### HTML Design
A procedural dark SVG map (a placeholder); a brand-coloured route.

### Decision
- Keep Google Maps with its **default light styling** — no style JSON and no new asset.
- `brand.identity` route line.
- The same markers.
- Map bottom padding = sheet or card height.
- Camera behaviour unchanged (U7 → B12).

### Reason
Changing the camera is map logic, and it belongs in a separate change.

### Impact
`02 §14`.

## Decision DD-29: New copy goes into new translation keys

### Context
New labels are needed ("I've arrived", "Drop off", …).

### Existing Behavior
`ACCEPT`, `ARRIVE` and `START_RIDE` double as notification titles (`booking/logic.dart:46-112`).

### HTML Design
New wording.

### Decision
- Add keys (`06 §3`) in en and km.
- km drafts come from the prototype's `I18N`, with native review.
- Never edit values that other features share.

### Reason
Editing values would silently change notifications.

### Impact
`assets/translations/{en,km}.json`, added in the implementation steps.

## Decision DD-30: Text scaling stays clamped at 1.0–1.3

### Context
How far text is allowed to scale.

### Existing Behavior
`textScaler.clamp(1.0, 1.3)` (`app/root_main.dart:41-42`).

### HTML Design
—

### Decision
- Keep the clamp.
- Every component uses a min-height, so a later change to the layout system's 200% target doesn't need a redesign.

### Reason
Changing the clamp is an app-wide behaviour change.

### Impact
Test at 1.3 (step 15).

## Decision DD-31: No ratings shown

### Context
Ratings in the UI.

### Existing Behavior
- `check-status` returns `rating` (`set_status_model.dart:31`), but `AppLogic` stores only `isOnline`.
- Passenger rating isn't in the request payload.

### HTML Design
Driver rating and trip count in the drawer; passenger rating on the request.

### Decision
- Omit both.
- Driver rating comes after a small `AppLogic` change (B11).

### Reason
No data reaches the view today.

### Impact
Drawer, `PassengerRow`.

## Decision DD-32: Resume dialog restyled, timing unchanged

### Context
The resume dialog.

### Existing Behavior
`showPocessBookingLoadingDialog`: a red button containing a spinner. Barrier-dismissible. `HomeLogic` navigates after 2 s regardless.

### HTML Design
—

### Decision
- `TDialog.progress` "Resuming your trip…".
- Still barrier-dismissible; the timer is untouched.

### Reason
Visual clarity without changing timing.

### Impact
`process_book_dialog_widget.dart`.

## Decision DD-33: The trip error dialog keeps its dismissal semantics — OPEN

### Context
How the trip error dialog dismisses.

### Existing Behavior
- `showErrorCustomDialog(context, …, true)`: OK calls `Navigator.pop` twice, which closes the dialog **and the trip screen**.
- A barrier tap closes only the dialog.
- Used for all three trip errors (`booking/view.dart:468-482`, `error_dialog_widget.dart`).

### HTML Design
—

### Decision
- The redesign keeps both pops (`TDialog.error(popRouteOnConfirm: true)`).
- **OPEN:** whether to change it to a single pop for the generic arrive/start/complete errors (B1) — Engineering + Product.

### Reason
It's navigation behaviour. For "already accepted" it's arguably right; for a mid-trip failure it may strand the driver (INFERRED).

### Impact
`TDialog`; step 7 verification.

## Decision DD-34: Migrate the theme route by route

### Context
Rolling the new token set across every screen.

### Existing Behavior
One app-level light theme; hundreds of hardcoded colours.

### HTML Design
—

### Decision
- Install the new light `ThemeData` in step 1. **No per-route `Theme` wrappers** — the app is already light, so a half-migrated app still looks coherent.
- Screens migrate one at a time under it.
- Remove legacy styles only once nothing uses them (step 13).

### Reason
The per-route wrapper only existed to hide a light/dark split mid-migration. With a light target there is no split to hide.

### Impact
`06` steps 1 and 13; one screen per change (RULES).

## Decision DD-35: The request stage shows the route to the pickup

**Supersedes DD-15, and DD-16 and DD-10 for the request stage only. Settled by the user on 2026-09-29.**

### Context
On a new request the map showed only the streets around the pickup, and the pickup pin sat under the sheet. The driver could not see where they were, how far the pickup was, or what the trip was worth, which is what they decide on. The user asked for a route from the driver's position to the pickup.

### Existing Behavior
- The camera centred on the pickup at zoom 19 and re-centred on every GPS tick. The map had no padding, so the centre was under the sheet.
- No driver marker at the request stage (`syncMarker`).
- The sheet showed the four-step stepper, the passenger with phone number and call button, and the two addresses. No distance or fare (DD-15).
- The countdown floated over the map under the stage header (DD-16).

### HTML Design
"New request · 0.4 km away", distance and est. fare, Accept, a Cancel text link.

### Decision
- **Route:** on arrival, one Directions request from the driver's position to the pickup. It draws the polyline and gives "4 min" and "1.2 km to pickup". The camera fits the driver, the pickup and the route once, inside the map's padding (status bar above, measured sheet height below), and does not follow GPS ticks at this stage.
- **Reuse on accept:** the pickup stage reuses that route when the driver is still within 50 m of where it was fetched. Only requests that are declined or expire cost an extra Directions request.
- **Trip figures:** when the request has a destination, a second Directions request (pickup to destination) gives the trip distance. The fare is `estimateFare` over that distance, prefixed "≈" (DD-14), and shown only once the vehicle's per-km price and minimum fare are known.
- **Sheet:** one line with the stage name and the passenger (small avatar, full name); the ETA and distance to the pickup; the trip figures; then the two addresses split into place and area. No stepper, no phone number and no call button until the ride is accepted.
- **Tighter layout:** no grabber on the request stage, because a 30-second decision has nothing to collapse for. The sheet has 16 px above the content and 8 px under Decline. The other stages keep the grabber and their padding.
- **Addresses:** `splitAddress` drops plus codes, the postcode, the country and repeated parts, and joins a bare house number to its street. The place wraps to 2 lines and the area to 1, then ellipsis; beyond 74% of the screen the content scrolls and Accept stays pinned.
- **Countdown:** drawn inside Accept. The elapsed share darkens from the right and the seconds left sit in a pill. Same `SmoothCircularCountdown` timer; expiry still goes home, still silently.
- **Header:** not shown at the request stage. The sheet names the stage.
- **Decline:** the text action below Accept reads "Decline" (new key `DECLINE`). The confirm dialog and the emit-then-cancel order (DD-11) are unchanged.
- **Markers:** pickup and destination pins are drawn in code (brand circle, dark square), for the trip screen only. The driver keeps the vehicle image and now shows at the request stage too.
- **No figures without data:** no GPS fix or no route means no ETA, no polyline and the pickup pin alone.

### Reason
A driver decides on distance to the pickup and the trip's value. Showing real route figures replaces the guesswork DD-15 avoided by showing nothing.

### Impact
`booking/view.dart`, `ride_request_bottom_pop_widget.dart`, `trip_action_bar.dart`, `count_down_widget.dart` (`builder`), `route_service.dart` (`RouteSummary`), `mock_route_provider.dart`, `load_custom_marker.dart` (`loadTripPin`), `core/helper/address_parts.dart` (`splitAddress`). New keys: `DECLINE`, `TRIP`, `TO_PICKUP`, `UNIT_MIN`, `UNIT_SECONDS_SHORT`. Directions usage: up to two requests per request received, instead of zero.

## Decision DD-36: Going to pickup uses the compact sheet and follows the driver

**Supersedes DD-28 and DD-10 for the going-to-pickup stage. Settled by the user on 2026-09-30.**

### Context
After DD-35 the request stage and the going-to-pickup stage looked like two different apps: a floating header, a numbered stepper, no headline figure, a heavier unsplit address and a phone line came back on accept. The camera also stayed on the pickup at zoom 19 and re-centred on every GPS tick, so the driver's own car only appeared in the last ~100 m.

### Existing Behavior
- Floating `TripHeader` with the stage and booking code.
- `TripTimeline` with four numbered circles (~100 px).
- Pickup address in the focused title style, not split.
- `PassengerRow` with the phone number line and the call button.
- Camera centred on the pickup at zoom 19 on every tick; the full route drawn from where it was fetched.

### Decision
- **Sheet:** the same anatomy as the request. A stage line ("Go to passenger", `#code` on the right), a thin 4-segment `TripProgressBar`, and one headline: time and distance left. These three stay visible when the sheet is collapsed. Below them, the pickup address split into place and area, and a dense `PassengerRow` (32 px avatar, call button, no phone line). The grabber stays, inside the sheet's top padding.
- **No floating header and no map zoom buttons** on this stage.
- **Time and distance left** are worked out on the phone: the driver is projected onto the route (`routeProgress`), the distance left is the rest of the route, and the time left is the route's Directions duration scaled by the share of distance still to drive. Under a minute reads "< 1 min".
- **Route:** the part already driven is trimmed away on every tick. A new route is fetched only when the driver is more than 80 m off it, at most once every 30 s, or when the stage opens without the request's route (screen reopened mid-trip, or the driver moved more than 50 m before accepting).
- **Camera:** frames the driver, the pickup and the route left, never smaller than ~170 m across, refitted at most every 4 s. When the driver moves the map themselves, the auto-fit pauses for 10 s.

### Reason
The driver's job on this stage is to reach the pickup; the map should show where they are and what is left, and the sheet should read like the one they just accepted.

### Impact
`booking/view.dart`, `ride_request_bottom_pop_widget.dart`, `trip_timeline.dart` (`TripProgressBar`, `tripStepsDone`), `passenger_row.dart` (`dense`), new `core/utils/route_progress.dart`. New keys: `DISTANCE_LEFT`, `STEP_OF`, `UNIT_UNDER_MIN`. Directions usage on this stage: none when the request's route is reused; otherwise one on entry, plus one per 30 s while off route.

## Decision DD-37: At pickup uses the compact sheet, a waiting timer and a trip preview

**Supersedes DD-28 and DD-10 for the at-pickup stage. Settled by the user on 2026-09-30. No no-show rule exists, so the timer has no threshold.**

### Context
After DD-36 the at-pickup stage still had the floating header, the numbered stepper, the phone line and the unsplit destination in the title style. Its distance line read "8.85 ម គ.ម" — `formatDistanceWithUnits` took the unitless number for metres and " km" was appended after it. The camera sat on the driver at zoom 19, so the route to the destination was a stub off-screen, and nothing said how long the driver had waited.

### Existing Behavior
- Floating `TripHeader`, `TripTimeline`, `PassengerRow` with the phone line.
- Destination in the focused title style with the broken distance line, and "≈ Est. fare" as a `TKeyValueRow`.
- Camera centred on the driver at zoom 19 on every GPS tick.
- No arrival time anywhere: not in `BookingScreenArgs`, not in the booking models.

### Decision
- **Sheet:** the DD-36 anatomy. Stage line ("At pickup", `#code`), `TripProgressBar` at step 3, then the waiting time as the headline — these stay when collapsed. Below: the trip distance and "≈" fare as the request's two tiles (the figures this stage already computed, now formatted "8.9 km"), the destination split into place and area, and the dense passenger row. "Start ride" stays in the success colour (DD-12).
- **Waiting timer:** counts up from the moment "I've arrived" succeeds, as "2:10" or "1:02:10". It is saved on the phone per booking (`StorageKeys.arrivedAt`, one key for the one active trip) so it survives an app restart, and cleared when the ride starts or is cancelled. Reopened at this stage with nothing saved, the timer is not shown. It ticks on its own, so only its line rebuilds each second. No colour change: there is no no-show rule.
- **Camera:** frames the whole trip once — driver at the pickup, the route to the destination — as a preview, and does not follow GPS ticks (the car is parked). With no destination, it frames the pickup. No floating header and no map zoom buttons.
- **No destination:** no tiles and no destination row; the timer, the passenger and Start ride.

### Reason
At the pickup the driver waits and then drives the trip; the sheet should say how long they have waited and what the trip is, in the same form as the two stages before it.

### Impact
`booking/view.dart`, `ride_request_bottom_pop_widget.dart` (`_StageSummary`, `_WaitingClock`, `_TripFigures`), `core/storage/*` (`arrivedAt`). New key: `WAITING`. No new network requests.

## Decision DD-38: On trip uses the compact sheet, a route-aware headline, and hold-to-confirm Drop off

**Supersedes DD-28 and DD-10 for the on-trip stage, and settles DD-13. Settled by the user on 2026-09-30.**

### Context
The on-trip stage still had the floating header and the numbered stepper. Its meter mixed two meanings on a ride with a destination — the time was elapsed but the distance and fare were the whole planned trip, so the full fare showed two seconds in — and read "8 គ.ម:850 ម" and "00:00:02". The route was drawn once at the start and never trimmed, and the camera followed the car at zoom 19. Drop off was a single tap that cannot be undone.

### Existing Behavior
- `TripMeterStrip`: `formatDuration`, `convertKmToKmM` / `convertMaterToKm`, and the fare expression (`DD-14`).
- `_drawPolylines` driver→destination on entering the stage; camera centred on the driver at zoom 19 on every tick.
- Drop off: one tap → `getLocation(TripStage.completing)`.

### Decision
- **Sheet:** the DD-36 anatomy — "On trip", `#code`, `TripProgressBar` at step 4. Steps 1–3 are already the stage's green, so the current step is drawn in the lighter success green; with a destination it fills as the trip progresses (against the trip's full driving distance, so a detour's new route does not reset it).
- **Headline by ride type:** with a destination, the time and distance left — the phone projects the driver onto the route (`routeProgress`) and scales the route's Directions duration, as DD-36; tiles "Duration" (elapsed) and "Est. fare". Without one, the elapsed time and distance driven; tile "Fare so far". The headline, tiles and the `EST_NOTE` line are pinned, so they stay when the sheet is collapsed (C4). The destination is split into place and area.
- **Values unchanged, formats changed:** the same figures and fare expression (`DD-14`), shown as a clock ("12:40", "1:02:10") and as "3.2 km" (`_formatKm`).
- **Route:** `_drawPolylines` now takes the Directions summary — the same one request — so the trip knows its duration. The route drawn at pickup is reused when the driver starts within 50 m of where it was fetched. It is trimmed on every tick, refetched when the driver is more than 80 m off it (at most every 30 s); the fare figures computed once (`laodCalculateDistance`) are not recomputed.
- **Camera:** with a destination, frames the car and the route left, refitted at most every 4 s, paused for 10 s after the driver moves the map. Long trips start zoomed out and zoom in as the car gets closer — accepted. Without a destination, it follows the car on every tick at a neighbourhood zoom (~170 m across). While dropping off it stays still. No floating header and no map zoom buttons.
- **Drop off is hold-to-confirm:** the button reads "Hold to drop off" and fills over 1 s while pressed, then fires with a haptic tick. Letting go early or dragging off empties it; a tap does nothing. The fill takes real time under the reduced-motion setting. A screen reader's activate action confirms directly. Disabled while any trip action is in flight (DD-17).

### Reason
One sheet language across all four stages; the headline says what the driver needs now (how far to go, or what the meter reads); and the one irreversible action cannot fire by accident.

### Impact
`booking/view.dart`, `ride_request_bottom_pop_widget.dart` (`_FigureTiles`, `_EstimateNote`; `TripMeterStrip` no longer used by the sheet), `trip_action_bar.dart` (`holdToConfirm`), `trip_timeline.dart` (`currentFraction`), new `core/utils/clock_format.dart`. New keys: `HOLD_TO_DROP_OFF`, `DISTANCE_DRIVEN`, `FARE_SO_FAR`. Directions usage: none extra when the pickup route is reused; otherwise one on entry, plus one per 30 s while off route.

## Decision DD-39: Payment leads with the amount, words follow the method, one request at a time

**Keeps DD-18. Settled by the user on 2026-09-30. "Payment done" stays a single tap.**

### Context
After the trip sheet (DD-35–DD-38) the payment screen was the one screen left in the old style. The amount the driver acts on sat below the receipt; duration and date were English and long in Khmer ("8 m 24 s", "Wed/30/Sep/2026 05:36 PM"); addresses were unsplit; the hint told the driver to collect cash whatever the method. And the button's spinner never showed: `loading` was read in a `StatelessWidget` without `Obx`, and `acceptPayment()` had no guard, so a second tap sent a second request.

### Existing Behavior
- Title bar, `ReceiptCard` (passenger + method badge, distance / duration / date rows, addresses), `TotalBox`, hint, success button.
- `convertTimeString`, `formatDateTime` (`EEE/dd/MMM/yyyy hh:mm a`, no locale), `formatDistanceWithUnits`.

### Decision
- **Layout:** `PaymentHeader` — "✓ Trip complete", `#code`, the four-step bar all done — where the trip sheet left off. `PaymentHero` — the method's wording, the server amount as the one hero figure, the method badge, and distance / duration / time as three tiles, falling back to labelled rows when a tile would be too narrow for its figure (small phones, large text). `PaymentRoute` — both addresses split into place and area, then the passenger, no call button. Hint and button pinned.
- **Formats:** distance "3.1 km" (`formatDistanceText`; a bare number is kilometres), duration as a clock "8:24" (`parseDurationText` → `formatClock`), time "17:36" today or "30/09 17:36" otherwise — digits only, so it reads the same in both languages. Unparseable server text is shown as given.
- **Method-aware wording** (`PaymentKind`, matched case-insensitively on "cash", "wallet", "card" — the server's exact strings are unconfirmed; mock mode sends Cash / Wallet / Card):
  - cash: "Collect in cash", hint "Take ៛9,100 in cash, then confirm.", button "Cash received";
  - wallet / card: "Paid by wallet" / "Paid by card", "Nothing to collect", hint "Paid in the app. Confirm to finish the trip.", button "Finish trip";
  - anything else or no method: the previous wording ("Total to collect", the old hint, "Payment done"), with the server's method text on the badge.
- **One request at a time:** the button is reactive (`Obx`) — it shows the spinner and is disabled while the request is in flight — and `acceptPayment()` returns early while one is. The REST call, the socket emit after it, the profile refresh and the immediate navigation are unchanged.
- **No hold-to-confirm** on this screen: it is the screen's only action, and the driver has just held Drop off.

### Reason
The amount and how it is paid are what the driver acts on; the screen should say exactly what to do for that method, look like the trip it ends, and never send the payment twice.

### Impact
`calculate_fee/view.dart`, `calculate_fee/logic.dart` (guard), `calculate_fee/widgets/receipt_card.dart` (`ReceiptCard` and `TotalBox` replaced by `PaymentHeader`, `PaymentHero`, `PaymentRoute`), new `core/utils/distance_format.dart`, `core/utils/clock_format.dart` (`parseDurationText`). New keys: `TRIP_COMPLETE`, `COLLECT_IN_CASH`, `PAID_BY_WALLET`, `PAID_BY_CARD`, `PAY_CASH`, `PAY_WALLET`, `PAY_CARD`, `NOTHING_TO_COLLECT`, `COLLECT_CASH_HINT`, `PAID_IN_APP_HINT`, `CASH_RECEIVED`, `FINISH_TRIP`.

## Decision DD-40: History is grouped by day, with compact cards and equal tabs

**Card and tabs reworked by DD-41 (2026-10-01).** The day grouping, the formats and the cancelled-card rule stand.

**Keeps DD-19 and DD-20. Settled by the user on 2026-10-01. Day totals were proposed and not taken.**

### Context
The user found the history list hard to use "because of the tabs and the cards". The selected tab pill hugged its label, so the two tabs did not read as equal halves. Each card was about 330 px — two per screen — and led with the invoice number in bold; "Completed" was repeated on every card of the Completed tab; the date ("Thu/01/Oct/2026 07:14 AM") wrapped to two lines; full addresses took two lines each; and nothing showed the card was tappable. The list was flat, with no day breaks. Cancelled cards printed ៛0, "Unknown" and 0 km.

### Existing Behavior
- `TTabs` with label-hugging pills; a flat `ListView` of `HistoryCardWidget`.
- Card: avatar, `#invoice`, "passenger · `formatDateTime`", amount, status and method badges, a route box, a distance/duration line (`formatDistanceWithUnits`, `convertTimeString`).

### Decision
- **Tabs:** each `TTabs` pill fills its half (`_SelectableSegment.fill`). Same two filters, same `switchTab`.
- **Grouped by day:** a header before each day's run of trips — "Today", "Yesterday", "Mon 28 Sep" (the year is added for another year), with day and month names in the app's language. Presentation only (`historyRows`): the list keeps the server's order, and paging, pull-to-refresh and the footer are unchanged. A trip's day is its `start_time`, or `created_at` when it never started.
- **Compact completed card** (four lines, about a third of the height): "07:14 · passenger" and the amount; the pickup and destination by place name (`splitAddress`), one line each, with the full address still spoken; then "3.5 km · 14:00 · Cash · #7712" (`formatDistanceText`, `formatClock`, `PaymentKind`) and a chevron. No avatar and no status badge — the tab says "Completed".
- **Cancelled card:** "07:14 · passenger", the status badge, and the invoice number. No amount, route or figures. Still not tappable (DD-19).
- **Not done:** day totals (a phone-side sum over a paged list; proposed, not taken), an "All" tab, date filters and search (all need API changes).

### Reason
A driver scanning history looks for when, how much and where. The day belongs in a header, not on every card, and a list that shows four or five trips at once is quicker to scan than one that shows two.

### Impact
`history/view.dart`, `history/widgets/history_card_widget.dart`, new `history/widgets/history_days.dart`, `widgets/ds/t_selection.dart` (`fill`). New keys: `TODAY`, `YESTERDAY`. The detail route and its `MapHistoryDetailArgs` are unchanged.

## Decision DD-41: History tabs are swipeable pages; the card gets its weight back

**Reworks DD-40's card and tabs. Keeps DD-19, DD-20 and DD-40's day grouping. Settled by the user on 2026-10-01 (card A, swipe option 1).**

### Context
The user tested DD-40 and asked for two things: to swipe sideways between the tabs "like a Cupertino tab bar", and a new card, because the compact one "is thin and the weight does not look good" — most of it was small grey caption text, with only the amount in bold.

### Existing Behavior (DD-40)
- One `HistoryLogic` list, reloaded from page 1 on every tab switch; tabs changed by tap only.
- A four-line card in caption text.

### Decision
- **Pages:** the two tabs are a `PageView`. Swiping moves between them; tapping a tab slides to its page (it jumps under the reduced-motion setting). `TTabs` now has one thumb that slides between equal segments and follows the page position mid-swipe (`position`).
- **One list per tab:** `HistoryLogic.lists` holds a `HistoryListLogic` per status, each with its own items, paging and scroll position, kept alive while the other page shows. The completed list loads with the screen; the cancelled one the first time its tab shows. **Switching tabs no longer refetches** — pull-to-refresh reloads that tab. Lists are always scrollable, so pull-to-refresh works on a short list too.
- **Card A, three tiers:** the time in bold with the payment-method badge and the amount in the subtitle style; the pickup and destination by place name in semi-bold, joined by a line between their markers; then, under a divider, a 24 px avatar with "passenger · #invoice", and the distance and duration with a chevron. The invoice stays on the card because the detail screen does not show it (DD-20).
- **Adaptive footer:** the distance and duration share the footer's line while the name keeps at least 96 px; otherwise they move to a line of their own. On a very narrow header the method badge scales down rather than overflowing.
- **Cancelled card:** time, the status badge, and the footer without figures. No amount, route or method (DD-40's rule).

### Reason
A swipe is the expected gesture for two sibling lists, and it only feels right if both lists exist while the finger moves — hence a list per tab. The card needed a clear hierarchy: when and how much, where, then who.

### Impact
`history/view.dart`, `history/logic.dart` (`HistoryListLogic`; `switchTab` no longer reloads), `history/state.dart`, `history/widgets/history_card_widget.dart`, `widgets/ds/t_selection.dart` (`TTabs` sliding thumb, `position`). No new keys.

## Decision DD-42: Trip detail shows the whole trip, and how to reach the passenger about a lost item

**Supersedes DD-20. Settled by the user on 2026-10-01: call and support together, a 24-hour call window, the number reachable by button only.**

### Context
The history detail showed a map and three figures. The user asked whether it should show the passenger, and then raised the case that decides it: a passenger leaves something in the vehicle — how does the driver reach them? The history payload already carries the passenger's phone number.

### Existing Behavior (DD-20)
- `MapHistoryDetailArgs`: vehicle type, three pre-formatted figures, four coordinates.
- A map opened at zoom 17 on the start, with the driver's vehicle image at the pickup and the old passenger pin at the destination, so the route ran off-screen; zoom buttons and the map toolbar on.
- `TripDetailCard`: a "Completed" badge, distance, duration, total.

### Decision
- **The whole trip:** the args gain the invoice, the passenger's name, image and phone, both addresses, the payment method, and the trip's start and end times. All optional, so a caller with only the figures still works.
- **Layout, from the payment screen's pieces:** `PaymentHero` with the label "Total price" (not the payment screen's "Collect in cash" wording) — amount, method badge, and distance / duration / time; then `PaymentRoute` — both addresses split into place and area, and the passenger with the invoice number under the name.
- **Map:** the trip screen's pickup and destination pins (DD-35) instead of the vehicle and the person; framed once on the whole route, never tighter than ~170 m; no zoom buttons or toolbar. Still one Directions request per open.
- **Lost item card:** "Found something the passenger left?"
  - For **24 hours after the trip ended** (`canCallPassenger`; the end is `end_time`, else the payment's `created_at`, else the start): a "Call passenger" button and a "Contact support" text action.
  - After that, or with no number or no known end time: "Contact support" only, with the invoice number to quote.
  - **Button only:** the passenger's number is never printed — though the phone's dialer will show it once the driver taps. `callPassenger()` re-checks the window, so a screen left open past it cannot still call.
  - "Contact support" opens a sheet with the company's two lines (the Contact us screen's numbers).
- **Not done:** an in-app lost-item report with a notification to the passenger — the right long-term answer, but it needs a backend endpoint and a passenger-app screen. And the payload still carries the passenger's email and date of birth, which this app has no use for; trimming that is a server change.

### Reason
A driver who finds a phone on the back seat needs to reach its owner within the hour, and the trip detail is where they will look. A time-limited call keeps that case fast without turning the driver app into a permanent directory of passengers' numbers.

### Impact
`routes/route_arguments.dart` (`MapHistoryDetailArgs`), `history_detail/{logic,view,binding}.dart`, new `history_detail/contact_window.dart`, `history/widgets/history_card_widget.dart` (`_openDetail`), `history/widgets/history_days.dart` (`historyEndedAt`), `calculate_fee/widgets/receipt_card.dart` (`PaymentHero.label`, `PaymentRoute.passengerCaption`). `TripDetailCard` is replaced by `TripDetailBody` and `LostItemCard`. New keys: `LOST_ITEM_TITLE`, `LOST_ITEM_CALL_HINT`, `LOST_ITEM_SUPPORT_HINT`, `LOST_ITEM_SUPPORT_ONLY_HINT`, `CALL_PASSENGER`.

## Decision DD-43: The wallet is a prepaid commission wallet

**Supersedes DD-21's "meaning unclear" for `commission_fare` and `debted`. The model was proposed and agreed with the user (product owner) on 2026-10-01. It is a product definition: the backend's behaviour still has to be confirmed against it — see "Needs from the backend".**

### Context
The wallet showed two money cards — "Wallet 85,400 ៛" and "Commission fare 10 ៛" — and nobody could say what the second meant (`docs/reverse-engineering/06 §5`, DD-21). The payload's `debted` was not shown at all. Transaction names and statuses were the backend's English text, amounts had no direction, and the money format ("85,400 ៛") differed from every other screen ("៛9,100").

### The model
- **`commission_fare` is the platform's rate, a percentage** of each completed trip's fare. `10` is 10%. It is not a sum of money.
- **Cash trip:** the driver keeps the cash; the wallet is charged the commission ("Commission −៛1,300").
- **Wallet or card trip:** the platform holds the fare; the wallet gets the fare as "Trip earning +" and the commission as "Commission −", two rows.
- **Top-up:** money the driver adds to cover commission.
- **`debted` is unpaid commission the driver owes.** The balance does not go below zero; a shortfall is debt. A top-up or a wallet-trip earning pays debt first. Past a limit the platform sets, the driver stops receiving requests until they top up.
- *(DD-46 paid rewards straight into the balance; DD-48 went back to a separate reward balance with a transfer, and settled that there is no cash withdrawal.)* **Referral rewards** (the flowchart) stay a separate balance with "Transfer to wallet" and withdraw — reward money is the driver's to cash out, top-up money is prepaid commission. Not built: no backend (DD-22, Q-4).

### Decision (this app, now)
- **One balance card:** "Balance", the amount, and under it "Platform commission: 10% of each trip" when the rate is reported. The "Commission fare" money card is gone.
- **Debt warning:** shown only when `debted` is above zero — "You owe ៛5,000", "Unpaid commission from cash trips. Top up to clear it." Warning amber, not red. No "Top up" button: there is no endpoint. The copy does not say requests will stop, because that rule is not yet confirmed server-side.
- **Transactions:** grouped by day (as DD-40); each row has a translated name for the kinds the app knows (`WalletTxKind`, matched loosely on `type_name`: top-up, trip earning, commission, withdrawal, referral reward) and the backend's own text otherwise; the time; a status only when it is not the routine one; and the amount with a sign — "+" in success green for money in, "−" in neutral for money out. A negative amount is always out; otherwise the kind decides, so a commission sent as a positive number still reads as out. An unknown kind with a positive amount gets no sign. The filter chips use the translated names; the filter itself still matches `type_name`.
- **Money format:** symbol first ("៛85,400", "$125.50"), as everywhere else. The USD/riel decimal rules are unchanged.

### Needs from the backend
- Confirm `commission_fare` is a percentage and `debted` is unpaid commission, with the balance floor and the pay-debt-first rule.
- The debt limit, and whether requests stop past it.
- Transaction `type` codes (CLIENT_BRIEF B4), so names and directions come from codes, not from matching English text.
- Top-up and withdraw endpoints (Q-4).

### Impact
`wallet/view.dart`, `wallet/wallet_presentation.dart`, `wallet/widgets/wallet_widgets.dart` (`WalletDebtCard`; `WalletBalanceTone` removed). New keys: `WALLET_BALANCE`, `WALLET_COMMISSION_NOTE`, `WALLET_DEBT_TITLE`, `WALLET_DEBT_MESSAGE`, `WALLET_TX_TOP_UP`, `WALLET_TX_TRIP_EARNING`, `WALLET_TX_COMMISSION`, `WALLET_TX_WITHDRAW`, `WALLET_TX_REFERRAL_REWARD`. The keys `WALLET` and `COMMISSION_FARE` are no longer used by this screen.

## Decision DD-44: The contact page is grouped by what the driver wants to do

**Settled by the user on 2026-10-01: this layout, the PU Taxi name, local number format, the new logo.**

### Context
The contact page (drawer tab "Contact us") was a large logo badge, a centred blurb and four identical bold rows — two phone numbers written "Smart: +855 70 427 213", the email, and an address that looked tappable and did nothing. The logo and copyright said "TAARRAA" while the rest of the app says PU Taxi, and the copyright year was hardcoded to 2025.

### Decision
- **Header:** a compact card with the PU Taxi mark (`assets/launcher/launcher_driver_1024.png`, decoded at display size), "PU Taxi support" and the existing blurb.
- **"Call us":** one card, a row per carrier — the carrier's name as a small label, the number in bold, and the green call button the trip screen uses.
- **"Other ways":** the email, and the office address, which now opens in the phone's maps app (`ContactUsLogic.openMap`).
- **Local number format:** "+855 70 427 213" is shown as "070 427 213" (`formatLocalPhone`). Display only; dialling still uses the full international number. The trip detail's support sheet (DD-42) shows the same format.
- **Footer:** "Version 1.1.9" — the version the app's update check is pinned to (`HomeLogic`), since the app has no package-info dependency — and the copyright as "© {year} PU Taxi", with the current year filled in.
- **Not done:** Telegram or Facebook rows and support hours — none were supplied.

### Impact
`contact_us/view.dart` (`ContactHeader`, `ContactSectionLabel`, `ContactGroup`, `PhoneRow`, `ContactInfoRow`; `ContactRow` kept for the support sheet), `contact_us/logic.dart` (`openMap`, `formatLocalPhone`), `history_detail/view.dart`. `COPYRIGHT` now takes the year. New keys: `SUPPORT_TITLE`, `CALL_US`, `OTHER_WAYS`, `CONTACT_EMAIL`, `CONTACT_OFFICE`, `APP_VERSION`. `assets/image/png/company_logo.png` is no longer used by the app.

## Decision DD-45: One invite QR for everyone, opened from the home map

**Settled by the user (product owner) on 2026-10-01, screen by screen. Supersedes DD-22. Built on mock data only: the backend has no referral endpoints.**

### Context
The reward flowchart and `ux_ui_design/referral-ux-copy-deck.md` describe a driver-only referral programme. The user set different rules, and asked to see the driver side working before anything else is built.

### The rules
- **One QR and one invite code per person**, the same for inviting drivers and passengers. The QR holds a link; the app the new person signs up in decides what they joined as.
- **Both drivers and passengers can invite and earn.** (The passenger app is not built yet.)
- **The invited person is a driver:** the inviter earns **1% of each wallet top-up** that driver makes.
- **The invited person is a passenger:** the inviter earns **10% of the platform's commission** on each trip they take. It comes out of the commission, never the fare or the driver's share, and it has no end date.
- **A code is given at sign-up only.** There is no way to add one later.

### Decision (driver app)
- **Entry point:** a round QR button floating over the home map, above the status card. The map's bottom padding grows by the button's height, so Google's logo and the zoom buttons sit above its row and nothing is covered.
- **"My QR" sheet:** a line of pitch, the QR (always black on white, high error correction, the PU Taxi mark in the middle), the code with a copy button, "Share invite link" (the system share sheet, with the code and the link), the two reward rules, and one line on what the invites have earned (DD-46).
- **Sign-up:** an optional "Invite code" field at the end of the form, on its own card, with a scan button inside it. The code is checked when typing pauses and shows "Invited by {name}" or "Code not recognised". **A wrong code stops Submit** — the code cannot be added later, so dropping it silently would lose the invite for good; clearing the field lets the driver continue. A code is sent with the registration as `invite_code` only when present.
- **Scanner:** a full-screen camera with a frame and one line of instruction. Only an invite counts — a link whose last path segment (or `code` parameter) is 4–12 letters and digits, or such a code on its own. Anything else shows "This is not a PU Taxi invite QR" and the camera keeps looking. With the camera refused: a message and "Open settings".
- **Hidden without a backend:** `inviteFeatureEnabled` is true only while the mock backend is serving the app. Against the real API the button, the wallet card and the sign-up field do not appear, so no driver reaches a screen that can only fail.

### Open
- **What a driver earns for inviting a passenger.** The app shows one rule per kind of invited person, so it shows 10% here too. The copy deck said 1% of commission. Not confirmed.
- **The invite code's format** (the mock uses six random characters) and **the link's domain** (the mock uses `putaxi.example`).
- **Whether the invited person gets anything** for joining (Q-21).
- **Self-invites** (same phone or device) should be refused by the server.
- **The endpoints.** The app proposes `GET /taxi-driver/referral` (code, link, the two rates, invitees, rewards) and `GET /taxi-driver/referral/check-code?code=` (asked before the driver has a token). Neither exists.

### Impact
New: `screens/invite/` (`InviteLogic`, `ReferralDatasource`, `ReferralModel`, `invite_presentation.dart`, `my_qr_sheet.dart`, `rewards_view.dart`, `people_view.dart`, `scan_view.dart`, widgets), six icons in `assets/icon/ds/`, routes `inviteRewards` and `inviteScan`. Changed: `home/view.dart`, `register/*`, `auth_datasource.dart` (`invite_code`), `TTextField` (a `suffix`). Mock: `MockData.referral`, `MockData.inviters`, OTP `1111` opens the sign-up form. **New packages:** `qr_flutter` (draw the QR), `mobile_scanner` (read one), `share_plus` (share the link).

## Decision DD-46: Rewards are paid into the wallet, and live under it

**Partly superseded by DD-48 (2026-10-02): rewards are a balance of their own again, moved to the wallet by the driver. The single "Invite rewards" screen with two tabs, opened from the wallet and the QR sheet, stands.**

**Settled by the user on 2026-10-01. Supersedes DD-43's "referral rewards stay a separate balance".**

### Context
The first build put "Your rewards" and "People you invited" behind the QR sheet. The user asked to move them to the wallet: rewards are money, and the wallet is where a driver looks for money.

### Decision
- **A reward is paid into the wallet balance.** There is no separate reward balance and nothing to transfer. Each reward is also a "Referral reward" row in the wallet's own transaction list.
- **One screen, "Invite rewards", with two tabs** (swipeable, as DD-41): **Rewards** — where the rewards came from, the two rules, and every reward by day with who it came from; **People** — everyone who joined with the code, filtered by All / Drivers / Passengers, each with what they have earned the driver.
- **It opens from the wallet** and from one line at the foot of the QR sheet ("៛5,160 earned · 5 invited") — the figure stays next to the QR because it is the reason to share it.
- A trip reward does not show the commission it was taken from: what the platform earned on someone else's trip is not the driver's to see. A top-up reward does show the top-up.

### Consequence to settle
DD-43 kept reward money apart because it is the driver's to cash out, while a top-up is prepaid commission. In one balance the two are mixed, so a future withdraw has to say what may be withdrawn.

## Decision DD-47: The wallet shows what the invites have earned

**Superseded by DD-48 (2026-10-02) for the wallet card: it now shows the reward balance, with a transfer button. The split on the rewards screen stands.**

**Settled by the user on 2026-10-01: option A, and keep the split on the rewards screen.**

### Decision
- **On the wallet, under the balance:** a card "Invite rewards earned" with the amount in green and "Already in your balance · 5 invited". It opens the rewards screen. It appears once the figure has loaded, and a failure to load it never takes the wallet down.
- **The wording is deliberate.** Two money figures on one screen invite adding them up; the earned amount is inside the balance, and the caption says so.
- **On the rewards screen:** the large "Total earned" card is gone. A small card keeps the split — from drivers, from passengers — and the line "Rewards are paid into your wallet balance."

### Impact
`InviteEarnedCard`, `RewardSplitCard` (`RewardSummaryCard` removed), `wallet/view.dart`. Keys: `INVITE_EARNED_LABEL`, `INVITE_EARNED_CAPTION`.

## Decision DD-48: Rewards are their own balance, moved to the wallet by the driver

**Amended by DD-49 (2026-10-02): the driver types the amount; it is no longer always the whole reward balance, and the app does send the amount. The rest of this entry stands.**

**Settled by the user on 2026-10-02: transfer all, no cash withdrawal, no minimum. Supersedes DD-46's "paid into the wallet balance" and DD-47's wallet card.**

### Context
DD-46 paid each reward straight into the wallet balance. The user asked for the two to be kept apart: the balance is working money — top-ups in, commission out — and a reward is prize money from the people the driver invited. Only money in the balance can be used, so the driver moves rewards into it.

### Decision
- **Two pots.** The wallet balance, and a reward balance. A reward goes into the reward balance. It pays no commission until it is transferred.
- **Transfer is all of it, one way.** One button, "Transfer to balance", and a confirm sheet. No amount to type: rewards have no other use. **No cash withdrawal, no minimum.** A transfer cannot be moved back, and the sheet says so.
- **The confirm sheet** says the amount, the balance afterwards (when the wallet has loaded), and — if the driver owes commission — how much of the transfer pays that first (DD-43's pay-debt-first rule): "៛5,000 pays what you owe. ៛160 goes to your balance."
- **On the wallet:** under the balance, a card "Invite rewards" with the reward balance in green, "Not in your balance yet · 5 invited", and the button. The card opens the rewards screen. With nothing to transfer the button is gone and the caption says so.
- **Wallet history:** one "Reward transfer" row per transfer. The single rewards are no longer wallet rows — they are in the reward history — so nothing is counted twice.
- **Rewards tab:** the reward balance with the same button, then "Total earned" and "Transferred to balance", the split by drivers and passengers (DD-47), the rules, and a history of rewards (+, green) and transfers (−, neutral).
- **Debt warning:** when the driver owes commission and has rewards, the warning adds "You have ៛5,160 in invite rewards. Transfer it to pay this." and the button.
- **After a transfer** the rewards are fetched again and the wallet is refreshed in place (no skeleton), so both show the server's figures. A toast says what moved.

### Safety
- The app sends **no amount**: the server moves the reward balance as it stands, so the app cannot ask for more than exists. The toast shows what the server says it moved.
- Each confirmed transfer carries a **request id**; the server must treat a repeat of the same id as the same transfer. The button is also disabled while one is out.

### Needs from the backend
- `reward_balance` and `transfers` on `GET /taxi-driver/referral`.
- `POST /taxi-driver/referral/transfer` with `request_id`, returning `transferred`. Idempotent on `request_id`; refuses when there is nothing to move; pays debt first.
- A wallet transaction type for the transfer (the app matches "transfer" in `type_name` until type codes exist).

### Not visible in mock mode
The mock wallet never owes (`debted: 0`), so the debt line on the sheet and the hint on the warning are covered by tests only.

### Impact
`RewardBalanceCard` (replaces `InviteEarnedCard`), `TransferConfirmBody`, `transfer_sheet.dart` (`confirmRewardTransfer`), `InviteLogic.transferRewards`, `ReferralModel.rewardBalance` / `transfers`, `invite_presentation.dart` (`rewardBalance`, `transferPreview`, `rewardEntries`), `WalletTxKind.rewardTransfer`, `WalletDebtCard` (hint and action), `WalletLogic.fetch(silent:)`. Mock: the transfer endpoint, persisted transfers; the wallet no longer derives reward rows. Keys: `INVITE_TRANSFER*`, `INVITE_NOT_IN_BALANCE`, `INVITE_NOTHING_TO_TRANSFER`, `INVITE_REWARD_BALANCE`, `INVITE_TOTAL_EARNED`, `INVITE_TRANSFERRED`, `WALLET_TX_REWARD_TRANSFER`, `WALLET_DEBT_REWARD_HINT`.

## Decision DD-49: The driver types the amount to transfer

**Settled by the user on 2026-10-02, after seeing both sheets side by side: option B. Amends DD-48's "transfer is all of it".**

### Context
DD-48 moved the whole reward balance in one step. The user wants the transfer to be the driver's own act down to the amount: nothing about it decided for them.

### Decision
- **The sheet "Transfer to balance":** the reward balance, an "Amount" field, the result, and the buttons.
- **The field starts empty**, with the keyboard up. "All" fills in the whole reward balance. Riel takes digits only; other currencies take two decimals.
- **While the amount is good**, the sheet shows "Balance after", "Rewards left", and the debt line when the driver owes (DD-48), and the button names the amount: "Transfer ៛2,000".
- **The button is off** until the amount is above zero and no more than the reward balance. More than the balance shows "You have ៛5,160 to transfer." under the field. Nothing typed shows no error — the button just waits.
- **No minimum, no maximum** other than the reward balance. What is not transferred stays in rewards.
- Everything else is DD-48: one way, debt paid first, a toast with what moved, the wallet refreshed in place.

### Safety
- The app now **sends the amount**. The check on screen is a convenience; the server is the judge — it must refuse an amount that is not above zero, is finer than the currency goes, or is more than the reward balance it holds.
- The request id, the disabled button while a transfer is out, and the refetch afterwards are unchanged.

### Needs from the backend
`POST /taxi-driver/referral/transfer` takes `amount` and `request_id`, returns `transferred` and the new `reward_balance`.

### Not checked
The sheet was run on an emulator with a hardware keyboard, so the on-screen keyboard did not open; the sheet pads itself by the keyboard's height, but that needs a look on a phone.

### Impact
`TransferAmountBody` (replaces `TransferConfirmBody`), `transfer_sheet.dart`, `InviteLogic.transferRewards(amount)`, `invite_presentation.dart` (`parseTransferAmount`, `transferAmountText`, `checkTransferAmount`). Mock: the endpoint validates the amount. Keys: `INVITE_TRANSFER_AVAILABLE`, `INVITE_TRANSFER_AMOUNT`, `INVITE_TRANSFER_REWARDS_LEFT`, `INVITE_TRANSFER_TOO_MUCH`, `INVITE_TRANSFER_BUTTON`; `INVITE_TRANSFER_CONFIRM_TITLE` removed.

## Decision DD-50: A lighter page background

**Settled by the user on 2026-10-03: option A.**

### Context
The page background, `bg.page` `#F2F2F5`, read too deep behind the white cards on every list screen.

### Decision
`bg.page` is `#F7F7F9`: the same cool grey, lighter. One token, so every screen with a page behind cards changes — wallet, history, trip detail, rewards, contact, sign-up. Map screens are unchanged: the map covers the page there.

### Effect
- Every text colour gains contrast on the page: secondary text 5.32 → 5.56, danger 4.46 → 4.65, brand text 4.57 → 4.77, warning 4.84 → 5.06, success 4.89 → 5.11.
- White cards lift off the page less (1.12 → 1.07); their 1 px border separates them, as it already did.
- Tab tracks and chip rests (`bg.raised` `#EBEBF0`) stand out a little more (1.06 → 1.11).

### Impact
`TaarraaColors.light.bgPage` in `core/theme/tokens.dart`; `02-design-system.md`, `01-design-direction.md`.

