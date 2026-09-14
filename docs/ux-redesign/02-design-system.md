# 02 — Design System (target)

**Theme: light.** Confirmed by the user on 2026-09-12 (`DD-01`). The prototype is dark; it supplies **layout, structure, components and hierarchy**, while colour is mapped onto a light palette built from the app's existing tokens and `../ux_ui_design/ui-layout-system.md`.

**How to read the Status column:**

| Status | Meaning |
|---|---|
| `CONFIRMED` | Verbatim from existing Flutter (`lib/core/theme/*`), the prototype (`HTML:<line>`) or `ui-layout-system.md`. |
| `INFERRED` | Derived from those sources. |
| `PROPOSED` | New, or a light-mode equivalent of a dark prototype value. |

Contrast ratios use the WCAG 2.1 relative-luminance formula and were measured in the analysis session. Floors: **4.5:1** text, **3:1** large text, **3:1** control borders and meaningful icons.

---

## 0. Token architecture (PROPOSED)

- **`ThemeExtension<TaarraaTokens>`** holds the semantic colours, spacing, radii and shadows.
- **`ThemeData`** is built from it with `brightness: light`; `useMaterial3: true` stays (`core/theme/app_theme.dart:13`).
- **Components read semantic tokens only.** Never a primitive, never `Colors.*`.
- **The app is already light**, so the new `ThemeData` can be installed in F1 and screens migrate under it one at a time. No per-route theme wrappers are needed (`DD-34`).
- **Legacy styles stay until the last screen migrates, then get deleted** (RULES: no dead code). Today's footprint, counted:
  - `ThemeConstands.` — 111 references
  - `AppColors.` — 242 references
  - `Colors.*` — 307 literals in `lib/presentation`

---

## 1. Colour

### 1.1 Semantic tokens

