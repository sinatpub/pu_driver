# pu_driver UI Redesign — Implementation Progress

Single source of truth for current implementation progress. **What** must be implemented is defined in `docs/roadmap.md`; this file tracks **what has actually been done**. 21 tracked items = the G0 gate + the roadmap's 20 implementation tasks.

Follow the maintenance rule: read this file before starting any work, update task status when work begins, and update Overall Progress / Current Task / Next Task on every change.

---

## Current Status

Overall Progress: 8 / 21 tasks DONE (S1–S5, P1, P3, Q1); P2 implemented but BLOCKED on native Khmer review; 8 code-complete in `[Q]` (F1–C6) awaiting re-review
Overall Status: PAUSED after Phase 5 (2026-09-14)

Current Phase:
Phase 5 — QA

Current Task:
none — paused after Q1

Next Implementation Task:
Q2 — Functional regression (device + live backend); Q3 — Performance review

Verification standard (adopted 2026-09-14, per `docs/implementation_rule.md` and the user's execution brief):
a task is `[x]` when (1) `dart analyze` is clean for every file it touched, (2) the **full** test suite passes, (3) a debug APK builds, and (4) its UI has been reviewed against `03`/`04` and the prototype — rendered at 390 px and 320 px, EN and KM, with the app's real fonts. Checks that genuinely need a device, a live backend or the G0 oracle (FCM taps, dialer/mail launch, paging against the API, socket emits) are recorded per task and carried by **Q2 — Functional regression**; pixel checks on a device by **Q1**.

How verification runs on this Mac (the old "no test runner" blocker is resolved):
- The project's pinned 3.38.9 is not installed and `~/FileInstaller/flutter` (3.38.1) has no `flutter_tester`; fvm's **3.44.1** has it.
- To avoid touching `pubspec.lock`/`.dart_tool` in the working tree, tests and builds run in a scratchpad mirror: `rsync` the repo (minus `build`, `.dart_tool`, `.git`), `~/fvm/versions/3.44.1/bin/flutter pub get --offline`, then `flutter test --no-pub` and `flutter build apk --debug --no-pub -t lib/main.dart`.
- The IntelliJ run configs still pass `--flavor dev`, but `android/app/build.gradle.kts` defines no flavors — build without `--flavor`.

Blockers:
- **G0 baseline not recorded** (`[!]`): no device video and no `tlog` socket-emit oracle. Recording it needs the pre-redesign build, a live backend and a real login (OTP) — a person, not this environment. It is the regression reference for C3–C6 and Q2.
- **P2 needs a native Khmer reviewer** (`[!]`): 39 developer-drafted KM strings and the 5 Terms & Conditions (KM file holds the English legal text until a legal translation exists). Review sheet: `docs/l10n-km-review.md`.
- **Open decisions:** DD-13 (Drop-off confirmation) affects C4; DD-33 (trip error dialog semantics) affects C5; DD-05 (Logout in drawer) — C1 shipped with Logout hidden (baseline).

---

## Progress Summary

| Phase | Done | Total | Status |
|---|---:|---:|---|
| Gate — Baseline and decisions | 0 | 1 | BLOCKED |
| Phase 1 — Design Foundation (F1–F3) | 0 | 3 | QA (code complete) |
| Phase 2 — Core Driver Experience (C1–C6) | 0 | 6 | QA (code complete) |
| Phase 3 — Supporting Screens (S1–S5) | 5 | 5 | DONE |
| Phase 4 — Polish (P1–P3) | 2 | 3 | P2 BLOCKED (review) |
| Phase 5 — QA (Q1–Q3) | 1 | 3 | Q1 DONE; Q2/Q3 TODO |
| **Total** | **7** | **21** | PAUSED |

"Done" means implementation **and** verification passed (see Verification standard above; device-visual and behaviour-vs-baseline checks are carried by Q1/Q2). S1–S5, P1 and P3 are DONE to the verification standard above. F1–C6 are `[Q]`: their tests now pass, but they have not had the rendered UI review.

---

## Task Status

Checkbox legend (per `docs/implementation_rule.md`): `- [ ]` TODO · `- [>]` IN PROGRESS · `- [x]` DONE · `- [!]` BLOCKED / NEEDS FIX · `- [Q]` code-complete before the test environment existed (2026-09-14), awaiting re-review · `- [~]` legacy in-progress marker (G0).

### Gate — Baseline and decisions

- [!] G0 — Decisions and baseline (DD-01, DD-02 settled by user 2026-09-12; DD-05, DD-13, DD-33 still OPEN; device video + `tlog` oracle **not recorded**)

### Phase 1 — Design Foundation

- [Q] F1 — Design tokens, light theme, typography
- [Q] F2 — Shared components
- [Q] F3 — Sheets, dialogs, toast, banner, state views

### Phase 2 — Core Driver Experience

- [Q] C1 — App shell
- [Q] C2 — Home tab
- [Q] C3 — Trip scaffold and request stage
- [Q] C4 — Trip stages: going to pickup, at pickup, in progress
- [Q] C5 — Trip dialogs and errors
- [Q] C6 — Payment

### Phase 3 — Supporting Screens

- [x] S1 — History and history detail
- [x] S2 — Wallet
- [x] S3 — Announcements, Terms, Contact
- [x] S4 — Auth: splash, login, OTP, register
- [x] S5 — Legacy token cleanup

### Phase 4 — Polish

- [x] P1 — Motion and micro-interactions
- [!] P2 — Copy and localization sweep (implemented; blocked on native Khmer review — `docs/l10n-km-review.md`)
- [x] P3 — Accessibility pass

### Phase 5 — QA

- [x] Q1 — Visual QA against the prototype
- [ ] Q2 — Functional regression
- [ ] Q3 — Performance review

---

## Current Task Details

### P3 — Accessibility pass

Status: DONE (2026-09-14)
Dependencies: S5 (DONE)

Method: `test/a11y/guidelines_test.dart` runs **14 redesigned surfaces** — login, OTP, register, drawer, the trip sheet at all four stages, home status card + location state, online pill, approval gate, payment receipt + total, history/wallet/news/contact rows, dialog + app bar — through Flutter's own `androidTapTargetGuideline` (≥ 48×48), `labeledTapTargetGuideline` (every tappable announces a label) and `textContrastGuideline` (rendered WCAG AA), and renders each at the 1.3 text-scale ceiling at 320 px **in EN and KM**, failing on any overflow. Plus a check that no text style is under 12 px. First run: 22 failures (after fixing the harness's own hosting), all real, all fixed:

Defects found and fixed:
- **Contrast — `text.secondary`** `#6B7588` → `#5C6474`. The old value was 4.64 only on white; on `bg.page` 4.15 and on `bg.raised` 3.91, where most secondary text sits (OTP description, "Didn't receive the code?", location messages, "Total to collect"). Now ≥ 4.60 on every neutral fill. `avatar.fallbackText` follows. `text.disabled` keeps `#6B7588` (inert controls are exempt).
- **Contrast — `warning`** `#8D6B07` → `#86650A`. The meter's estimate note was 4.46 on `stage.onTrip.tint` (4.43 on page). Now ≥ 4.56 everywhere amber text sits.
- **Tap target — text fields.** `TTextField`'s input was a 22 px strip inside the 56 px box: taps on the rest of the field did nothing. The input now fills the field (`minHeight: 56`, 16 px vertical content padding) — same visual height.
- **Tap target + label — trip sheet grabber.** The collapse/expand control was 24 px and silent. Now 48 px (bar unchanged; the sheet grows 16 px) with `expanded` state and the platform's "Collapse"/"Expand" hint as its label.
- **Clipping — drawer language row** overflowed 32–58 px at 1.3 on 320 px. The row wraps the segment under a flexible label.
- Design doc `02 §1.1` rows for `text.secondary`, `avatar.fallback` and `warning` updated, marked CHANGED with the measured ratios — **design review requested** for the two token values.

Files:
- `lib/core/theme/tokens.dart` (three values), `lib/presentation/widgets/ds/t_text_field.dart`, `lib/presentation/screens/booking/widgets/ride_request_bottom_pop_widget.dart` (grabber), `lib/presentation/screens/drawer/widgets/driver_drawer.dart`
- `docs/ux-redesign/02-design-system.md` (token table)
- Tests: `test/a11y/guidelines_test.dart` (new, 43 cases); `test/core/theme/tokens_contrast_test.dart` (+ secondary text on page/raised/sunken, warning on its real fills)

