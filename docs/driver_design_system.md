# Pu Taxi Driver — UI Design System

**Scope:** `pu_taxi_system/pu_driver` (Flutter, SDK `>=3.4.3 <4.0.0`, Material 3).
**Method:** extracted from source only. Every value below is traceable to a file; uncertain items are marked *Needs verification*.
**Revision basis:** UX-redesign tokens (F1/F2/F3, C1–C3, P1) are the implemented system; legacy `AppColors`/`ThemeConstands`/`SizeConfig`/ScreenUtil are **absent** from `lib/` (verified: only surviving mentions are in doc comments at `lib/core/theme/app_theme.dart:7` and `lib/core/theme/tokens.dart:14`).

---

## 1. Overall design language

- **Light-only Material 3 theme.** A single `ThemeData` is built by `AppTheme.light({required bool khmer})` and installed once at `GetMaterialApp.theme` (`lib/app/root_main.dart:68`). No dark theme is built; `TaarraaTokens.lerp` deliberately snaps rather than interpolates (`lib/core/theme/tokens.dart:536`). Confirmed by design decision `DD-01`.
- **Semantic tokens, not primitives.** All colour/type flows through a `ThemeExtension<TaarraaTokens>` (`lib/core/theme/tokens.dart:518`), read as `context.colors` / `context.texts` (`tokens.dart:544`). Widgets are specified never to reference raw hex or `Colors.*` (`docs/ux-redesign/02-design-system.md:21`).
- **Brand split (the core rule).** `#FF4500` (`brandIdentity`, 3.44:1 on white) is **graphics only** — logo, route line, markers, countdown arc. Anything with a white label uses `#CC3700` (`actionPrimary`, `brandText`), which clears AA (5.10:1). This is `DD-02`.
- **Separation by border, shadow only for floating layers.** On a light map, shadow-heavy UI "turns to mud" — `Elevations.flat` is empty and only `float`/`sheet`/`modal` cast shadows (`tokens.dart:110-140`).
- **Khmer-aware typography.** Every text style carries two line-height sets; the theme is rebuilt with `TaarraaTextStyles.khmer` when `locale.languageCode == 'km'` (`root_main.dart:68`, `tokens.dart:501`).
- **Accessibility-first sizing.** Minimum 48 px touch target everywhere (`Sizes.touchTarget`); primary CTA 56 px; text scale clamped 1.0–1.3 (`root_main.dart:48-50`); reduced-motion honoured through `reduceMotion(context)` (`ds/t_motion.dart:51`).
- **Bangladesh-free:** the app has no `ScreenUtil` dependency and no `.w/.h/.sp/.r` scaling (verified: zero matches in `lib/`). Responsiveness is `MediaQuery` + `LayoutBuilder` + 4 px-grid tokens.

---

## 2. Colour palette

**Source of truth:** `TaarraaColors.light` in `lib/core/theme/tokens.dart:319-365`.
**Application:** mapped into `ColorScheme.light` and `ThemeData` in `lib/core/theme/app_theme.dart:24-128`, then read as `context.colors.<name>`.

### 2.1 Semantic tokens

| Semantic name (`TaarraaColors`) | HEX | Alpha | Role |
|---|---|---|---|
| `bgPage` | `#F7F7F9` | FF | Scaffold behind cards/lists |
| `bgSurface` | `#FFFFFF` | FF | Cards, sheets, dialogs, inputs, app bar |
| `bgRaised` | `#EBEBF0` | FF | Segmented/tab tracks, chip rests, icon-button chip |
| `bgSunken` | `#E2E2E5` | FF | Disabled fills, skeleton base |
| `bgFloating` | `#FFFFFF` | FF | Cards floating over the map (opaque) |
| `scrim` | `#3A3A3C` | 7A (~48%) | Barrier behind sheets/dialogs/drawer |
| `blockingOverlay` | `#FFFFFF` | F7 (~97%) | Full blocking overlays (approval gate) |
| `borderDivider` | `#E2E2E5` | FF | Dividers, card hairlines, grabber |
| `borderControl` | `#8F90A6` | FF | Input/chip/icon/ghost outlines (3.13:1) |
| `borderFocus` | `#CC3700` | FF | Focused input / cursor |
| `textPrimary` | `#3A3A3C` | FF | Body text, all money (11.35:1) |
| `textSecondary` | `#5C6474` | FF | Sub-lines, metadata, placeholders |
| `textDisabled` | `#6B7588` | FF | Inert control labels only |
| `textOnAction` | `#FFFFFF` | FF | Labels on `actionPrimary` / `success` |
| `brandIdentity` | `#FF4500` | FF | **Graphics only** — logo, route, markers |
| `brandText` | `#CC3700` | FF | Brand text & links (5.10:1) |
| `brandTint` | `#FFF1EC` | FF | Selected row/chip background |
| `actionPrimary` | `#CC3700` | FF | Primary button fill |
| `actionHighlight` | `#D93B00` | FF | Top stop of primary gradient |
| `actionPressed` | `#A82D00` | FF | Pressed primary fill |
| `success` | `#1C784D` | FF | Success text/icons/fills (5.46:1) |
| `successGraphic` | `#10CF7C` | FF | Dots, marker accents, bars (not text) |
| `successTint` | `#E6F7EF` | FF | Online pill, on-trip strip, done step |
| `warning` | `#86650A` | FF | Warning text/icons (5.41:1) |
| `warningGraphic` | `#FFB020` | FF | Countdown arc ≤10 s, warning dots |
| `warningTint` | `#FFF6E5` | FF | Offline banner, pending approval |
| `danger` | `#D32F2F` | FF | Error text, destructive outline (4.98:1) |
| `info` | `#1976D2` | FF | Informational text/icons (4.60:1) |
| `stageRequestTint` / `stageRequestText` | `#FFF1E8` / `#A33A00` | FF | "New request" stage pill (6.01:1) |
| `stagePickupTint` / `stagePickupText` | `#E8F1FD` / `#1A579E` | FF | En-route / at-pickup stage (6.35:1) |
| `stageOnTripTint` / `stageOnTripText` | `#E6F7EF` / `#1C784D` | FF | On-trip pill & meter strip (4.92:1) |
| `toastBackground` / `toastText` | `#3A3A3C` / `#FFFFFF` | FF | Dark toast on light UI (11.35:1) |
| `avatarFallbackBackground` / `avatarFallbackText` | `#EBEBF0` / `#5C6474` | FF | Initials when no photo (5.01:1) |