| Token | Value | Source | Status | Use · measured contrast |
|---|---|---|---|---|
| `bg.page` | `#F2F2F5` | `AppColors.light3` | CONFIRMED | Scaffold behind cards and lists |
| `bg.surface` | `#FFFFFF` | — | PROPOSED | Cards, sheets, dialogs, inputs, app bar |
| `bg.raised` | `#EBEBF0` | `AppColors.light2` | CONFIRMED | Segmented and tab tracks, chip rests |
| `bg.sunken` | `#E2E2E5` | `AppColors.light1` | CONFIRMED | Disabled fills |
| `bg.floating` | `#FFFFFF` | — | PROPOSED | Cards floating over the map (opaque, not translucent — translucency was a dark-mode device) |
| `bg.scrim` | `#3A3A3C` @48% | layout-system §5 | CONFIRMED | Scrim behind sheets, dialogs, drawer |
| `bg.blocking` | `#FFFFFF` @97% | — | PROPOSED | Full blocking overlays (approval gate) |
| `border.divider` | `#E2E2E5` | `AppColors.light1` | CONFIRMED | Dividers and card hairlines — decorative (1.29 on white) |
| `border.control` | `#8F90A6` | `AppColors.dark3` | CONFIRMED | Input, chip, icon-button and ghost-button outlines · **3.13 on white** ✓. Controls sit on white, not on `bg.page` (2.80 there) |
| `border.focus` | `#CC3700` | `AppColors.darker` | CONFIRMED | Focused input · 5.10 |
| `text.primary` | `#3A3A3C` | `AppColors.dark1` | CONFIRMED | 11.35 on white · 10.16 on page |
| `text.secondary` | `#5C6474` | `AppColors.dark2` | CHANGED in P3 (was `#6B7588`) | Sub-lines, meta, placeholders · 5.95 surface / 5.32 page / 5.01 raised / 4.60 sunken. `#6B7588` failed AA on page (4.15) and raised (3.91), caught by `textContrastGuideline` — design review requested |
| `text.disabled` | `#6B7588` on `bg.sunken` | — | PROPOSED | 3.59 — inert controls only (layout-system §2 rule 5) |
| `text.onAction` | `#FFFFFF` | — | CONFIRMED | On `action.primary` · 5.10 |
| `brand.identity` | `#FF4500` | `AppColors.main`; `--brand` HTML:10 | CONFIRMED | **Graphics only:** logo, route line, markers, countdown arc, active indicator fills · 3.44 on white (≥3:1 non-text) ✓ · **never text, never a fill under white text** |
| `brand.text` | `#CC3700` | `AppColors.darker` | CONFIRMED | Brand-coloured text and links · 5.10 |
| `brand.tint` | `#FFF1EC` | — | PROPOSED | Selected row or chip background · carries `brand.text` at 4.63 ✓ |
| `action.primary` | `#CC3700` | `AppColors.darker` | CONFIRMED | Primary button fill · white label 5.10 ✓ |
| `action.highlight` | `#D93B00` | — | PROPOSED | Optional top stop of the button gradient · white 4.59 ✓ |
| `action.pressed` | `#A82D00` | — | PROPOSED | Pressed fill · white 6.91 |
| `success` | `#1C784D` | layout-system success-700 | CONFIRMED | Success **text, icons and fills** · 5.46 on white · white-on-it 5.46 |
| `success.graphic` | `#10CF7C` | `AppColors.success` | CONFIRMED | Dots, marker accents, meter bars only · 2.05 as text ✗ |
| `success.tint` | `#E6F7EF` | — | PROPOSED | Online pill, on-trip strip, done timeline step · carries `success` at 4.92 ✓ |
| `warning` | `#86650A` | layout-system warning-700 | CHANGED in P3 (was `#8D6B07`) | Warning **text** · 5.41 surface / 4.84 page / 4.56 raised / 4.88 on `stage.onTrip.tint`. `#8D6B07` failed AA under the meter's estimate note (4.46) — design review requested |
| `warning.graphic` | `#FFB020` | `--amber` HTML:15 | CONFIRMED | Countdown arc ≤10 s, warning icons · fails as text |
| `warning.tint` | `#FFF6E5` | — | PROPOSED | Offline banner, pending approval · carries `warning` at 4.62 ✓ |
| `danger` | `#D32F2F` | `AppColors.error` | CONFIRMED | Error text, destructive outline and label · 4.98 |
| `info` | `#1976D2` | `AppColors.info` | CONFIRMED | Informational text and icons · 4.60 |
| `stage.request` tint / text | `#FFF1E8` / `#A33A00` | — | PROPOSED (light form of `.st-req` HTML:173) | "New request" pill · **6.01** ✓ |
| `stage.pickup` tint / text | `#E8F1FD` / `#1A579E` | — | PROPOSED (light form of `.st-go` HTML:174) | Going to and at pickup · **6.35** ✓ |
| `stage.onTrip` tint / text | `#E6F7EF` / `#1C784D` | — | PROPOSED (light form of `.st-carry` HTML:175) | On-trip pill and meter strip · **4.92** ✓ |
| `toast` bg / fg | `#3A3A3C` / `#FFFFFF` | — | PROPOSED | Dark toast on a light UI · **11.35** ✓ |
| `avatar.fallback` bg / fg | `#EBEBF0` / `#5C6474` | — | CHANGED (was `#6B7588`, which is 3.91 on this fill; its 4.64 was measured on white) | Initials when there's no photo · 5.01 ✓ (the prototype's orange→purple gradient carried white initials at 2.87 ✗) |

### 1.2 Contrast verification (measured)