Verification:
- Analyze: PASS (no new findings)
- Tests: PASS — 521/521 (all 14 surfaces meet the three guidelines; none clip at 1.3 in EN or KM)
- Build: PASS — debug APK
- UI review: PASS — all 35 renders regenerated after the token and field changes; no layout change beyond the grabber's larger hit area
- Device-only, carried by Q2: a TalkBack/VoiceOver walk through the live trip flow (map, socket events and route changes can't be exercised in widget tests); the roadmap's "trip flow completable with a screen reader" is covered here at component level — every tappable in every trip stage is ≥ 48 px and labelled

---

### P2 — Copy and localization sweep

Status: BLOCKED (implementation complete 2026-09-14; verification needs a native Khmer reviewer)
Dependencies: the screen tasks that introduce each key (all done or `[Q]`)

What is blocking:
- The roadmap's verification is "a native Khmer reviewer signs off the drafts". Nobody in this environment can. **39** KM strings are developer drafts and the **5** Terms & Conditions have no Khmer at all (below).
- Missing information: a reviewed Khmer for the drafts; a legal translation of the terms.
- Decision required: none technical — who reviews, and whether the Terms ship in English meanwhile.
- Handoff: `docs/l10n-km-review.md` lists every Khmer string the redesign added or changed, grouped by risk (developer draft / legal / prototype dictionary / reused app Khmer), with a checkbox per row. Once corrected in `km.json`, P2 can be marked DONE: the automated checks below already pass.

Implemented:
- **All planned keys (`06 §3`) that have a call site**, EN + KM (prototype dictionary Khmer where it exists): `STAGE_*` (trip header titles), `ACTION_ARRIVED/START_RIDE/DROP_OFF` (trip buttons — `ACCEPT`/`ARRIVE`/`START_RIDE` values untouched because they are notification titles), `CANCEL_REQUEST`, `CANCEL_REQUEST_TITLE/MSG`, `YES_CANCEL`, `STAY` (decline-confirm, deferred from C5 — `showYesNoCustomDialog` gained optional `yesLabel`/`noLabel`, defaults unchanged for logout), `PICKUP`/`DESTINATION` (address overlines on trip sheet, receipt, history).
- **Plan-name alignment:** `APPROVAL_REJECTED_DES` → `APPROVAL_REJECTED_DESC`, `COLLECT_MSG` → `COLLECT_HINT` (as `EMPTY_*` earlier).
- **Hardcoded English removed** (new keys): register form and its error dialog (`REGISTER_TITLE/DESC`, `FULL_NAME(_HINT)`, `VEHICLE_TYPE(_HINT)`, `VEHICLE_COLOR(_HINT)`, `PLATE_NUMBER`, `DOCUMENTS`, `DOC_*`, `PHOTO_GALLERY/CAMERA`, `REGISTER_FIELDS_REQUIRED` — the bilingual "English - ខ្មែរ" pairs are now one language per locale; `PhotoSlot` lost its second title line); OTP error dialog (`PLEASE_TRY_AGAIN` + `OTP_INCORRECT` fallback); contact blurb and copyright; profile header error fallback; "Address not found" returned into trip address rows (`ADDRESS_NOT_FOUND`); driver marker title (`DRIVER_LOCATION`); vehicle type names in the drawer header (`VEHICLE_*`, fixes "Classis Car"); client-side network error messages in `ApiException` (`NO_INTERNET_CONNECTION`, `CONNECTION_TIMED_OUT`, `PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG`); Terms content (`TERM_1`…`TERM_5`, same order); the drawer wordmark now uses `AppConstant.titleApp` instead of translating the brand.
- `MOBILE_NUMBER` added to km (was en-only since before the redesign). Locale files: 181 keys each, identical key sets.
- **Found by the KM 1.3× render and fixed:** `TripMeterStrip` broke "00:12:40" and "≈ ៛7,600" mid-figure in a third-width cell; values now scale down on one line with 6 px inner padding.

Not changed, on purpose:
- Server-sent messages (e.g. "OTP not correct") are shown as the backend sends them — English. Client-side localization cannot fix them (follow-up).
- Android notification **channel names** ("High Importance Notifications", "Booking"/"Urgent Booking") — OS settings strings fixed at channel creation, not screen copy (follow-up).
- Legacy `core/api_service` `ErrorMessage` constants — not shown on any redesigned screen.
- `SECONDS` — no call site left (C3 removed the "seconds" text); `REQUEST_EXPIRED` belongs to P3's expiry feedback, which is not built; `RETRY` — screens use the existing `TRY_AGAIN`/`PLEASE_TRY_AGAIN`.
- Keys now unused (`NEW_RIDE_REQUEST`, `GO_TO_PASSENGER`, `PREPAIR_TO_GO`, `CARRYING_PASSENGER`, `CANCEL_BOOK`, `CONTANCT_CELCEL_BOOK`, `PASSENGER_LOCATION`, `WHERE_TO_GO`, `DROP`, `CANCEL`, and older ones) are left in the files — "add keys, don't edit values".

Files:
- `assets/translations/en.json`, `km.json`; `docs/l10n-km-review.md` (new)
- `lib/presentation/screens/booking/{view.dart,widgets/ride_request_bottom_pop_widget.dart,widgets/show_distand_and_price_widget.dart}`, `history/widgets/history_card_widget.dart`, `calculate_fee/{view.dart,widgets/receipt_card.dart}`, `register/{logic,view}.dart`, `register/widgets/photo_slot.dart`, `otp/logic.dart`, `contact_us/{state,view}.dart`, `term_condition/{state,view}.dart`, `profile/widgets/profile_header_widget.dart`, `drawer/{view.dart,widgets/approval_gate.dart}`
- `lib/presentation/widgets/{yesno_dialog_widget,x_dropdown_search}.dart`, `lib/app/funtion_convert.dart`, `lib/core/network/api_exception.dart`, `lib/core/helper/get_address_latlng_helper.dart`, `lib/taxi_single_ton/taxi_location.dart`
- Tests: `test/l10n/translations_test.dart` (new); `history_widgets_test`, `content_widgets_test`, `auth_views_test` updated

Verification:
- Analyze: PASS (no new findings)
- Tests: PASS — 477/477. New guards: EN/KM identical key sets and no empty values; the three notification-title values pinned (EN + KM); every literal `'KEY'.tr()` in `lib/` exists; no hardcoded English in widget text parameters in `lib/presentation` + `lib/app` (allowlist: "English", the Smart/Cellcard carrier prefixes, the plate format placeholder).
- Build: PASS — debug APK
- UI review: PASS — trip sheet stages 1–4 with header, register and terms rendered **in Khmer at text scale 1.3** at 360 px; plus the S1–S4 renders regenerated. One defect found and fixed (meter). 
- **Native Khmer sign-off: NOT DONE — the blocker.**

---

### P1 — Motion and micro-interactions

Status: DONE (2026-09-14)
Dependencies: S5 (DONE)

**Defect found and fixed — request countdown under reduced motion.** `SmoothCircularCountdown`'s `AnimationController` *is* the ride-request timer (its dismissal calls `Get.offAllNamed('/home')`). With the default `AnimationBehavior.normal`, Flutter runs a controller at 5% of its duration when the OS asks to remove animations (`animation_controller.dart:651`), so on those devices a 30 s request expired after ~1.5 s and the driver was sent home. Now `AnimationBehavior.preserve`. Same fix on `TAutoDismissBar` (decoration of the 10 s passenger-cancel timer). A regression test fails without the fix (verified by reverting it in the mirror).

Implemented (`02 §15`, `05` Motion):
- **Motion tokens** — `ds/t_motion.dart`: `Motion` durations/curves, `reduceMotion(context)`, `TPulseDot`, `TScaleIn`, `TCrossFade`.
- **Routes:** fade + 10 px rise, 250 ms (`lib/routes/transitions.dart`, installed on `GetMaterialApp`). `/home` keeps `Transition.noTransition`. **Android only** — GetX's custom-transition branch skips its iOS back-swipe detector, so iOS keeps the platform slide and the swipe-back gesture (at 250 ms).
- **Sheets** (`showTSheet`): 300 ms on `cubic(.2,.9,.3,1)`; no animation under reduced motion.
- **Dialogs** (`TDialog`, i.e. all four `show…Dialog` bodies): scale .9 → 1 over 250 ms on top of the route fade; no scale under reduced motion. Dismissal/navigation untouched.
- **Trip sheet:** stage content cross-fades over 150 ms (`TCrossFade`, keyed by the content branch so a fare/address update inside a stage never animates; the outgoing content ignores taps; the meter and action bar are outside it). Timeline steps fill over 200 ms (colour only).
- **Pulses:** trip stage dot 1.2 s; online pill dot 1.4 s only while online; both still under reduced motion.
- **Offline banner:** slides down over 200 ms (fade only under reduced motion).
- **Reduced motion elsewhere:** `TButton`/`TIconButton` press scale off; `ShakeWidget.shake()` no-ops (the inline error still shows).
- Selectable controls' 150 ms colour change moved onto `Motion.colorChange`.

Files:
- New: `lib/presentation/widgets/ds/t_motion.dart`, `lib/routes/transitions.dart`, `test/presentation/widgets/ds/motion_test.dart`
- Modified: `lib/app/root_main.dart`, `ds/{ds,t_button,t_selection,t_overlays,t_dialog}.dart`, `widgets/{count_down_widget,shake_widget}.dart`, `booking/widgets/{trip_header,trip_timeline,ride_request_bottom_pop_widget}.dart`, `drawer/widgets/{online_status_pill,offline_banner}.dart`

Deviations / notes:
- "Sheets fade only" under reduced motion is implemented as **no** animation (`AnimationStyle.noAnimation`); a fade-only modal sheet would need a custom route.
- Drawer stays at Flutter's fixed ~246 ms (spec 280 ms) — `Scaffold.drawer` exposes no duration; within the 300 ms rule.
- Material's dialog fade stays at its 150 ms default; the 250 ms scale runs with it.
- Done-when reading: *transitions* finish ≤ 300 ms (asserted in a test). Progress indicators that depict real time — the request countdown, the auto-dismiss bar, spinners — and the pulses are not transitions; the map camera is exempt by the roadmap.
- Money: no widget tweens a figure; the only animations near amounts are the stage cross-fade (whole content, keyed by stage) and the dialog entrance.

Verification:
- Analyze: PASS (no new findings)
- Tests: PASS — 473/473. New (12): every transition ≤ 300 ms; countdown keeps real time under reduced motion (fails without the fix) and counts normally otherwise; pulse animates / still when inactive / still under reduced motion; cross-fade outgoing stage untappable; same-key value change not animated; shake suppressed; dialog scales from .9 and not under reduced motion; route transition per platform.
- Build: PASS — debug APK
- UI review: motion is reviewed through the tests above (frame-by-frame values); static layouts unchanged (the dot widgets are the same size).
- Device-only, carried by Q1: feel of the route/sheet/dialog timings; OS "Remove animations" walk-through (pulses stop, sheets and dialogs don't slide or scale); iOS swipe-back still works

---

### S5 — Legacy token cleanup

Status: DONE (2026-09-14)
Dependencies: C1–C6 (`[Q]` — code-complete; S5 needs only that no screen still uses the legacy tables, which the grep below proves), S1–S4 (DONE); DD-34

Implemented:
- **Deleted** `lib/core/theme/colors.dart` (`AppColors`) and `lib/core/theme/text_styles.dart` (`ThemeConstands`, `AppTextStyles`) — deleted, not commented out.
- **Deleted the superseded legacy widgets**, each verified to have no importer: `x_text_field.dart` + `text_field_decoration.dart` + `decorated_input_border.dart` (→ `TTextField`), `fbtn_widget.dart` + `x_button.dart` (→ `TButton`), `card_atta_widget.dart` (→ `PhotoSlot`), `x_showmodal_bottom.dart` (→ `showTSheet`), `loading_widget.dart` (→ in-button spinners, DD-17), `t_image_widget.dart` (→ `TAvatar`). These were the last five files importing the legacy tables.
- `simmer_widget.dart`: removed `ShimmerWalletCard`, `ShimmerBookStory`, `ShimmerNotification` (no callers since S1–S3); `ShimmerProfile` stays (drawer header).
- The two remaining off-palette literals — the red route polyline on the trip map (`booking/view.dart`) and in history detail (`history_detail/logic.dart`) — now use `TaarraaColors.light.brandIdentity` (a const, so no `context` across the async gap). History detail's view-side `copyWith` recolour from S1 is removed as redundant.
- Comments in `app_theme.dart` / `tokens.dart` that described the legacy tables as "still in place" updated. `primaryColor*` values kept (Material fallbacks), comment corrected.

Files:
- Deleted: `lib/core/theme/{colors,text_styles}.dart`; `lib/presentation/widgets/{x_text_field,text_field_decoration,decorated_input_border,fbtn_widget,x_button,card_atta_widget,x_showmodal_bottom,loading_widget,t_image_widget}.dart`
- Modified: `lib/presentation/widgets/simmer_widget.dart`, `lib/presentation/screens/booking/view.dart` (polyline colour + import only), `lib/presentation/screens/history_detail/{logic,view}.dart`, `lib/core/theme/{app_theme,tokens}.dart`

Verification:
- Roadmap grep `grep -rn 'Colors\.\|Color(0x\|ThemeConstands\|AppTextStyles' lib/presentation`: nothing meaningful — only `Colors.transparent` (7, structural) and three `TaarraaColors.light…` token references that contain the substring.
- Analyze: PASS — no errors; `lib` + `test` findings fell from 41 to 21, all `info`s in untouched non-UI code, plus the documented `booking/view.dart` warning.
- Tests: PASS — 461/461
- Build: PASS — debug APK
- UI review: PASS — all S1–S4 screen renders (29) regenerated after the deletions, EN/KM, 390/320 px; no change. The only visible change S5 makes is the route polyline colour (red → brand orange), which lives on the map and is carried by Q1.
- Device-only, carried by Q1: the trip-map route in the brand colour; the roadmap's "walk every screen in both locales" on a device for C1–C6

---

### S4 — Auth: splash, login, OTP, register

Status: DONE (2026-09-14)
Dependencies: F1–F3; DD-23 (no Skip, no boot log), DD-24 (no Register link, no step dots, validation unchanged)

Implemented:
- **Splash** (`03 S01`): `bg.page`, `SplashMark` — today's `Tara2.png` in a 96 px `r 28` surface badge with the float shadow, "TARA DRIVER" (display, 3 px tracking) over "តារា តាក់សុី" in `brand.text`. `SplashLogic` untouched (3 s delay, permission request, token routing, exception safety).
- **Login** (`03 S02`): `LanguageSegment` inline top-right (replaces the flag + language sheet; same `context.setLocale`); headline/description on existing keys; `TTextField.phone` with the **same three formatters in the same order**, the same shake key, the inline error from the same two flags; 56 px `TButton` pinned at the bottom with its own spinner; field disabled while submitting (the full-screen `LoadingWidget` is gone).
- **OTP** (`03 S03`): back `TIconButton`; headline; `OTP_SENT_TO` + "+855 <number>" bold; `OtpInput` (Pinput theme per `02 §8`: 64 high, 26/700, `r.control`, focus = `border.focus` + 3 px `brand.tint` halo, boxes fill the width); boxes disabled + a 20 px spinner while verifying; `OtpResendRow` — countdown pill (`brand.tint`, tabular) → tertiary "Resend code" when the controller enables it.
- **Register** (`03 S04`): `TTextField`s; the vehicle dropdown restyled on tokens (still `SearchableDropdown`: search + clear kept) with a skeleton while vehicles load and an inline error + Try again → `getAllVehicles` (previously rendered nothing); colour + plate side by side (stacked under 340 px); `PhotoSlotGrid` 2×2 of `PhotoSlot` (dashed → solid `success` + photo + check badge + 48 px remove); the picker is now a `showTSheet` with the same two options calling the same `pickFromGallery`/`pickFromCamera` (the F3 note's planned migration off `xShowModalBottomSheet`); 56 px pinned submit with spinner, fields and slots disabled while submitting.
- `TTextField` gained an optional `textInputAction` (login keeps `send`).

Behaviour preserved (the risk of the task):
- Login: `validate` untouched — empty → `CHECK_YOUR_PHONE_NUMBER_ERROR`; `< 10` characters **of the formatted text** → `CHECK_PHONE_NUMBER_DIGIT_ERROR`; normalisation, `onResend` binding, server-error dialog. The keyboard action still **only validates** (it never submitted; `03 S02` says it should — baseline kept).
- OTP: `onCompleted` → `verify` on the 4th digit; countdown from `seconde ?? 60`; resend enabled at 0; debug bypass; new-driver → register; failure clears the pin.
- Register: enabled unless name **and** plate are both empty (`RegisterPage.canSubmit`, verbatim); missing photos still end in the controller's error dialog; `tlog` + unfocus before `submit`; post-success calls untouched.

Files:
- `lib/presentation/screens/splash_screen/view.dart`, `login/view.dart`, `otp/view.dart`, `register/view.dart`, `register/widgets/photo_slot.dart` (new)
- `lib/presentation/widgets/x_dropdown_search.dart` (tokens only; register is its sole user), `lib/presentation/widgets/ds/t_text_field.dart` (`textInputAction`)
- `assets/translations/en.json`, `km.json` (`OTP_SENT_TO`, `REGISTER_SUBMIT` — KM from the prototype dictionary)
- `test/presentation/screens/auth/auth_views_test.dart` (new), `test/helpers/localized_host.dart` (+ `localizedHostPage`)

Deviations / notes:
- Kept the splash asset (`Tara2.png`) and wording — the brand choice `03 S01` leaves open is not made here.
- The register form copy stays as shipped (bilingual hardcoded labels, "Fill Information", the hint strings); only the submit label moved to a key. That copy belongs to P2.
- The OTP boxes are disabled while verifying, so the keyboard closes; after a wrong code the driver taps a box to retype (the pin is still cleared by the controller).
- Gallery option uses `DsIcons.doc` (no image glyph in the DS set).
- Left without callers by S4 and deleted in S5: `CardUploadAttachment`, `xShowModalBottomSheet`, `XButton`, `XTextField`, `FBTNWidget`, `LoadingWidget`. (`ShakeWidget` stays — `TTextField` uses it.)

Verification:
- Analyze: PASS (no findings in S4 files)
- Tests: PASS — full suite 461/461; `login/logic_test.dart` green. New: login view shows the empty and short-number errors without calling the API (a repository that throws if called), `"1234567"` formats to `"12 345 67"` and is rejected by the formatted-length rule, submitting disables the field and spins the button, language control is inline; OTP auto-submits on the 4th digit and not before; countdown pill vs Resend; sent-to line; `canSubmit` truth table incl. one-character name; PhotoSlot pick/clear; SplashMark has no Skip.
- Build: PASS — debug APK
- UI review: PASS — full Login, OTP, Register and Splash pages rendered with fake controllers at 390/320 px, EN/KM. Found and fixed: a 55 px overflow in the language control (a fixed width too narrow for "English | ខ្មែរ" — caught by the new test), and the vehicle hint wrapping inside the 56 px field.
- Device-only, carried by Q2: wrong OTP, resend, real vehicle list, camera/gallery picker, a real registration

---

### S3 — Announcements, Terms, Contact

Status: DONE (2026-09-14)
Dependencies: F1–F3; DD-06 (announcements stay a pushed route from the bell; no drawer tab)

Implemented:
- **Announcements** (`03 S12`): `TAppBar` "Announcements"; `NewsCard` — 15/700 title (2 lines), 13 px secondary body (2 lines), date; unread (`status == 0`, same rule) = brand border **and** dot, dot spoken as "Unread"; `NewsCardSkeleton`s; `TErrorState` + Try again → `reload`; `TEmptyState` "No announcements yet" (pull-to-refresh still works when empty). Paging trigger, footer and `NotificationDetailArgs(appOpened: true)` unchanged.
- **Announcement detail** (`03 S13`): `TAppBar` with the **same back rule** (`appOpened == true` → pop, else `Get.offNamed(home)` for cold FCM opens); card with 17/700 title, caption date, 14/1.65 body, existing images full width with `r.md` corners (skeleton while loading, placeholder on error); skeleton for initial/loading; `TErrorState` with the server message + Try again → `logic.load(notificationId)`.
- **Terms** (`03 S14`): `TermRow` — numbered `brand.tint` badge on a surface card. Content source unchanged.
- **Contact** (`03 S15`): logo in a badge, blurb, `ContactRow` ×3 (brand glyph, chevron, tap → existing `callPhone`/`sendEmail` with the same arguments), address row without chevron or tap, copyright. Now a `ListView` — the old `Column` + `Spacer` could overflow on short screens.
- **Shared `TAppBar`** (`ds/t_app_bar.dart`, exported from `ds.dart`): back + title + hairline, optional `onBack`. S1's history detail now uses it instead of its hand-built header (removed the duplicate).

Files:
- `lib/presentation/screens/announcement/view.dart`, `announcement/widgets/news_card.dart` (new)
- `lib/presentation/screens/announcement_detail/view.dart`
- `lib/presentation/screens/term_condition/view.dart`, `lib/presentation/screens/contact_us/view.dart`
- `lib/presentation/widgets/ds/t_app_bar.dart` (new), `ds.dart`; `lib/presentation/screens/history_detail/view.dart` (uses `TAppBar`)
- `assets/translations/en.json`, `km.json` (`ANNOUNCEMENTS` — KM from the prototype dictionary; `EMPTY_ANNOUNCEMENTS`, `UNREAD` — KM drafts)
- `test/presentation/screens/announcement/announcement_widgets_test.dart`, `test/presentation/screens/content/content_widgets_test.dart` (new)

Deviations / notes:
- Detail app bar reads "Announcements" (prototype) instead of `NOTIFICATION_DETAIL`; the `TITLE`/`CREATED_DATE`/`DESCRIPTION` section labels and the hardcoded English "Images" label are gone. Those keys are now unused (S5).
- `formatAnnouncementDate` uses `DateTime.tryParse`: a null/malformed `updated_at` now omits the date instead of throwing inside `build` (the old `DateTime.parse('null')` red-screened).
- The address row uses `DsIcons.home` — the DS icon set has no map-pin glyph.
- "Smart: " / "Cellcard: " prefixes and the Contact data stay hardcoded English, as before (P2 copy sweep).
- `ShimmerNotification` now has no callers (S5).

Verification:
- Analyze: PASS (no findings in S3 files)
- Tests: PASS — full suite 451/451 (new: unread border + dot + spoken label, read state, detail body with/without date, `formatAnnouncementDate` null/malformed, TermRow badge, ContactRow tappable vs info, `TAppBar` override and default pop)
- Build: PASS — `flutter build apk --debug` (3.44.1)
- UI review: PASS — rendered NewsCard (read/unread), TermRow, ContactRow (tappable/info) and the detail body at 390/320 px, EN/KM; long Khmer titles and a long address wrap cleanly
- Device-only, carried by Q2: open the detail from an FCM tap in background and terminated states (back → home); call and email launch; paging against the live API

---

### S2 — Wallet

Status: DONE (2026-09-14)
Started: 2026-09-14
Dependencies: F1–F3; DD-21 (no withdraw, no invented sub-labels), DD-04 (money neutral, tabular)

Files:
- `lib/presentation/screens/wallet/view.dart` (rebuilt body)
- `lib/presentation/screens/wallet/widgets/wallet_widgets.dart` (new — `WalletBalanceCard`, `TransactionRow`, `WalletSkeleton`)
- `test/presentation/screens/wallet/wallet_widgets_test.dart` (new)

Implemented:
- `WalletBalanceCard` ×2 side by side (equal height): Wallet on `success.tint` with a `success` label, Commission fare on `brand.tint` with a `brand.text` label; wallet glyph; amount in `title`, tabular, `text.primary`. Labels are the existing `WALLET` / `COMMISSION_FARE` keys — no sub-labels (DD-21).
- Filter chips: the existing dynamic filters (All + backend `type_name`s, shown only when there is more than one type) rendered as `TChip`.
- `TransactionRow`: neutral wallet glyph · typeName (or "—") · "date · status" caption · amount right in `text.primary`, tabular. No in/out colour or sign (debit convention unconfirmed).
- States: `WalletSkeleton` (two tiles + three rows) for initial/loading; `TErrorState` with the existing `PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG` / `PLEASE_TRY_AGAIN` → `logic.fetch`; `TEmptyState` `NO_TRANSACTIONS_YET`.
- Pull-to-refresh → `logic.fetch` (new; the tab had no refresh besides reopening it).
- Visual-review fix: a balance too wide for its half-width tile scales down on one line (`FittedBox`) — at 320 px "1,250,000.50 $" was breaking mid-number.

Behaviour preserved:
- `WalletLogic`/`WalletState`/`wallet_presentation.dart` untouched: fetch in `initState` on every tab open, `visibleTransactions` (filter then newest first), `availableTypeFilters`, `formatWalletAmountWithSymbol` for balances and rows (row currency falls back to the wallet's), `formatTransactionDate`.
- No new copy keys.

Deviations / notes:
- On error the balance tiles no longer show a shimmer above the error message; the whole tab shows one error state. Loaded with a null `data` shows the transactions section without tiles (previously: shimmer tiles that never resolved).
- Card order is Wallet then Commission fare (spec + prototype); it was Commission first.
- The commented-out top-up UI and its `_cardBank` helper (legacy `AppColors`, marked `unused_element`) were removed from the view — no API, not in the design (DD-21). `state.bankSelected` / `logic.selectBank` are left in place, now with no view callers (S5).
- The spec's header refresh icon is not built: the title lives in the C1 shell app bar; pull-to-refresh covers it (same call as S1).
- `ShimmerWalletCard` (`simmer_widget.dart`) now has no callers — S5.

Verification:
- Analyze: PASS
- Tests: PASS — full suite (wallet widget tests: label only, USD decimals kept, neutral + tabular amount in both tones, caption join, no colour on a negative amount, skeleton)
- Build: PASS — debug APK
- UI review: PASS — tiles, chips, rows and empty state rendered at 390/320 px, EN/KM; found and fixed the mid-number wrap
- GetX/state: untouched
- Device-only, carried by Q2: loaded/empty/error against the live API, every filter chip on real data
---

### Q1 — Visual QA against the prototype

Status: DONE (2026-09-14)
Started: 2026-09-14
Dependencies: F1–F3, all screen tasks (S1–S5, C1–C6)

What it covers:
All 34 redesigned surfaces rendered at 390 px and 320 px, in EN and KM, via a widget-test harness. Prototype (`docs/taarraa-driver-prototype.html`) captured headlessly at the same sizes via CDP. 100 side-by-side pairs (app left, prototype right) + 1 contact sheet built for visual review. Machine-readable geometry (text styles, colours, radii, fills, borders, controls) extracted per render for automated token-conformance checks.

Key findings:
- **Text colours**: all 10 rendered colours are on-token. No renegade text colours.
- **Controls**: TButton 350×56, TIconButton 48×48, app-bar 56×64, approval 308×48 — all matching `02 §7`.
- **Radii**: on-token (0, 12, 14, 16, 20, 22, 999). Two deviations: `10` in TTabs pill (tighter than `md` 12), `28` in splash wordmark (decorative).
- **Type scale**: 12–30 px, weights 400/700, all KantumruyPro. Two off-scale: `19` px (meter override of `numericLg` 22 — fit constraint), `26` px (OTP input digits — legibility).
- **Fills**: `#000000` appearances are `Colors.transparent` artifact (no `Colors.black` in codebase). `#FF4500` fills are allowed graphic-only brand per DD-02/roadmap.
- **Theme**: prototype is dark, app is light — intentional per DD-01 ("The prototype supplies layout, structure, and component hierarchy only — not surface colours").
- **Harness fidelity**: 3 string-translation literals fixed; 2 directory-creation bugs fixed; sheet surfaces re-hosted with `Scaffold(page: true)` pattern matching the a11y test.

Defects found: zero rendering defects. Five harness-only fidelity fixes (translation literals, directory creation, sheet hosting, renderObject cast).

Artifacts:
- `docs/qa/q1/renders/` — 136 PNGs
- `docs/qa/q1/geometry/` — 136 JSONs (`<key>__<lang>__<width>.json`)
- `docs/qa/q1/proto/` — 136 prototype captures
- `docs/qa/q1/pairs/` — 100 side-by-side PNGs
- `docs/qa/q1/qa1_contact_en_390.png` — contact sheet (22 surfaces)

Files:
- `test/qa/visual_qa_test.dart` (new — 34-surface harness)
- `docs/qa/q1/` (new — all artifacts + `README.md`)

Verification:
- Analyze: PASS (clean)
- Tests: PASS — 34/34
- UI review: awaiting user sign-off of side-by-side pairs/contact sheet (agent cannot view images)
- DD-01 compliance: confirmed (light app vs dark prototype, graphics-only dark usage)
- Device-only, carried by Q2: live-backend regression, G0 baseline comparison, FCM/navigation checks
---

### S1 — History and history detail

Status: DONE (2026-09-14)
Started: 2026-09-14
Dependencies: F1–F3; DD-19 (card is the tap target), DD-20 (detail shows only what the args carry)

Files:
- `lib/presentation/screens/history/view.dart` (rebuilt body)
- `lib/presentation/screens/history/widgets/history_card_widget.dart` (rebuilt; + `HistoryCardSkeleton`)
- `lib/presentation/screens/history_detail/view.dart` (rebuilt body; + `TripDetailCard`)
- `lib/presentation/screens/booking/widgets/show_distand_and_price_widget.dart` (legacy `ShowDistandWidget` deleted — last caller gone)
- `assets/translations/en.json`, `km.json` (`FAILED_TO_LOAD_DATA`, `EMPTY_COMPLETED`, `EMPTY_CANCELLED`, `TRIP_DETAILS`)
- `test/presentation/screens/history/history_widgets_test.dart` (new)

Implemented:
- History tab: `TTabs` (Completed / Cancelled → `logic.switchTab`); skeleton cards while the list is empty and loading; `TErrorState` + Try again → `logic.reload` when empty with an error; `TEmptyState` "No completed trips yet" / "No cancelled trips" when the list is exhausted and empty — scrollable, so pull-to-refresh still works on an empty account.
- `HistoryCardWidget` (`04 § B`): `TCard` → `TAvatar` (photo, initials fallback) · `#invoice` in tabular figures · "passenger · date" (wraps to 2 lines) · amount right (`៛` + `formatRielAmount`, neutral) → status badge (success/danger, `statusName` label) + payment-method badge when present → compact route box (dot + 13 px line per address, `.hroute`; the pickup/destination labels are spoken, not shown) → distance/duration meta.
- Visual-review fixes: the route box first used full `TAddressRow`s (overline + 16 px bold), which made each card nearly twice the prototype's height; the subtitle truncated the date at 320 px Khmer.
- DD-19: the `image_map.png` thumbnail is gone; its `Get.toNamed(mapHistoryDetail, MapHistoryDetailArgs(...))` moved to the card's `onTap` with the argument construction copied verbatim. The flag `showMap` was renamed `canOpenDetail` and is still `indexActive != 1`, so exactly the cards that had the thumbnail are tappable; cancelled cards are not.
- History detail (`03 S10`, DD-20): `TAppBar` "Trip details" (shared with S3), map in the top 55%, `TripDetailCard` below — completed badge, Distance / Duration / Total price from the args. No invoice, passenger, date or replay.

Behaviour preserved:
- `HistoryLogic`/`HistoryState`/`PaginatedController` untouched: status filter (4/5), `pixels == maxScrollExtent` paging trigger, `RefreshIndicator → reload`, the footer (`items.length < 10` → nothing, else spinner).
- Every card value keeps its formatter and its "UNKNOWN" rule (pickup/destination/duration when not completed; destination row hidden when cancelled). The `passenger!`/`payment!`/`driver!.vehicle!` null-asserts are kept (removing them is a behaviour change — queue with the B-items).
- `HistoryDetailLogic`/binding untouched: markers, 1 s startup timer, Directions call; all `GoogleMap` properties identical.

Deviations / notes:
- Route polyline recoloured to `brandIdentity` in the view via `Polyline.copyWith` (logic still builds it red) — spec asks for a brand-coloured route; keeps the controller untouched.
- A cancelled card's subtitle omits the date instead of printing "Unknown" beside it; its amount still renders as today (usually ៛0).
- The optional refresh icon (`03 S09`) is not built: the title lives in the C1 shell app bar; pull-to-refresh is the refresh path.
- `FAILED_TO_LOAD_DATA` was never in either locale file — the old error text rendered the raw key. The new key also fixes the announcements list, which shares `PaginatedController`.
- All four KM strings are **drafts** (no prototype donor) — native review at P2/Q1.
- `ShimmerBookStory` (`simmer_widget.dart`) now has no callers; `INVOICE`, `METHOD`, `DATE_TIME` usage dropped from history — left for S5.

Verification:
- Analyze: PASS
- Tests: PASS — full suite (history tests: completed tappable with the destination spoken, cancelled inert with UNKNOWN rules and no destination line, no thumbnail, skeleton, detail card 3 rows and no replay). The first run caught a bad fixture (`invoice_id` is an `int`).
- Build: PASS — debug APK
- UI review: PASS — completed/cancelled cards, tabs and detail card rendered at 390/320 px, EN/KM; two fixes applied (above)
- GetX/state: untouched
- Device-only, carried by Q2: paging, pull-to-refresh, empty account, offline error against the live API; tap a completed card (args) and a cancelled one; the map and polyline
---

### C4 — Trip stages: going to pickup, at pickup, in progress

Status: QA (code complete)
Started: 2026-09-12
Dependencies: C3 (done, QA); DD-13 OPEN — default rule: **ship without a Drop-off confirmation** unless Product says otherwise

Files:
- `lib/presentation/screens/booking/view.dart` (build only)
- `lib/presentation/screens/booking/widgets/ride_request_bottom_pop_widget.dart`
- `lib/presentation/screens/booking/widgets/show_distand_and_price_widget.dart`
- `lib/presentation/screens/booking/widgets/trip_action_bar.dart` (`primaryVariant` only)
- `assets/translations/en.json`, `km.json` (`EST_FARE`, `EST_NOTE`)
- `test/presentation/screens/booking/trip_widgets_test.dart`

Scope:
- Per-stage sheet content; a new [TripMeterStrip](`04 §B`) moves the in-trip meter **into** the sheet and keeps it visible when collapsed (`Done When`).
- Estimate labelling (`DD-14`): the in-trip price reads "≈ Est. fare", no longer "TOTAL_PRICE".
- Drop-off spinner starts **on tap**, not after geocoding.

Implemented:
- `TripMeterStrip` (new, in `show_distand_and_price_widget.dart`): three cells — DURATION / DISTANCE / EST_FARE — with vertical rules on `stageOnTripTint`; the fare cell reads "≈ ៛…" and the warning note `EST_NOTE` with a `DsIcons.info` icon sits below. It renders pre-formatted strings only; the legacy `ShowDistandWidget` was kept for `history_detail` until S1, which deleted it.
- Sheet content per stage: 1 (request) and 2 (en route) unchanged from C3; 3 (at pickup) = passenger, destination in focus with its distance as meta, and "≈ Est. fare" only once `totalFee` is computed — the driver's own start-address line is gone; 4/6 (in progress/dropping) = destination line only (the meter carries the figures).
- Meter pinned for `processType == 4 || processType == 6` **above** the collapsible region.
- `view.dart`: the top-of-map `ShowDistandWidget` block removed from `_topOverlay`; the three meter strings are computed in `build()` with the fare/distance branch expressions taken verbatim from the old strip; view-local `_dropPending` set in the drop tap and passed as `isLoading: isLoading || _dropPending`; new `duration`/`distance`/`fare` sheet args; unused `currentLocationName` dropped from the sheet.
- `TripActionBar.primaryVariant` added; the sheet passes `TButtonVariant.success` for Start ride (`DD-12`); Drop off stays primary and is **never** red.
- Locales: `EST_FARE` (EN "Est. fare" / KM "ថ្លៃប៉ាន់ស្មាន") and `EST_NOTE` (EN "≈ estimated — final fare is confirmed after drop-off" / KM from the prototype dictionary).

QA acceptance (vs G0 baseline video + `tlog` oracle — oracle not yet captured):
- One trip **with** a destination and one **without**; duration/distance/fare must equal the baseline at the same points.
- Resume directly into each stage (server statuses 2, 8, 3).
- `tlog`: `rideArrival`, `startDrive`, `dropDrive` match the oracle.
- Meter's three values must equal today's expressions exactly, including the no-destination branch.
- Meter stays visible when the sheet is collapsed at 4/6; the Drop-off spinner starts on tap; Start ride renders in the success fill.

Notes:
- Drop off still calls `getLocation(TripStage.completing)` (reverse-geocodes before `complete()`).
- `_dropPending` is never explicitly reset: success navigates away and an error dialog double-pops the route (`DD-33`). If `getCurrentPosition` itself throws, the button stays spinnered — the same dead end the old silent button had, now with feedback.
- Meter values are not re-formatted or re-computed anywhere; only the label and the "≈" prefix changed (`DD-14`).

QA:
- Visual: NOT RUN (needs device)
- Functional: NOT RUN
- GetX/state: PASS (untouched)
- Analyze: PASS (only pre-existing findings in preserved code: `view.dart` `refreshApp == true`, `_clearPolyline()` return type, legacy `ShowDistandWidget` `withOpacity`)
- Tests: NOT RUN (new TripMeterStrip and DD-12 success-variant tests unexecuted; env block)

---

### C5 — Trip dialogs and errors

Status: QA (code complete)
Started: 2026-09-12
Dependencies: F3 (dialog bodies), C3 (wiring), C4; DD-33 OPEN — default **preserve the double pop**; DD-25 (bar is decoration, timer stays where it is)

Files:
- `lib/presentation/widgets/cancel_book_dialog_widget.dart` (button label only)
- `assets/translations/en.json`, `km.json` (`OK`)

Scope (roadmap:349, plan step 7):
- "Apply copy and icons to the trip dialogs; wire the three `TripActionError` variants." Plan step 7 already admits "Most of the work is already done by step 2" — the F3/C3 combination restyled the four dialog bodies and wired the error call sites, so this step is a copy/icon sweep at the call sites (`booking/view.dart`, `app/alert_widget.dart`) plus an audit, not a rebuild.

Audit vs Done When (code-level, PASS):
- All three error variants use localized keys and `comfirmBook: true` (`_onTripError`, `view.dart:475-489`): `RIDE_ALREADY_ACCEPTED`+`BOOKING_ALREADY_ACCEPTED`, `COMFIRM_ERROR`+`CAN_NOT_CONFIRM_BOOKING`, `PLEASE_TRY_AGAIN`+`PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG`. All six keys exist in both locale files; dismissal behaviour matches baseline (`DD-33` — the switch is untouched).
- Passenger-cancel (`AlertWidget.cancelBooking`, fired from `socket_service.dart:178` on `onPassengerCancelDrive`): `barrierDismissible: false`, warning-style `danger` icon, 10 s `TAutoDismissBar` (decoration only), timer still scheduled in the builder with `close` never set — the double-navigation defect (B4) is deliberately preserved (`DD-25`), OK primary → home.
- Decline-confirm: the `showYesNoCustomDialog` restyle and the `driverCancelDrive`-before-`onCancel()` emit order are C3's work; the NO-primary / YES-destructiveOutline layout matches `04 § confirm`. The prototype's "Cancel request?"/"Yes, cancel"/"Stay" phrasing is **deferred to P2** (copy sweep) — the dialog is shared with Logout (unreachable, DD-05), so the call-site copy stays `CANCEL_BOOK`/`CONTANCT_CELCEL_BOOK`.
- Resume: `RESUMING_TRIP` + spinner, the 2 s timer in `HomeLogic` (C2) — untouched.

Implemented (the residual copy delta C5 owns):
- Passenger-cancel primary label `'YES'` → `'OK'` (`03 §595`: "an 'OK' primary (existing YES → home)"); doc-comment updated to match.
- New `OK` key in both locales (`"OK": "OK"` — language-neutral) so the label resolves from the locale maps instead of falling back to the bare literal key.

NOT changed anywhere: signature, dismissal, barrier or navigation semantics (DD-33/DD-25); `t_dialog.dart` untouched — variant behaviour lives in the `show…Dialog` bodies per `04 §287`.

QA:
- Visual: NOT RUN (device: trigger each trip error + passenger-cancel; compare post-dismiss routes to the G0 baseline)
- Functional: NOT RUN
- Analyze: PASS on touched files (ran on installed 3.44.1 — the pinned 3.38.9 is not installed; `fvm` hangs fetching it). No new findings.
- Tests: n/a for this change (no behaviour delta); existing tests still NOT RUN (env block)
- GetX/state: PASS (untouched)

---

### C6 — Payment

Status: QA (code complete)
Started: 2026-09-12
Dependencies: F2 (TButton/TAmount/TBadge/TCard/TKeyValueRow/TAddressRow), F3 (error dialog), C4; DD-04 (money neutral, tabular) + DD-18 (server figures, no success overlay) settled

Files:
- `lib/presentation/screens/calculate_fee/view.dart` (rebuilt body)
- `lib/presentation/screens/calculate_fee/widgets/receipt_card.dart` (new — `ReceiptCard`, `TotalBox`)
- `lib/presentation/screens/calculate_fee/logic.dart` (error copy → keys; +easy_localization import)
- `lib/presentation/widgets/error_dialog_widget.dart` (`'Try Again'` → `TRY_AGAIN` key)
- `lib/presentation/screens/booking/widgets/passenger_row.dart` (optional phone/call params + `trailing`)
- `assets/translations/en.json`, `km.json` (`COLLECT_PAYMENT_TITLE`, `TOTAL_TO_COLLECT`, `COLLECT_MSG`, `TRY_AGAIN`)
- `test/presentation/screens/calculate_fee/receipt_card_test.dart` (new)

Scope (roadmap:376 / plan step 8):
- ReceiptCard, TotalBox, success button, "Collect payment" title, the real payment method; error copy at `logic.dart:78-81` → existing keys.

Implemented:
- `ReceiptCard` (`04 § B`): `TCard`(18) → `PassengerRow` (no phone line, no call button, method `TBadge` as the `trailing` slot **only when** `payment.paymentMethod` is present — the hardcoded "Unknown Payment" is gone, `DD-18`) → dashed `.dash` dividers → `TKeyValueRow` Distance / Duration / Date & Time (existing formatters `formatDistanceWithUnits`, `convertTimeString`, `formatDateTime`) → `TAddressRow` pickup/destination.
- `TotalBox` (`04 § B`, DD-04/18): `TCard` raised (s16); caption "Total to collect" left, `TAmount.hero` right; server `payment.amount` through `formatRielAmount` exactly as before; no estimate line.
- View: title `COLLECT_PAYMENT_TITLE`; receipt + total in the scroll body; `COLLECT_MSG` hint + pinned full-width `TButton` success (56, spinner from `PaymentStatus.loading`) replacing the red 200 px `FBTNWidget`.
- Both `routFrom` entry branches preserved (`FromDropBooking` / `FromHome` — same payload reads, incl. `payment.createdAt` → `formatDateTime`). Navigation/back behaviour untouched.
- `logic.dart` error: hardcoded `"Please Try Again!"` → `PLEASE_TRY_AGAIN` + `PLEASE_TRY_AGAIN_SOMETHING_WENT_WRONG`, `comfirmBook: false` unchanged (single pop).
- `error_dialog_widget.dart`: the non-confirm label `'Try Again'` (B8 hardcoded-English item) is now the `TRY_AGAIN` key — localization only, no behaviour change.
- `PassengerRow`: `phone`/`phoneLabel`/`callSemanticLabel` are now optional (subtitle and call button render only when provided); new `trailing` slot overrides the call button. The booking sheet's call site is unaffected.

Deviations / notes:
- The hint copy uses the prototype's `collectMsg` verbatim ("Collect cash from the passenger, then confirm below." — EN + KM from the prototype dictionary) rather than 03 §648's suggested wording "Collect the fare…"; intent identical, no new KM drafted.
- `TOTAL_TO_COLLECT` KM "ប្រាក់សរុបដែលត្រូវទទួល" is a **draft** (no prototype donor) — flag for native review at P2/Q1.
- The amount now appears once, in the TotalBox (the old money-on-red-metric rows are gone). `CALCULATE_FEE`, `METHOD`, `PAYMENT_COLLECTION`, `TOTAL_PRICE` keys are now unused — left in place for the S5 cleanup.
- The prototype's 1.6 s success overlay is deliberately not built (`DD-18`): navigation stays immediate.

QA:
- Business logic: PASS (unchanged — copy/keys/imports only; emit-after-REST order, profile refetch, `offAllNamed` intact)
- Analyze: PASS — no findings in any C6 file (full-project shows only pre-existing infos, incl. the documented `booking/view.dart` + `show_distand` ones)
- Tests: NOT RUN (env block) — new `receipt_card_test` (badge present/absent, no call button, TotalBox figure, "Unknown Payment" gone) unexecuted
- Visual/Functional: NOT RUN (device) — both entry paths (drop-off, resume status 6), the network-off error path, and `acceptPayment` in `tlog` vs the G0 oracle

---

## QA Pending — Code Complete, awaiting device verification (F1–C3)

Common to all six: `dart analyze` clean, `dart format` clean, no controller/binding/service/repository/model/route touched, **no new package**, tests written but **not executed**, visual verification **not performed**. GetX untouched throughout. `AppColors`/`ThemeConstands` deliberately left in place (deleted in S5).

### F1 — Design tokens, light theme, typography

Status: QA

Implemented:
- `lib/core/theme/tokens.dart` (new) — light design system: `TaarraaColors`, `TaarraaTextStyles` (11-step scale, EN/KM line heights, `FontVariation` for the variable face), `Insets/Radii/Sizes/Elevations`, `TaarraaTokens` ThemeExtension + `context.colors`/`context.texts`.
- `app_theme.dart` — `AppTheme.light(khmer:)` built from tokens.
- `lib/app/root_main.dart` — theme built from active locale (`DD-34`).
- `lib/main.dart` — `configLoading` on tokens (was yellow-on-green).

Files changed:
- `tokens.dart` (new), `app_theme.dart`, `root_main.dart`, `main.dart`, `test/core/theme/tokens_contrast_test.dart` (new).

QA:
- Visual: NOT RUN (expected app-wide shift to `#F2F2F5` bg, white app bars, `#CC3700` action fill per DD-02)
- Functional: NOT RUN
- GetX/state: PASS (untouched)
- Analyze: PASS
- Tests: NOT RUN (contrast test unexecuted; env block)

Notes:
- O-1 (Kantumruy tabular figures) and O-2 (variable face w700) unproven until a device run; fallbacks documented in `02 §2`.
- `primaryColor` left as identity orange so unmigrated screens don't shift early.

### F2 — Shared components

Status: QA

Implemented — `lib/presentation/widgets/ds/`:
- `ds_icons.dart` — `DsIcons` + `TIcon`; 20 SVGs in `assets/icon/ds/`, rendered by existing `flutter_svg`.
- `t_button.dart` (`TButton` 6 variants × 2 sizes, `TIconButton`; loading keeps width), `t_text_field.dart` (`TTextField` + `TTextField.phone`), `t_surfaces.dart` (`TCard`, `TBadge`), `t_selection.dart` (`TSegmented`, `TTabs`, `TChip`), `t_content.dart` (`TAvatar`, `TKeyValueRow`, `TAddressRow`, `TAmount`), `ds.dart` barrel, `test/presentation/widgets/ds/ds_components_test.dart` (new).

Deviations:
- Badge `danger/info/neutral` render outline-on-white (no measured tint pair existed).
- `TAvatar` uses initials, not `TImageWidget`.
- `TAddressRow` loading is a plain placeholder (swaps to `TSkeleton` at F3).
- `TButton` has 6 variants (added `tertiaryDanger`).

Files changed:
- `lib/presentation/widgets/ds/` (7 files, new), `assets/icon/ds/` (20 SVGs, new), `pubspec.yaml` (one asset line).

QA:
- Visual: NOT RUN (nothing imports the barrel until C1)
- Functional: NOT RUN — components presentational by design; `TTextField` owns no validation
- Analyze: PASS · Tests: NOT RUN · GetX/state: PASS (no GetX in this layer)

### F3 — Sheets, dialogs, toast, banner, state views

Status: QA

Implemented:
- New: `t_dialog.dart` (`TDialog`, `TAutoDismissBar`), `t_overlays.dart` (`showTSheet`/`TSheet`, `showTToast`, `TBanner`), `t_states.dart` (`TSkeleton`, `TEmptyState`, `TErrorState`).
- Re-skinned **in place, signatures unchanged**: `yesno_dialog_widget.dart`, `error_dialog_widget.dart`, `process_book_dialog_widget.dart`, `cancel_book_dialog_widget.dart`, `simmer_widget.dart`.

Behaviour preserved (the whole risk of the task):
- `showErrorCustomDialog(…, comfirmBook: true)` still pops **twice** (`DD-33`, B1; fix is out of scope).
- `showCancelBookingDialog` still has the 10 s timer inside the builder; `TAutoDismissBar` animates in its own `State` (the builder runs a fresh timer every run — driving it from the parent would navigate 10×).
- `showYesNoCustomDialog` / `showPocessBookingLoadingDialog` dismissal, pop and navigation semantics unchanged.

Files changed:
- New: `lib/presentation/widgets/ds/{t_dialog,t_overlays,t_states}.dart`, `test/presentation/widgets/ds/ds_overlays_test.dart`.
- Modified: `ds.dart`, the five re-skinned widgets.

QA:
- Visual: NOT RUN · Functional: NOT RUN (dialog navigation must be device-checked vs baseline) · Analyze: PASS
- Tests: NOT RUN. `show…Dialog` functions (use `.tr()` + `Get`) are not unit-covered — weakest link; fix when the test env works.
- `showTToast`/`showTSheet` have no call sites yet (by design, `DD-27`). `xShowModalBottomSheet` untouched (S4 migrates registration).

### C1 — App shell

Status: QA

Implemented:
- `drawer/view.dart` — rebuilt shell: app bar (menu · wordmark/tab title · bell · online pill), drawer, body stack of tabs + offline banner + approval gate.
- New: `drawer/widgets/{online_status_pill,approval_gate,offline_banner,driver_drawer}.dart`, `widgets/language_segment.dart`; restyled `profile/widgets/profile_header_widget.dart`; 6 copy keys in both locales.

Behaviour preserved:
- Approval gate **fails closed** — `unknown` is not approved.
- Online guard blocks going-online only while unapproved; turning off always allowed (asymmetry kept).
- `fetchCurrentDriveInfo` still fires exactly once from `DrawerLogic.onInit`.
- Pill on home tab only; bell → `/notification`; `SafeArea(bottom: false)` kept; all six `DrawerTab` values render.
- **Deleted:** `home/widgets/switch_online_widget.dart`, `widgets/widget_change_laguage.dart` (both replaced; no other importers — verified).

Deviations:
- No busy state on the pill (no in-flight flag in `AppState`; themed EasyLoading remains the signal).
- Language switch no longer closes the drawer (the old sheet popped twice; inline control has nothing to pop).
- Profile header keeps the `data.vehicle!` null-assert (real crash path; changing it is a behaviour change — queue with B-items).
- No logout restored: `DD-05` remains OPEN; Logout stays hidden as today (no drawer item).

Files changed:
- New: 4 drawer widgets, `language_segment.dart`, `test/presentation/screens/drawer/shell_widgets_test.dart`.
- Modified: `drawer/view.dart`, `profile_header_widget.dart`, `assets/translations/{en,km}.json`.

QA:
- Visual: NOT RUN (first task a driver would see — device run matters most here)
- Functional: NOT RUN · Analyze: PASS · Tests: NOT RUN
- NOTE: `en.json` had one key `km.json` lacked (`MOBILE_NUMBER`) — pre-existing at HEAD; the 6 C1 keys went into both files. Khmer approval copy needs a native review.

### C2 — Home tab

Status: QA

Implemented:
- `home/view.dart` — map with floating overlays: `DriverStatusCard`, `LocationStateView` (all four `LocationLoadStatus` states), update gate.
- New: `home/widgets/{driver_status_card,location_state_view}.dart`; restyled `widgets/widge_update.dart`; `app/alert_widget.dart` resume string → "Resuming your trip…" (`DD-32`); 12 copy keys in both locales.

Behaviour preserved:
- `HomeLogic` untouched: camera follows every GPS tick (B12 stays open), version check unchanged, resume redirect + 2 s dialog still fired by `ever()` from the controller.
- All `GoogleMap` properties identical (eager gestures, traffic on, zoom, callbacks); single addition is `padding`. `openAppSettings()` remains the location-state action.

Not built (deliberate): earnings card + QR FAB (`DD-07`) — no earnings endpoint; a test asserts the card carries no money figure.

Deviations:
- `_statusCardReserve` is a constant estimate (112), not a measure — long Khmer could outgrow it; `LayoutBuilder` measurement is a refinement, not a blocker.
- Permission-denied state gained an action (was text-only).
- `WidgetUpdate` became stateless; `IN_PROCESS_BOOKING` key now unused but left in both locale files.

Files changed:
- New: 2 home widgets, `test/presentation/screens/home/home_widgets_test.dart`.
- Modified: `home/view.dart`, `widge_update.dart`, `alert_widget.dart`, both locale files.

QA:
- Visual: NOT RUN (logo clearance + card-over-map only judgeable on device) · Functional: NOT RUN
- Analyze: PASS · Tests: NOT RUN · Map itself not unit-covered (`GoogleMap` needs a platform view).

### C3 — Trip scaffold and request stage

Status: QA — **highest risk task; device verification against the socket-emit oracle has NOT happened.**

Implemented:
- New: `booking/widgets/{trip_header,trip_timeline,passenger_row,trip_action_bar}.dart`. `ride_request_bottom_pop_widget.dart` rebuilt — **same class name and constructor**, plus `isLoading`.
- `widgets/count_down_widget.dart` — `build()` only; `initState` and expiry listener untouched.
- `booking/view.dart` — surgical edits only: app bar removed, overlay helpers, `isLoading` passed to the sheet, full-screen `LoadingWidget` deleted.
- 5 copy keys, all from the prototype's dictionary (no new KM drafts).

Behaviour preserved (grep-verified after the edits):
- `_onTripAction` / `_onTripError` untouched; socket emits exactly where they were.
- `PopScope(canPop: false)` intact; `getLocation(TripStage.completing)` still the drop-off path; cancel dialog emits `driverCancelDrive` **before** `onCancel()`.
- Sheet starts collapsed at `processType == 4`; countdown expiry still `Get.offAllNamed('/home')`.

The point of the task (`DD-17`):
- Every trip action **disabled while `isLoading`**, each action shows its own spinner. Correctness requirement: Cancel emits `driverCancelDrive` before the controller guard — an enabled Cancel during in-flight Accept would have told the passenger the trip was cancelled while no REST call occurred. Widget test asserts both buttons inert while loading.

Deviations:
- No map padding on this screen (defers to `_turnRight()` / B12).
- Meter strip still floats at the top — C4 moves it into the sheet, relabels estimate (`DD-14`).
- Stage 2 no longer shows the driver's own address (early adoption of a C4 call).
- Stage titles/CTA labels still use existing keys — prototype phrasing lands in C4/P2.

Files changed:
- New: 4 booking widgets, `test/presentation/screens/booking/trip_widgets_test.dart`.
- Modified: `booking/view.dart`, the sheet, `count_down_widget.dart`, both locale files.

QA:
- Visual: NOT RUN · Functional: NOT RUN — needs the accept/decline/cancel/expiry/conflict matrix on a device vs the unrecorded G0 oracle
- Analyze: PASS (3 pre-existing findings in untouched code) · Tests: NOT RUN
- Two defects caught in own code pre-ship: a nonsense timeline-connector expression and a `typedef TIconButtonFinder = Widget` in the test (would have matched the whole tree).

---

## Follow-ups (found, deliberately not implemented)

Recorded while executing S1–P3; none is in a task's scope. Each needs an owner or a decision.

- **Distance double unit in Khmer** — trip sheet at pickup shows "3.50 ម គ.ម": `formatDistanceWithUnits` returns metres ("ម") for a unit-less number and the view appends the km key. Which unit `distandTotal` holds must be confirmed before fixing (C4 expression, carried verbatim).
- **OTP resend re-pushes the OTP route** — `onResend` calls `LoginLogic.submit`; its status worker navigates to `/otp` again on success, stacking a second OTP page. Pre-existing.
- **Server-sent messages are English** (e.g. "OTP not correct") — needs backend localization or error codes the client can map.
- **Android notification channel names** ("High Importance Notifications", "Booking"/"Urgent Booking") are English OS-settings strings.
- **Legacy `core/api_service` error constants** are English; not shown on redesigned screens today.
- **`HistoryLogic.switchTab` during an in-flight fetch** can append the previous tab's page (the paging base's `_isFetching` guard drops the new fetch). Pre-existing.
- **`PaginatedController` screens duplicate their empty/error/skeleton switch** (history, announcements) — a shared paged-list view would remove it.
- **IntelliJ run configs pass `--flavor dev`** but the Gradle file defines no flavors.
- **Pinned Flutter 3.38.9 is not installed** (`.fvmrc`), and `~/FileInstaller/flutter` has no `flutter_tester` — tests/builds currently run on fvm 3.44.1 in a mirror.
- **Unused locale keys** left by the redesign (e.g. `NEW_RIDE_REQUEST`, `CANCEL_BOOK`, `PASSENGER_LOCATION`, `DROP`, `TITLE`, `CREATED_DATE`, `METHOD`, `TOTAL_PRICE`, `IN_PROCESS_BOOKING`) — removable once nothing external reads them.
- **`state.bankSelected` / `WalletLogic.selectBank`** have no view callers since S2 removed the dead top-up UI.
- **Design review** of the P3 token changes (`text.secondary`, `warning`) and of C1–C6, which remain `[Q]` (code-complete, tests passing, not yet given the rendered UI review S1–P3 had).

---

## Blocked / Needs Fix

### G0 — Baseline artefacts

Status: BLOCKED (by environment, not by decisions)
Reason: Needs a real device or emulator. Device video of every screen/state in `05 §1–§4` and a full-trip `tlog` transcript have never been captured.
Dependency: required to verify C3–C6 and Q1/Q2; referenced by almost every "Done When".
Suggested resolution: run once on a device (or in CI with a socket-log capture) and link the artefacts here.

### All tests — environment

Status: BLOCKED
Reason: `flutter test` fails locally — SDK at `~/FileInstaller/flutter` resolves `darwin-x64` artifacts on an arm64 Mac; no `flutter_tester`. `fvm flutter test` (pinned 3.38.9) never completed.
Required action: run tests in CI or on a machine with `flutter_tester`; never claim a test passed unless actually run.

### F1 — O-1 / O-2

Status: NEEDS FIX (unverified, not failing)
Reason: Kantumruy Pro tabular figures and variable-face `w700` resolution unproven (documented fallbacks in `02 §2`).
Required action: visual check on a device; apply fallback if the face fails.

### DD-13 — Drop-off confirmation (OPEN)

Default: **no confirmation** — ship C4 without it unless Product says otherwise. Record the decision when changed.

### DD-33 — Trip error dialog semantics (OPEN)

Default: preserve the double pop (B1 stays out of scope). C5 must keep dismissal behaviour identical to baseline.

### DD-05 — Logout in drawer (OPEN)

C1 shipped with Logout hidden (current baseline). If approved later, use prototype pattern: red row at bottom + confirm dialog ("GPS will stop" — accurate, logout calls `LocationService.instance.stop()`).

---

## Decision / Change Log

- 2026-09-12 — UI redesign implementation started (F1–F3, C1–C3 code-complete; uncommitted).
- 2026-09-12 — Restructured `IMPLEMENTATION_PROGRESS.md` into the required tracker format: derived all 21 items from `docs/roadmap.md`, marked F1–C3 as QA (code complete, awaiting device verification), set C4 as next implementation task. No Flutter/Dart source modified by this change.
- 2026-09-12 — `DD-01` (light theme) and `DD-02` (action fill `#CC3700`) settled by the user. `DD-34` supersedes `DD-01` for migration order.
- 2026-09-12 — C5 (trip dialogs and errors) code-complete, marked QA. Audited `_onTripError` (all three variants localized, `comfirmBook: true`, double-pop kept) and the passenger-cancel dialog (DD-25 quirks kept); applied the one residual copy item — passenger-cancel button `YES` → `OK` (`03 §595`) plus a new `OK` locale key. Prototype copy for decline-confirm deferred to P2. Analyze PASS on touched files (ran on installed 3.44.1; pinned 3.38.9 not installed, so `fvm` hangs — noted in Blockers).
- 2026-09-12 — C6 (payment) code-complete, marked QA. Built `ReceiptCard`/`TotalBox` (`04 § B`), rebuilt `calculate_fee/view.dart` (Collect payment title, real method badge per DD-18, Total to collect in neutral hero figures per DD-04, hint, pinned success Payment done button), moved the error copy to existing `PLEASE_TRY_AGAIN*` keys and localized the dialog's "Try Again" label via a new `TRY_AGAIN` key. Added `PassengerRow.trailing` + optional phone/call params. No behaviour change (emit-after-REST order, immediate navigation preserved). Analyze clean on all touched files.
- 2026-09-14 — S1 (history + history detail) code-complete, marked QA. Rebuilt the history list (`TTabs`, skeleton/empty/error states), `HistoryCardWidget` per `04 § B` with the whole completed card as the tap target (DD-19, same `MapHistoryDetailArgs`), and the detail screen as map + `TripDetailCard` (DD-20). Deleted the now-unused `ShowDistandWidget`. Added `FAILED_TO_LOAD_DATA` (previously missing — raw key was shown), `EMPTY_COMPLETED`, `EMPTY_CANCELLED`, `TRIP_DETAILS`. No controller/binding/route touched. Analyze clean; tests written, not run.
- 2026-09-14 — S2 (wallet) code-complete, marked QA. Rebuilt the wallet tab with tinted `WalletBalanceCard`s (existing labels only, DD-21), `TChip` filters, neutral tabular `TransactionRow`s (DD-04), skeleton/error/empty states and pull-to-refresh. Removed the dead commented-out top-up UI and `_cardBank`. Logic, filters and USD/riel formatting untouched; no new copy keys. Analyze clean; tests written, not run.
- 2026-09-14 — **Test runner unblocked.** fvm's Flutter 3.44.1 has `flutter_tester`; tests and builds now run in a scratchpad mirror (see Current Status). First-ever full run: 433 passed, 6 failed. Fixed: (a) `test/helpers/localized_host.dart` — a file-backed `AssetLoader` so `.tr()` resolves inside `testWidgets` (the root-bundle loader never completes in fake async; three test files carried their own broken copy); (b) a wrong `invoice_id` fixture type in the S1 test; (c) a real F1 contrast defect — `avatarFallbackText` `#6B7588` is 3.91:1 on its `#EBEBF0` fill (`02 §1.1`'s 4.64 was measured on white); now `#60697A`, 4.65:1. Debug APK builds (no `--flavor`: the Gradle file defines none).
- 2026-09-14 — Adopted the verification standard in Current Status; G0 marked `[!]` (needs a person, a live backend and the old build).
- 2026-09-14 — S3 (announcements, detail, terms, contact) DONE. Added shared `TAppBar`; history detail moved onto it. Rendered visual review of S1–S3 found and fixed the heavy history route box, the truncated date subtitle and the wallet mid-number wrap. S1 and S2 re-verified and marked DONE. Suite: 451/451.
- 2026-09-14 — Renamed the S1/S3 empty-state keys to the names in `06 §3` (`EMPTY_COMPLETED`, `EMPTY_CANCELLED`, `EMPTY_ANNOUNCEMENTS`) so P2 works from one table.
- 2026-09-14 — S4 (splash, login, OTP, register) DONE. Validation, auto-submit and the register enable rule unchanged and now covered by view tests. Suite: 461/461; APK builds.
- 2026-09-14 — S5 (legacy token cleanup) DONE. `AppColors`, `ThemeConstands`, `AppTextStyles` and nine superseded legacy widgets deleted; route polylines on the brand token. Phase 3 complete. Suite 461/461; APK builds.
- 2026-09-14 — P1 (motion) DONE. Motion tokens, route/sheet/dialog/stage/banner/pulse motion, reduced-motion support. **Fixed a real defect:** the ride-request countdown ran at 5% of its duration under the OS reduced-motion setting and dropped requests after ~1.5 s. Suite 473/473; APK builds.
- 2026-09-14 — P2 (copy and localization) implemented and marked `[!]`: all planned keys with call sites landed, remaining hardcoded English moved to keys, locale parity + key-existence + hardcoded-copy guard tests added, meter overflow at KM 1.3× fixed. Waiting on a native Khmer reviewer (`docs/l10n-km-review.md`). Suite 477/477; APK builds.
- 2026-09-14 — P3 (accessibility) DONE. Guideline suite over 14 surfaces found and fixed: `text.secondary` and `warning` contrast (token values changed, design review requested), 22 px text-field tap targets, the unlabelled 24 px trip-sheet grabber, and a drawer overflow at text scale 1.3. Suite 521/521; APK builds.
- 2026-09-14 — **Paused after Phase 4 at the user's request.** Remaining: Q1–Q3 (need a device), P2 (Khmer review), G0 (baseline recording), re-review of C1–C6.