### 2.2 `ColorScheme` mapping (`app_theme.dart:24-38`)

| ColorScheme role | Token |
|---|---|
| `primary` | `actionPrimary` (`#CC3700`) |
| `onPrimary` | `textOnAction` |
| `secondary` | `brandIdentity` (`#FF4500`) |
| `onSecondary` | `textOnAction` |
| `surface` | `bgSurface` |
| `onSurface` | `textPrimary` |
| `error` / `onError` | `danger` / `textOnAction` |
| `outline` / `outlineVariant` | `borderControl` / `borderDivider` |

Legacy `primaryColor` is set to `brandIdentity` for Material fallbacks only; `primaryColorDark`→`actionPressed`, `primaryColorLight`→`brandTint`, `hintColor`→`textSecondary` (`app_theme.dart:54-57`). `scaffoldBackgroundColor`=`bgPage`, `canvasColor`=`bgSurface`, `dividerColor`=`borderDivider` (`app_theme.dart:45-47`).

### 2.3 Gradients, opacity, status semantics

- **Primary button gradient** — `LinearGradient(topCenter→bottomCenter, [actionHighlight, actionPrimary])`; replaced by solid `actionPressed` while pressed (`ds/t_button.dart:199-206`).
- **Transparency** comes from `withValues(alpha:)`: icon halos at `0.12` (`ds/t_dialog.dart:74`, `approval_gate.dart:227`), trip-header border at `content.withValues(alpha: 0.35)` (`trip_header.dart:49`).
- **Raw alpha scrims (not tokens):** `Color(0x2E000000)` (countdown darken) and `Color(0x33FFFFFF)` (hold-to-confirm fill) in `booking/widgets/trip_action_bar.dart:179,328`.
- **Status = colour + icon + word** (`02-design-system.md:111`); `TBadge` never relies on colour alone (`ds/t_surfaces.dart:102`). Destructive actions are **outlined**, never filled red (`t_button.dart:24-31`).

### 2.4 Hardcoded colours outside the token table

| Location | Value | Notes |
|---|---|---|
| `lib/core/utils/load_custom_marker.dart:85-88` | `#FF4500`, `#3A3A3C`, `#FFFFFF`, `0x33000000` | Code-drawn pickup/destination pins (legacy hardcode, not tokens) |
| `lib/presentation/widgets/ds/../booking/.../trip_action_bar.dart:179,328` | `0x2E000000`, `0x33FFFFFF` | Overlay scrims over buttons |
| `lib/presentation/screens/invite/widgets/invite_widgets.dart:117,127,132,136,142` | `Colors.white`, `Colors.black` | QR tile must stay pure black/white |
| `lib/presentation/screens/invite/scan_view.dart:121` | `Colors.white` | Scanner frame |
| `lib/mock/mock_dev_panel.dart:24,41` | `0xE6D32F2F`, `Colors.white` | QA-only overlay |
| `lib/presentation/screens/booking/view.dart:560,778`, `history_detail/logic.dart:88` | `TaarraaColors.light.brandIdentity` | Reads the raw light theme instead of `context.colors` (map polyline) |

---

## 3. Typography