| Pair | Ratio | Result |
|---|---|---|
| `text.primary` on white / page | 11.35 / 10.16 | AA |
| `text.secondary` on white / page | 4.64 / 4.15 | AA on white; on `bg.page` use it for meta only, or move the surface to white |
| `brand.text` on white | 5.10 | AA |
| White on `action.primary` | 5.10 | AA |
| White on `action.highlight` | 4.59 | AA |
| White on `action.pressed` | 6.91 | AA |
| `brand.identity` on white | 3.44 | **Graphics only** |
| `success` on white · white on `success` | 5.46 | AA |
| `warning` on white | 4.95 | AA |
| `danger` on white | 4.98 | AA |
| `info` on white | 4.60 | AA |
| `stage.request` / `.pickup` / `.onTrip` text on their tints | 6.01 / 6.35 / 4.92 | AA |
| `brand.text` on `brand.tint` | 4.63 | AA |
| `warning` on `warning.tint` | 4.62 | AA |
| `border.control` on white | 3.13 | AA (non-text) |
| White on `toast` | 11.35 | AA |
| `text.disabled` on `bg.sunken` | 3.59 | Inert controls only |

### 1.3 Values rejected

| Value | Where it came from | Problem (measured) | Replacement |
|---|---|---|---|
| `#FF4500` as button fill under white text | `AppColors.main`, today's `FBTNWidget`; `.btn` HTML:63 | 3.44 | `action.primary #CC3700` |
| `#FF4500` as text or link | prototype brand text | 3.44 on white | `brand.text #CC3700` |
| `#10CF7C` as text | `AppColors.success`, today's switch label | 2.05 | `success #1C784D`; keep `#10CF7C` for dots and bars |
| `#FFB020` as text | `--amber` | fails on white | `warning #8D6B07` |
| `#FF1100` red totals and drop button | `AppColors.red`, `calculate_fee/view.dart:369-393` | Reads as an error on money and on a forward action | `text.primary` amounts; `action.primary` buttons (`DD-04`, `DD-12`) |
| `#8F90A6` as text | `AppColors.dark3` | 3.13 | `text.secondary #6B7588`; `#8F90A6` stays a border and decorative-icon colour |
| Dark surfaces `#101216 / #1B1E25 / #262B36` | prototype `:10` | Dark theme | `bg.page / bg.surface / bg.raised` |
| Heavy black shadows `0 10px 30px rgba(0,0,0,.45)` | `--sh` HTML:18 | Muddy on light | §5 elevation |
| Translucent map cards `rgba(27,30,37,.94)` | `.earn-card` HTML:150 | Illegible over a light map | Opaque white + border |
| 11 px uppercase labels | `.t1` HTML:193 | Below 12 px; all-caps has no Khmer form | `micro` 12/700, sentence case |
| `.btn.sm` 46 px, `.icon-btn` 42 px | HTML:68, 86 | Below the 48 px target | 48 px |

### 1.4 Colour rules

1. **Brand means action or identity, never status.** `brand.identity` is for graphics; anything with a white label on it uses `action.primary`.
2. **Status = colour + icon + word.**
3. **Money is `text.primary`** in ledgers, receipts and totals (`DD-04`). The in-trip meter sits on `stage.onTrip.tint` because that marks the stage, not the money.
4. **Destructive is an outline, never a filled red button** (layout-system §7): white fill, 1.5 px `danger` border, `danger` label.
5. **Disabled is never the only signal**, and informational text stays at `text.secondary` even in a disabled container.
6. **Separation is by border first, shadow only where something floats** — on light, shadow-heavy UI over a map turns to mud.

### 1.5 Legacy → token mapping (for migration)

| Legacy | → Token | Note |
|---|---|---|
| `AppColors.main #FF4500` | `brand.identity` (graphics) / `action.primary` (buttons) | The split is the whole point of `DD-02` |
| `AppColors.darker #CC3700` | `action.primary`, `brand.text`, `border.focus` | |
| `AppColors.red #FF1100` | removed | Icons → `brand.identity`; amounts → `text.primary` |
| `AppColors.error #D32F2F` | `danger` | |
| `AppColors.success #10CF7C` | `success.graphic` | Text switches to `success` |
| `AppColors.info #1976D2` | `info` | |
| `AppColors.dark1 / dark2 / dark3` | `text.primary` / `text.secondary` / `border.control` | `dark4 #C7C9D9` is decorative only |
| `AppColors.light1 / light2 / light3 / light4` | `bg.sunken` / `bg.raised` / `bg.page` / — | `light4 #FAFAFC` is superseded by white surfaces |
| `Color(0xff01b951)` wallet card (`wallet/view.dart:92`) | `success.tint` card | |
| `Colors.red` route polyline (`booking/view.dart:335`) | `brand.identity` | |
| EasyLoading yellow-on-green (`main.dart:60-74`) | `bg.surface` + `action.primary` indicator | Config only (`DD-09`) |