**Family:** `KantumruyPro` (variable `wght` font). Registered in `pubspec.yaml` alongside two static per-face families, `KantumruyPro-SemiBold` and `KantumruyPro-Regular`, which are **not referenced by any style** — all styles pin the `wght` axis explicitly via `FontVariation` (`tokens.dart:437-454`).
**Weights:** `FontWeights.regular = w400`, `semiBold = w600`, `bold = w700` (`tokens.dart:28-34`); the prototype's 800 maps to 700 (axis tops out at 700).
**Scale source:** `TaarraaTextStyles._build` (`tokens.dart:456-513`), applied to `ThemeData.textTheme` in `app_theme.dart:63-78`.

| Token | Size / weight | Height (Latin / Khmer) | Tabular | Usage |
|---|---|---|---|---|
| `display` | 30 / w700 | 1.25 / 1.5 | yes | Amount to collect |
| `headline` | 24 / w700 | 1.3 / 1.55 | — | Screen titles, blocking-state titles |
| `numericLg` | 22 / w700 | 1.2 / 1.2 | yes | Countdown seconds |
| `title` | 18 / w700 | 1.35 / 1.7 | — | Dialog titles, focused address, OTP digits |
| `subtitle` | 17 / w700 | 1.35 / 1.7 | — | App-bar & section titles |
| `bodyStrong` | 16 / w700 | 1.4 / 1.75 | — | Button labels, names, addresses |
| `body` | 15 / w400 | 1.45 / 1.8 | — | Body copy, input text |
| `bodySecondary` | 14 / w400 | 1.55 / 1.8 | — | Dialog & news body |
| `label` | 13 / w700 | 1.35 / 1.7 | — | Field labels, chips, tabs |
| `caption` | 12 / w400 | 1.35 / 1.7 | — | Metadata, timestamps |
| `micro` | 12 / w700 | 1.3 / 1.6 | — | Badges, pills, timeline labels, overlines |

**Rules**
- Minimum 12 px. **No uppercase transforms** — Khmer has no case, so `micro` is never uppercased (`tokens.dart:433`).
- Money, timers, distances and codes use tabular figures (`FontFeature.tabularFigures()`), e.g. `display`, `numericLg` (`tokens.dart:470-481`) and manually in `trip_action_bar.dart:206-208`.
- Letter-spacing is Latin-only; the wordmark applies `letterSpacing: 1.5` (title) / `1` (role) only when not Khmer (`drawer/view.dart:161-179`).
- Re-weighting a variable-font style must use the `withWeight()` extension, which sets both `fontWeight` and `fontVariations` (`tokens.dart:373-380`).
- **Hardcoded font sizes that bypass the scale** (see §7): `otp/view.dart:175` (26), `term_condition/view.dart:67,80` (13, 14), `announcement/widgets/news_card.dart:48,59` (15, 13), `announcement_detail/view.dart:107,122` (17, 14), `contact_us/view.dart:362` (15), `wallet/widgets/wallet_widgets.dart:231,252` (14), `invite/widgets/invite_widgets.dart:301,450,675,751,772,826,846` (14/15), `booking/widgets/show_distand_and_price_widget.dart:33` (numericLg→19).

---

## 4. Spacing, radius, elevation, icons, motion

### 4.1 Spacing — 4 px grid (`Insets`, `tokens.dart:37-59`)

| Token | Value | Token | Value |
|---|---|---|---|
| `s4` | 4 | `s24` | 24 |
| `s8` | 8 | `s32` | 32 |
| `s12` | 12 | `screen` | 20 (full-screen horizontal) |
| `s16` | 16 | `tabContent` | 16 (tab content horizontal) |
| `s20` | 20 | `betweenTargets` | 8 (min gap between tap targets) |
| | | `betweenAcceptAndCancel` | 16 |

### 4.2 Radii (`Radii`, `tokens.dart:62-88`)

| Token | Value | Usage |
|---|---|---|
| `sm` | 8 | Small inner elements, skeletons |
| `md` | 12 | Icon buttons, drawer rows |
| `control` | 14 | Buttons, fields, OTP boxes, list tiles, trip card, passenger row |
| `lg` | 16 | Cards, wallet cards, receipt |
| `xl` | 20 | Dialogs |
| `sheet` | 22 (top corners) | Bottom sheets |
| `full` | 999 | Pills, badges, avatars, chips, grabber |

Pre-built `BorderRadius` constants: `controlRadius`, `cardRadius` (=lg), `dialogRadius` (=xl), `sheetRadius` (top-only).

### 4.3 Sizes (`Sizes`, `tokens.dart:91-103`)

| Token | Value | Usage |
|---|---|---|
| `touchTarget` | 48 | Hard floor for anything tappable |
| `primaryButton` | 56 | Primary CTA |
| `input` | 56 | Text field height |
| `listRow` | 64 | List row |