---

## 2. Typography

- **Family:** Kantumruy Pro. CONFIRMED: bundled (`pubspec.yaml:121-130`) and first in the prototype's stack (HTML:23).
- **Weights:** the prototype uses 800; the bundled faces are Regular, SemiBold and a variable font. Map 800 → 700, and verify the variable face is registered so `FontWeight.w700` resolves — today styles select a face by family name (`text_styles.dart:21`). INFERRED; O-2.

| Token | Size / weight | Line height Latin / Khmer | Prototype source (CONFIRMED) | Use |
|---|---|---|---|---|
| `display` | 30 / 700 | 1.25 / 1.5 | `.total-box b` HTML:211 | Amount to collect |
| `headline` | 24 / 700 | 1.3 / 1.55 | `h1` HTML:24 | Screen titles, blocking-state titles |
| `numericLg` | 22 / 700, tabular | 1.2 / 1.2 | `.count-ring .secs` HTML:177 | Countdown seconds |
| `title` | 18 / 700 | 1.35 / 1.7 | `.dialog h3` HTML:110; focused address HTML:932 | Dialog titles, focused address |
| `subtitle` | 17 / 700 | 1.35 / 1.7 | `h2` HTML:25 | App-bar and section titles |
| `bodyStrong` | 16 / 700 | 1.4 / 1.75 | `.btn` HTML:63 | Button labels, names, addresses |
| `body` | 15 / 400 | 1.45 / 1.8 | inputs HTML:31 | Body copy, input text |
| `bodySecondary` | 14 / 400 | 1.55 / 1.8 | `.dialog p` HTML:111 | Dialog and news body (`text.secondary`) |
| `label` | 13 / 700 | 1.35 / 1.7 | `.lbl` HTML:72 | Field labels, chips, tabs |
| `caption` | 12 / 400 | 1.35 / 1.7 | `.tiny` HTML:27 | Meta, timestamps |
| `micro` | 12 / 700 | 1.3 / 1.6 | `.badge` HTML:90 | Badges, pills, timeline labels, overlines |

**Rules:**
- Sizes are CONFIRMED from the prototype; line heights are PROPOSED from `ui-layout-system.md §3` ratios. Switch sets when `context.locale.languageCode == 'km'`.
- **Numerals:** tabular (`FontFeature.tabularFigures()`) for money, timers, distances and codes (`.mono` HTML:28). UNCLEAR whether Kantumruy Pro ships `tnum` (O-1); if not, right-align numeric columns and give timers a fixed-width box.
- **Minimum 12 px. No uppercase transforms.** Letter-spacing is Latin-only.
- Don't carry `ThemeConstands` forward; that also retires the `font10SemiBold`-is-14 px bug (U6).
- **Text scale:** keep the 1.0–1.3 clamp (`root_main.dart:41-42`, `DD-30`). Every component uses a min-height.

---

## 3. Spacing (4 px grid)

**Tokens:** `s4, s8, s12, s16, s20, s24, s32`.