### 4.4 Elevation (`Elevations`, `tokens.dart:110-140`)

Shadow colour is neutral `#3A3A3C`, never black (`_shadow`, `tokens.dart:113`).

| Token | Value | Usage |
|---|---|---|
| `flat` | none (border only) | Cards on `bgPage` |
| `float` | `#3A3A3C` @12%, blur 8, offset (0,2) | Map cards, countdown pill, toast |
| `sheet` | `#3A3A3C` @10%, blur 16, offset (0,−2) | Bottom sheets |
| `modal` | `#3A3A3C` @16%, blur 32, offset (0,8) | Dialogs |
| `selected` | `#3A3A3C` @8%, blur 2, offset (0,1) | Selected segment/tab thumb |

### 4.5 Icons

- **Set:** 26 SVGs in `assets/icon/ds/`, exposed as `DsIcons` constants (`ds/ds_icons.dart:14-56`).
- **Style:** 24 viewBox, stroke 2, round caps/joins; authored with `stroke="currentColor"` and tinted at render via `ColorFilter.mode(color ?? context.colors.textSecondary, srcIn)` (`ds_icons.dart:91-99`). No emoji as icons.
- **Glyph sizes:** `TIconSize.sm=16`, `md=22`, `lg=28` (`ds_icons.dart:60-68`).
- **Tap target:** always `Sizes.touchTarget` (48); the visible glyph is smaller (`ds/t_button.dart:228-231`).
- **Icon colour conventions:** default `textSecondary`; active/selected `brandText`; on filled button white; success actions `success`; destructive `danger`.
- **Fallback:** Material `Icons.*_rounded` where no DS glyph exists.
- **Legacy asset constants** (`lib/core/resources/asset_resource.dart`) still exist for nav/upload/flag/no-image assets; the DS icon namespace is separate.

### 4.6 Motion (`Motion`, `t_motion.dart:12-48`)

| Transition | Duration / curve |
|---|---|
| Screen enter (Android) | 250 ms fade + 10 px rise (iOS: platform slide) — `routes/transitions.dart` |
| Bottom sheet | 300 ms `Cubic(0.2, 0.9, 0.3, 1)` |
| Dialog | 250 ms scale 0.9 → 1 |
| Stage content cross-fade | 150 ms |
| Timeline step | 200 ms |
| Banner slide | 200 ms |
| Button press | 100 ms scale 0.97 |
| Selection colour change | 150 ms |
| Online / stage pulse | 1400 ms / 1200 ms opacity 1↔0.4 |
| Error shake | 400 ms |

Under `MediaQuery.disableAnimations`: no pulse, slide, scale or shake — opacity only (`t_motion.dart:51`). Countdowns/auto-dismiss/hold-to-confirm use `AnimationBehavior.preserve` so they still take real time (`count_down_widget.dart:67`, `t_dialog.dart:155`, `trip_action_bar.dart:248`). Money values never animate.

---

## 5. Reusable component inventory

All components live in `lib/presentation/widgets/ds/` and are re-exported from `ds/ds.dart`. They are **presentational only** — no controllers, no navigation.

### 5.1 Buttons — `ds/t_button.dart`

| Widget | Variants / sizes | Styling rules |
|---|---|---|
| `TButton` | variants `primary`, `success`, `secondary`, `destructiveOutline`, `tertiary`, `tertiaryDanger`; sizes `regular` (56), `small` (48) | Radius `control` (14); label `bodyStrong` (small → 14); primary = gradient `actionHighlight→actionPrimary`, pressed = `actionPressed`; disabled = `bgSunken` fill + `textDisabled`; outlined variants use 1.5 px border; press scale 0.97; optional leading `TIcon`; `loading` swaps to a 20×20 spinner **without resizing** |
| `TIconButton` | tones `neutral`, `success`; `filled` chip or bare glyph; `showDot` | 48×48 target, 22 px glyph, radius `md` (12), fill `bgRaised`, border `borderControl`/`success`, unread dot 9 px `brandIdentity` with 2 px `bgSurface` ring |

### 5.2 Inputs — `ds/t_text_field.dart`

`TTextField` (+ `TTextField.phone` → `+855` prefix). 56 px tall (`Sizes.input`), radius `control`, 1.5 px border `borderControl`/`danger`, fill `bgSurface`/`bgSunken`. Label above in `label`+semiBold (`textSecondary`); hint `body` (`textSecondary`); error row with `warn` icon in `danger`; optional `ShakeWidget` (offset 10) on validation failure. Owns **no validation** — formatters/errors come from the caller. Phone variant uses `title`+semiBold at 18 px.

### 5.3 Surfaces & badges — `ds/t_surfaces.dart`

| Widget | Rules |
|---|---|
| `TCard` | variants `flat`/`raised`/`tinted`; radius `lg` (16); default padding `all(16)`; 1 px border; `floating` adds `Elevations.float`; optional `onTap` wraps in `InkWell` |
| `TBadge` | tones `success`, `warning`, `brand`, `danger`, `info`, `neutral`; `micro` label; padding 11×5; radius `full`; optional leading icon; tint tones fill, outline tones (danger/info/neutral) are border-on-white |

### 5.4 Content primitives — `ds/t_content.dart`

| Widget | Rules |
|---|---|
| `TAvatar` | circular, initials fallback (first two words), `bodyStrong` at `size*0.35`, fill `avatarFallbackBackground`; default 48, dense 32, drawer 54 |
| `TKeyValueRow` | label `bodySecondary`(`textSecondary`) left, value `bodyStrong` 14 right; em dash when unknown; 8 px vertical |
| `TAddressRow` | pickup dot `brandIdentity` + `brandTint` halo / destination `textSecondary` + `bgRaised`; overline `micro`; primary `bodyStrong` (or `title` when focused); secondary `caption` |
| `TAmount` | `row` (`bodyStrong`) / `hero` (`display`); formats nothing (takes a pre-formatted string); prefixes `≈` when `isEstimate`; money wraps, never ellipsises |

### 5.5 Selection — `ds/t_selection.dart`

`TSegmented` (hug-width, equal-width segments, track `bgRaised`+border, 4 px inset), `TTabs` (equal segments with a sliding white thumb + `Elevations.selected`), `TChip` (pill, selected `brandTint`+`brandText`, rest `bgSurface`+`borderControl`). All use min-height 48 and `Motion.colorChange`.

### 5.6 States — `ds/t_states.dart`

`TSkeleton` (`.line`/`.box`, shimmer `bgSunken`→`bgRaised`), `TEmptyState` (secondary icon, `subtitle` title, optional secondary button), `TErrorState` (warn icon in `danger`, retry action).

### 5.7 Overlays — `ds/t_overlays.dart`

`showTSheet`/`TSheet` (top radius 22, grabber 44×5 `borderDivider`, padding 12/20/26, 84% max height, `elev.sheet`, scrim, 300 ms), `showTToast` (floating `toastBackground` pill, radius `control`, margin 20, 2.4 s, `elevation:0`), `TBanner` (tones warning/danger/info; warning = `warningTint` fill + `warning` content, padding 16×10, `micro`).

### 5.8 Dialog — `ds/t_dialog.dart`

`TDialog` (radius `xl`, padding 22, `elev.modal`, 250 ms `TScaleIn`; 64 px tinted icon halo at 12%; equal-width action row with 10 px gap) + `TAutoDismissBar` (6 px draining bar in `brandIdentity`). Renders only; dismissal/navigation stay in the `show…Dialog` wrappers.

### 5.9 App bar — `ds/t_app_bar.dart`

`TAppBar` for pushed screens: 64 px toolbar + 1 px `borderDivider`, `bgSurface`, back `TIconButton`, `subtitle` title. The shell builds its own bar inline (see §6).

### 5.10 Motion primitives — `ds/t_motion.dart`

`TPulseDot` (opacity pulse), `TScaleIn` (dialog entrance), `TCrossFade` (stage change with `IgnorePointer` on outgoing child), `reduceMotion(context)`.

### 5.11 Non-DS reusable widgets — `lib/presentation/widgets/*.dart`

| File | Widget | Purpose |
|---|---|---|
| `count_down_widget.dart` | `SmoothCircularCountdown` | Request decision timer (ring pill, or `builder` for in-button) |
| `error_dialog_widget.dart` | `showErrorCustomDialog()` | Error dialog via `TDialog` |
| `yesno_dialog_widget.dart` | `showYesNoCustomDialog()` | Confirm dialog (safe=primary, risky=destructiveOutline) |
| `cancel_book_dialog_widget.dart` | `showCancelBookingDialog()` | Auto-dismiss (10 s) passenger-cancelled dialog |
| `process_book_dialog_widget.dart` | `showPocessBookingLoadingDialog()` | Resuming-trip spinner dialog |
| `x_dropdown_search.dart` | `SearchableDropdown<T>`/`DropdownSelection<T>` | Searchable `DropdownButton2` |
| `simmer_widget.dart` | `ShimmerProfile` | Drawer-profile skeleton |
| `shake_widget.dart` | `ShakeWidget`/`ShakeWidgetState` | Validation shake |
| `widge_update.dart` | `WidgetUpdate` | Blocking force-update card |
| `language_segment.dart` | `LanguageSegment` | EN/ខ្មែរ `TSegmented` switcher |
| `custom_animated_loading.dart` | `CustomAnimation` | EasyLoading indicator animation |

---

## 6. Driver-specific UI patterns

### 6.1 Shell — `lib/presentation/screens/drawer/view.dart`