| Context | Value | Source |
|---|---|---|
| Full-screen horizontal padding | 20 | `.screen` HTML:38 |
| Tab content padding | 16 | `.scroll` HTML:146 |
| Top padding | `SafeArea` | The prototype's 46 px is its fake status bar |
| Card padding | 16 (receipt 18) | `.card` HTML:80 |
| Generic sheet padding | 12 / 20 / 26 + safe area | `.sheet` HTML:105 |
| Trip sheet padding | 12 / 20 / 24 + safe area | `.bsheet` HTML:179 |
| Dialog padding | 22 | `.dialog` HTML:108 |
| Gap between list rows | 8 | `.tx` HTML:238 |
| Grid gap | 12 | 10 in the prototype, snapped to the grid |
| Between any two tap targets | ≥ 8 | layout-system §4 |
| Between Accept and Cancel | ≥ 16 | `DD-11` |

## 4. Radius (CONFIRMED, HTML:17 and literals)

| Token | Value | Use |
|---|---|---|
| `r.sm` | 8 | Small inner elements |
| `r.md` | 12 | Icon buttons, drawer rows, route box, images |
| `r.control` | 14 | Buttons, fields, OTP boxes, list tiles, trip card, passenger row |
| `r.lg` | 16 | Cards, wallet cards, receipt, minimap, status card |
| `r.xl` | 20 | Dialogs |
| `r.sheet` | 22 (top only) | Sheets |
| `r.full` | 999 | Pills, badges, avatars, chips, grabber |

## 5. Elevation (light)

On light, **borders separate and shadows only lift what floats** (layout-system §5). The prototype's heavy dark shadows are not carried over.

| Token | Value | Status | Use |
|---|---|---|---|
| `elev.flat` | 1 px `border.divider`, no shadow | CONFIRMED | Cards on `bg.page` |
| `elev.float` | (0, 2) / 8 / `#3A3A3C` @12% | CONFIRMED | Cards and pills floating over the map, countdown, toast |
| `elev.sheet` | (0, −2) / 16 / `#3A3A3C` @10% | CONFIRMED | Bottom sheets, top corners only |
| `elev.modal` | (0, 8) / 32 / `#3A3A3C` @16% | CONFIRMED | Dialogs, over `bg.scrim` |
| `elev.selected` | (0, 1) / 2 / `#3A3A3C` @8% | PROPOSED | Selected segment or tab |

Shadow colour is the neutral `#3A3A3C` at low alpha, never pure black.

## 6. Icons

- **Style:** 24 viewBox, stroke 2, round caps and joins (prototype sprite HTML:275+).
- **Sizes:** 16 / 22 / 28. **Touch target:** 48.
- **Colours:** default `text.secondary`; active `brand.text`; on a filled button, white.
- **Implementation (PROPOSED):** export the symbols in use to `assets/icon/ds/*.svg` and render with the existing `flutter_svg`, tinted from the current text colour. Material `Icons.*_rounded` is the fallback. **No emoji as icons.**

| Symbol | Used for | Replaces today |
|---|---|---|
| `i-menu` | drawer button | default hamburger |
| `i-bell` | announcements | `CupertinoIcons.bell_circle_fill` 44 px (`drawer/view.dart:88-92`) |
| `i-home`, `i-cal`, `i-wallet`, `i-doc`, `i-mail`, `i-globe` | drawer items | mixed SVG and Material icons |
| `i-car` | trip header | — |
| `i-phone` | call passenger, contact | `Icons.phone_outlined` in error red |
| `i-clock`, `i-route` | duration, distance | `time_outline`, `map_outline` |
| `i-check`, `i-x`, `i-warn`, `i-info` | status, approval, banners, estimate note | — |
| `i-back`, `i-chev`, `i-refresh`, `i-cam` | navigation, rows, refresh, photo slots | Material defaults |

---

## 7. Buttons

| Variant | Fill | Label | Border | Height | Prototype | Used for |
|---|---|---|---|---|---|---|
| `primary` | `action.primary` (optional gradient `action.highlight→action.primary`) | White, `bodyStrong` | — | 56 | `.btn` HTML:63 | Accept, I've arrived, Drop off, Next, Submit |
| `success` | `success` | White, `bodyStrong` | — | 56 | `.btn.green` HTML:65 | Start ride, Payment done |
| `secondary` | `bg.surface` | `text.primary` | 1 px `border.control` | 56 / 48 | `.btn.ghost` HTML:66 | Retry, Contact support, dialog neutral action |
| `destructiveOutline` | `bg.surface` | `danger` | 1.5 px `danger` | 56 / 48 | `.btn.danger-ghost` HTML:67 | Dialog "Yes, cancel" |
| `tertiary` | none | `brand.text`, or `danger` when destructive | — | min 48 | `.tbtn` HTML:69 | Cancel request, Resend code |