`DrawerScreen`: 6-tab shell (`home`, `history`, `wallet`, `termCondition`, `contactUs`, `announcement`). Custom `AppBar` (64 px, `bgSurface`, 1 px bottom divider): menu `TIconButton` · wordmark (`APP_NAME` `subtitle` with `letterSpacing 1.5` + `DRIVER_ROLE` `micro` in `brandText`, Latin only) or tab title · bell `TIconButton` · `OnlineStatusPill` (home tab only). Body is a `Stack`: tab content (`SafeArea bottom:false`) → `OfflineBanner` (top) → `ApprovalGate` (covers body only, app bar stays reachable).

### 6.2 Online / offline status

| Component | File | Pattern |
|---|---|---|
| `OnlineStatusPill` / `OnlineStatusPillView` | `drawer/widgets/online_status_pill.dart` | 40 px pill, `full` radius, 48 target. **On:** `successTint` fill, `success` border/label, `successGraphic` dot pulsing at 1.4 s. **Off:** `bgRaised`, `borderControl`, `textSecondary`, static dot. Toggle logic in `AppLogic`; blocked drivers get a reason toast (`DD-52`). |
| `OfflineBanner` | `drawer/widgets/offline_banner.dart` | Renders nothing when connected; `TBanner` warning ("reconnecting"), slides 200 ms. Amber not red (`DD-26`). |
| `DriverStatusCard` / `…View` | `home/widgets/driver_status_card.dart` | Floating `TCard` over the map stating online/offline (or approval-check state). `subtitle` title + `caption` line + `TBadge` online/offline; busy → 3 px `brandIdentity` progress bar; failed check → `secondary` retry `TButton`. **No earnings** (`DD-07`). |

### 6.3 Approval gate — `drawer/widgets/approval_gate.dart`

`ApprovalGate`/`ApprovalGateView`: full-page (below app bar) blocked state. 72 px tinted halo icon (`warning` clock / `danger` close), `title`, `bodySecondary` message, optional `TCard` step list (done = `success` check, current = `warning` clock, upcoming = `borderControl` ring), pinned `TButton` support + `tertiary` "check again" (loading). Copy says which of the three states it is (`DD-52`).

### 6.4 Drawer — `drawer/widgets/driver_drawer.dart`

`DriverDrawer`: `bgSurface`; `ProfileHeaderWidget` header; `_DrawerRow` list (48+ min height, `md` radius, 22 px icon, selected = `brandTint` + `brandText` + bold); divider + language `Wrap` with `LanguageSegment`. Five destinations only (no referral/sound/logout — `DD-05/06/22`).

### 6.5 Home map — `home/view.dart`

`GoogleMap` (`normal`, traffic on, compass/my-location on, `EagerGestureRecognizer`) with a bottom overlay column: optional `InviteFab` (QR invite, `DD-45`) above `DriverStatusCard`, both inside `SafeArea bottom:false`, 16 px insets. `GoogleMap.padding.bottom` reserves the card height — base 112 px, +`s12+touchTarget` when check failed, +`InviteFab.size+s12` when invite is on — so Google's logo and controls stay visible (Maps terms). Location states use `LocationStateView` (searching/denied/failed) as a full-screen fallback. Force-update overlays `c.scrim` with `WidgetUpdate`.

### 6.6 Trip flow — `lib/presentation/screens/booking/`

`view.dart` is a full-bleed `GoogleMap` (no app bar) under a `Stack`:
- **Stage header overlay** (`TripHeader`) when not compact: tinted pill/radius-`control` banner with 9 px pulsing dot, `bodyStrong` title, `caption` `#code`, `Elevations.float` (`DD-10`).
- **Bottom sheet** (`ModelBottomSheetNewRequestWidget`, `widgets/ride_request_bottom_pop_widget.dart`): persistent (not modal), max **74%** height, `elev.sheet`, grabber 44×5. Contains `TripTimeline`/`TripProgressBar`, stage summaries, `_EtaHero`, `TAddressRow`s, `PassengerRow`, and a **pinned** `TripActionBar` that never scrolls (`DD-10`).
- **Action bar** (`trip_action_bar.dart`): one primary action per stage; Start ride uses `success` (`DD-12`); Accept carries the decision timer as a darkening fill (`0x2E000000`) + seconds pill (`DD-35`); Drop off is hold-to-confirm (1000 ms, `0x33FFFFFF` fill, haptic) (`DD-38`); Cancel is a `tertiaryDanger` text action **below** Accept with a 16 px gap (`DD-11`); both disabled while loading.
- **Timeline** (`trip_timeline.dart`): `TripTimeline` (26 px numbered circles, done=`successTint`+check, current=`actionPrimary` white number, 2 px connector) and `TripProgressBar` (4×3 px segments, done=`success`, current=stage colour, fractional fill `DD-38`).
- **Meter strip** (`show_distand_and_price_widget.dart`): `TripMeterStrip` on `stageOnTripTint` — Duration / Distance / Est. Fare (≈) cells split by 1 px rules + `info` estimate note.
- **Countdown** (`count_down_widget.dart`): floating white pill, 40 px ring stroke 4, arc `brandIdentity` → `warningGraphic` ≤10 s, `numericLg` seconds, `caption` caption.
- **Route:** polyline `brandIdentity`, width 5 (via raw `TaarraaColors.light`, `view.dart:560,778`). **Markers:** driver = top-down vehicle PNG by `typeVehicleId` (`load_custom_marker.dart:27-56`, `DD-60`): one 3:5 family in `brandIdentity` with dark glass, a white ring and a soft `#3A3A3C` shadow (Alphard VIP is the one dark body); sources in `docs/markers/`. Pickup/destination = code-drawn pins (`#FF4500`/`#3A3A3C`).

### 6.7 Payment / receipt — `calculate_fee/widgets/receipt_card.dart`

`PaymentHeader` (trip-complete + `TripProgressBar`), `PaymentHero` (method label, `TAmount.hero`, ride-credit band, 3 fact tiles), `RideCreditNote` (green band), `PaymentRoute` (`TAddressRow` + `PassengerRow` with payment-method badge). Uses `TButton`, `TCard`, `TIcon`, `TBadge`, `TAmount`, dotted-line separators.

### 6.8 Wallet / history / invite

- **Wallet** (`wallet/`): `TCard` balance, tinted warning debt card, `TChip` type filters, `TEmptyState`/`TErrorState`/`TSkeleton`, `TransactionRow`.
- **History** (`history/`): `TTabs` (Completed/Cancelled) with `PageView`, `HistoryCardWidget` (route line markers 10 px, success/fare rows), skeletons.
- **Invite/rewards** (`invite/`): `InviteFab` (round QR FAB), `InviteQrCard` (`qr_flutter`, pure black/white), `RewardBalanceCard`, `RewardSplitCard`, `RewardTile`, scan view (`mobile_scanner`, white frame).

---

## 7. Inconsistencies, duplication, hardcoded values

**Token aliasing (same value, different names)** — intentional semantics but easy to misuse:
- `bgSurface` = `bgFloating` = `toastText`/`textOnAction` = `#FFFFFF`.
- `bgSunken` = `borderDivider` = `#E2E2E5`.
- `brandText` = `actionPrimary` = `borderFocus` = `#CC3700`.
- `avatarFallbackBackground` = `bgRaised` = `#EBEBF0`; `avatarFallbackText` = `textSecondary` = `#5C6474`.

**Raw theme access instead of `context.colors`** (bypasses the ThemeExtension and any future theming):
- `booking/view.dart:560,778` and `history_detail/logic.dart:88` use `TaarraaColors.light.brandIdentity`.

**Hardcoded `fontSize` overrides** that bypass the type scale / text scaler (see §3 list): OTP, term condition, news card, announcement detail, contact us, wallet, invite, trip meter.

**Raw colour literals outside tokens:** `load_custom_marker.dart:85-88`, `trip_action_bar.dart:179,328`, invite QR/scan white/black, `mock_dev_panel.dart`.

**Raw spinners** (`CircularProgressIndicator`) instead of a DS loading primitive in `history/view.dart:228`, `announcement/view.dart:122`, `otp/view.dart:88`, `invite/widgets/invite_code_field.dart:100` (the DS only standardises the in-button spinner and skeleton).

**Duplicated shapes:** sheet grabber 44×5 defined both in `ds/t_overlays.dart:69` and `ride_request_bottom_pop_widget.dart:387`; profile/empty/error/announcement skeletons repeated; `_EstimateNote` in `ride_request_bottom_pop_widget.dart` duplicates the `EST_NOTE` line in `TripMeterStrip`.

**Unused/mismatched assets:** `assets/marker/destination_icon.png` and `taxi_marker.svg` are bundled but unreferenced. `KantumruyPro-SemiBold` / `KantumruyPro-Regular` families are registered but no style selects them.

**No dark theme.** Only `TaarraaColors.light` exists; `blockingOverlay` and `stage*` tokens are defined but `blockingOverlay` is not consumed by `ApprovalGate` (which uses `bgPage`).

**Not found / needs verification:**
- Earnings / "today" summary card — explicitly not built (`DD-07`, `driver_status_card.dart:11-15`): no earnings endpoint exists.
- `ScreenUtil` / responsive scaling — **not found**; responsive behaviour is manual (`MediaQuery`, `LayoutBuilder`, breakpoint `maxWidth < 340` in `register/view.dart:181`).
- Full-screen dedicated loading screen for trips — removed (`view.dart:1288-1292`); loading is now inside components.
- Whether Kantumruy Pro ships tabular figures (design open item O-1) — *Needs verification* on device.