**States:**

| State | Treatment | Source |
|---|---|---|
| Pressed | Scale .97 for 100 ms + `action.pressed` | HTML:30 |
| Disabled | `bg.sunken` fill + `text.disabled`, no shadow | HTML:64 |
| Loading | 20 px spinner in the label colour; **width unchanged**; taps ignored | existing `FBTNWidget.loadingBut` |

Full width inside the screen padding unless paired. Dialog pairs split equally with a 10 px gap.

## 8. Inputs

- **Field:** 56 high (prototype 54), `bg.surface`, 1.5 px `border.control`, radius 14, 14 px horizontal padding. Text `body`; placeholder `text.secondary`.
- **Focus:** `border.focus`, 1.5 px.
- **Label above:** `label` in `text.secondary`, 16 top / 8 bottom.
- **Error:** `danger` border, a 13 px `danger` message with `i-warn` 6 px below, and a 400 ms shake (the existing `ShakeWidget`).
- **OTP:** 4 boxes, 64 high, 26/700, radius 14; focus = `border.focus` + a 3 px `brand.tint` halo. A Pinput theme.

## 9. Cards and rows

| Element | Spec | Source |
|---|---|---|
| Card | `bg.surface`, 1 px `border.divider`, `r.lg`, padding 16, `elev.flat` | `.card` HTML:80 |
| Key-value row | Label `bodySecondary` `text.secondary` / value `bodyStrong` 14 `text.primary`, 8 px vertical | `.kv` HTML:207 |
| Address row | 12 px dot (pickup `brand.identity` + `brand.tint` halo; destination `text.secondary` + grey halo) · overline `micro` `text.secondary` · primary `bodyStrong` (`title` when it's the stage focus) · secondary `caption` | `.addr-row` HTML:192-197 |
| Passenger row | `bg.page` fill, `border.divider`, `r.control`, padding 12, avatar 48, call icon-button with `success` outline | `.pax-row` HTML:190, 923 |
| List tile | `bg.surface`, `border.divider`, `r.control`, padding 12×14, gap 8 | `.tx` HTML:238 |

## 10. Bottom sheets

- **Generic modal sheet:** `bg.surface`, top radius 22, `elev.sheet`, grabber 44×5 in `border.divider`, padding 12 / 20 / 26 + safe area, max 84%, scrim `bg.scrim`, enters 300 ms from +60 px.
- **Trip sheet:** **persistent, not modal.** Max 74%, `elev.sheet`. Grabber → timeline → collapsible content (scrolls) → **pinned action bar**. The primary action never scrolls (`DD-10`).

## 11. Dialogs, toast, banners

- **Dialog:** `bg.surface`, `r.xl`, padding 22, `elev.modal`, centred; enters 250 ms scale .9 → 1. Title `title`, body `bodySecondary`. Actions in an equal-width row, gap 10 — **the safe choice is the primary**, the risky one is `destructiveOutline`.
- **Auto-dismiss variant:** a 6 px progress bar draining over the existing timer's duration (`DD-25`).
- **Toast:** `toast` tokens (dark pill on light UI), 14/700, `elev.float`, 32 px above the safe area, 2.4 s. Only for new presentation feedback (`DD-27`).
- **Offline banner:** `warning.tint` fill, `warning` text and `i-warn`, `micro`, full width under the app bar; non-dismissible while offline; renders nothing when online (`DD-26`).

## 12. Navigation

- **Shell app bar:** `bg.surface`, no elevation, 1 px bottom `border.divider`. Left to right: menu icon-button (48) · title (the `TAARRAA` wordmark with a `micro` overline "DRIVER · តារា" in `brand.text`, or the tab title) · notifications icon-button (48) · online pill (home tab only).
- **Drawer:** 80% wide, `bg.surface`. Profile head: avatar 54, name 16/700, `caption` "phone · vehicle — driver id". Menu rows 48+ with 22 px icons; the active row is `brand.tint` + `brand.text`. A language row with a two-option segmented control.
- **Detail app bar:** back icon-button + `subtitle` title.

## 13. Status indicators

| Indicator | Spec | Source |
|---|---|---|
| Online pill | 48 high, pill. **Off:** `bg.raised`, `border.control`, `text.secondary` label, `#8F90A6` dot. **On:** `success.tint` fill, `success` border and label, `success.graphic` dot with a 1.4 s pulse | `#onlinePill` HTML:140-143 |
| Stage pill | `micro`, padding 9×14, 9 px pulse dot, `stage.*` tint + text | `.status-pill` HTML:171-175 |
| Badge | `micro`, padding 5×11, tints: success / danger / warning / brand / info / neutral; always carries text | `.badge` HTML:90-96 |
| Countdown | Floating white pill, `elev.float`; 46 px ring stroke 6; track `border.divider`, arc `brand.identity` → `warning.graphic` at ≤10 s; seconds `numericLg` in `text.primary`; `caption` "to decide" | `.count-ring` HTML:176-178 |
| Timeline | 4 steps, 26 px dots. **Done:** `success.tint` + `success` check. **Current:** `action.primary` fill, white number. **Future:** `bg.raised` + `text.secondary`. 2 px connector | `.tstep` HTML:180-189 |

## 14. Map presentation

- **Provider:** Google Maps, **default light styling** — no style JSON and no new asset. The prototype's dark map was a placeholder (`docs/ui-reference/05 §4`) and does not apply in light mode.
- **Route polyline:** `brand.identity`, 5 px (today `Colors.red` at 5 px, `booking/view.dart:335-337`).
- **Markers:** the existing assets, unchanged (`core/utils/load_custom_marker.dart`).
- **Overlay cards:** opaque `bg.floating` + `border.divider` + `elev.float`, so they stay legible over map imagery.
- **Map padding:** `GoogleMap.padding.bottom` = the current sheet or card height, keeping the Google logo, zoom controls and compass visible. They stay enabled as today.
- **Traffic layer:** stays on for Home (`home/view.dart:83`).

## 15. Motion

| Transition | Duration / curve | Source |
|---|---|---|
| Screen enter | 250 ms fade + 10 px rise | `fadeUp` HTML:39-40 |
| `/home` | none — preserve `Transition.noTransition` | `app_pages.dart:30-33` |
| Sheet in | 300 ms `cubic(.2, .9, .3, 1)` | HTML:105-106 |
| Dialog in | 250 ms scale .9 → 1 | HTML:108-109 |
| Drawer in | 280 ms, 60 px slide | HTML:158-159 |
| Stage content change | 150 ms cross-fade | PROPOSED |
| Button press | 100 ms scale .97 | HTML:30 |
| Live pulse | 1.2–1.4 s opacity | `pl` HTML:144 |
| Error shake | 400 ms | HTML:98-99 |

When `MediaQuery.disableAnimations` is true: no pulses, fades only. **Money values never animate.**

## 16. Open items

| ID | Question |
|---|---|
| O-1 | Does Kantumruy Pro ship tabular figures? |
| O-2 | Is the variable face registered so `w700` resolves? |
| O-4 | Brand-owner sign-off on the `#FF4500` identity / `#CC3700` action split (`DD-02`). `ui-layout-system.md` proposes `#DB4C25` / `#BA401F` instead; this system keeps the app's and prototype's `#FF4500` family |
| O-6 | Confirm map legibility in direct sunlight with the default light style and `#FF4500` route line |