---

## 8. Architecture & source map

### 8.1 Theme architecture

```
lib/core/theme/tokens.dart        TaarraaColors.light, TaarraaTextStyles.latin/.khmer,
                                  Insets, Radii, Sizes, Elevations, FontWeights,
                                  TaarraaTokens (ThemeExtension)
        │  context.colors / context.texts / context.tokens  (tokens.dart:544-551)
        ▼
lib/core/theme/app_theme.dart     AppTheme.light({khmer}) → ColorScheme + ThemeData
                                  + TaarraaTokens extension
        │
        ▼
lib/app/root_main.dart:68         GetMaterialApp.theme  (rebuilt on locale change)
lib/main.dart:69-85               configLoading() uses TaarraaColors.light for EasyLoading
```

Widgets consume styles only through the `BuildContext` extensions; screen-level overrides use `.copyWith(...)` on a token style.

### 8.2 Design-decision → file map

| Decision | Implementation file(s) |
|---|---|
| Semantic colours | `lib/core/theme/tokens.dart:319-365` |
| Type scale | `lib/core/theme/tokens.dart:456-513` |
| Spacing / radii / sizes / elevation | `lib/core/theme/tokens.dart:37-140` |
| Material theme + component themes | `lib/core/theme/app_theme.dart:40-128` |
| Context accessors | `lib/core/theme/tokens.dart:544-551` |
| Design-system components | `lib/presentation/widgets/ds/*.dart` (barrel: `ds/ds.dart`) |
| Icon set + sizing | `lib/presentation/widgets/ds/ds_icons.dart`; assets `assets/icon/ds/*.svg` |
| Motion spec | `lib/presentation/widgets/ds/t_motion.dart`; route transition `lib/routes/transitions.dart` |
| Buttons | `ds/t_button.dart` (`TButton`, `TIconButton`) |
| Inputs | `ds/t_text_field.dart` (`TTextField`, `.phone`) |
| Surfaces/badges | `ds/t_surfaces.dart` (`TCard`, `TBadge`) |
| Content primitives | `ds/t_content.dart` (`TAvatar`, `TKeyValueRow`, `TAddressRow`, `TAmount`) |
| Selection | `ds/t_selection.dart` (`TSegmented`, `TTabs`, `TChip`) |
| States | `ds/t_states.dart` (`TSkeleton`, `TEmptyState`, `TErrorState`) |
| Overlays | `ds/t_overlays.dart` (`showTSheet`, `TSheet`, `showTToast`, `TBanner`) |
| Dialog | `ds/t_dialog.dart` (`TDialog`, `TAutoDismissBar`) |
| App bar | `ds/t_app_bar.dart` (`TAppBar`) |
| Shell / navigation | `screens/drawer/view.dart`, `screens/drawer/widgets/driver_drawer.dart` |
| Online/offline/approval | `screens/drawer/widgets/{online_status_pill,offline_banner,approval_gate}.dart` |
| Home map layout | `screens/home/view.dart`, `screens/home/widgets/{driver_status_card,location_state_view}.dart` |
| Trip flow | `screens/booking/view.dart`, `screens/booking/widgets/*.dart` |
| Payment receipt | `screens/calculate_fee/widgets/receipt_card.dart` |
| Map markers / pins | `lib/core/utils/load_custom_marker.dart`, `assets/marker/` |

### 8.3 Globally defined vs screen-specific

- **Global:** everything in `core/theme/` and `presentation/widgets/ds/`; the shell app bar and drawer chrome; `TAppBar` for pushed routes.
- **Screen-specific overrides:** local `fontSize`/dimension overrides listed in §7; the map polyline colour convention lives in `booking/view.dart` and `history_detail/logic.dart`; the home status card and map padding constants are `HomeScreen`-local (`home/view.dart:46-50`).

### 8.4 Shared with the Passenger app (candidates for reuse)

The following are self-contained and dependency-light, so they can be lifted into a shared design package across Driver/Passenger:
- `lib/core/theme/tokens.dart` + `lib/core/theme/app_theme.dart` (palette, type scale, spacing, radii, elevation, motion values).
- The whole `lib/presentation/widgets/ds/` set (`TButton`, `TCard`, `TTextField`, `TBadge`, `TSheet`, `TDialog`, `TStates`, `TSelection`, `TContent`, `TIcon`).
- `assets/icon/ds/*.svg` and the `ds_icons.dart` name map.
- `routes/transitions.dart` and `t_motion.dart`.

Reuse requires the Passenger app to register the same `TaarraaTokens` `ThemeExtension`; today each app owns its own copy of `tokens.dart` (this repo only contains the Driver app, so a shared package is *Needs verification* against the passenger codebase).

---

*Report generated from source at `1.1.9+1191`. No application code was modified.*
