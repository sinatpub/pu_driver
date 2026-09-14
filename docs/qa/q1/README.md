# Q1 — Visual QA: App Renders vs Prototype

Generated 2026-09-14. 34 surfaces × 2 locales × 2 widths = 136 app renders, 136 prototype captures, 100 side-by-side pairs, 1 contact sheet.

---

## Method

### App renders (`test/qa/visual_qa_test.dart`)

Each surface is a `SurfaceDef` — a `build` function returning a widget, plus a locale wrapper. The harness runs at the **390 px** / **320 px** device widths that match the prototype (phone = 100vw at viewport ≤ 480), in both `en` and `km`. Per combination it saves:

- `renders/<key>__<lang>__<width>.png` — pixel-perfect Flutter toImage render
- `geometry/<key>__<lang>__<width>.json` — machine-readable audit data: text styles, colours, radii, fills, borders, paddings, controls

### Prototype captures (`docs/taarraa-driver-prototype.html`)

A headless Chrome CDP script (`capture_proto.mjs`) serves the prototype locally, injects `@font-face` for Kantumruy Pro from bundled `.ttf` files, sets DPR 3 + the same 390/320 viewport, then:

1. Injects `setLang('en'|'km')` and any required state setup
2. Navigates to the target surface via `jump(...)`
3. Captures the full phone viewport

Output: `proto/<key>__<lang>__<width>.png` at 1170×2532 (390) or 960×2532 (320) — 1:1 pixel match with the app renders.

### Side-by-side pairs

`pairs/<key>__<lang>__<width>.png` — app render on the left, prototype on the right, labelled with surface name, locale, and width. 100 files covering 25 mapped surfaces.

Contact sheet: `qa1_contact_en_390.png` (22 surfaces, app over prototype, EN 390).

---

## Surface mapping

| App surface | Prototype target | Notes |
|---|---|---|
| 01_splash | splash | |
| 02_login | login | |
| 03_otp | otp | |
| 04_register | register | |
| 05_shell_app_bar | home | Status pill only |
| 05_drawer | drawer | |
| 05_approval_unknown | approval-pending | |
| 05_approval_pending | approval-pending | |
| 05_approval_rejected | approval-rejected | |
| 05_offline_banner | offline-bar | |
| 06_status_online | home | Home content |
| 06_status_offline | home-offline | Offline state |
| 07_request | booking-stage0 | New request |
| 07_pickup | booking-stage1 | Going to pickup |
| 07_at_pickup | booking-stage2 | At pickup |
| 07_on_trip | booking-stage3 | In progress |
| 08_receipt | receipt | |
| 09_history_tabs | history-completed | |
| 10_history_detail_card | history-detail | |
| 11_wallet | wallet | |
| 12_news_unread | news-unread | |
| 12_news_read | news-read | |
| 13_announcement_detail | announcement-detail | |
| 14_terms | terms | |
| 15_contact | contact | |

**9 surfaces with no standalone prototype counterpart** (enhancements beyond the prototype's scope):

| App surface | Why no match |
|---|---|
| 06_force_update | App-only gate; no prototype equivalent |
| 06_location_searching | Intermediate state; prototype jumps straight to home |
| 06_location_denied | Error state; prototype shows no permission flow |
| 06_location_failed | Error state; prototype shows no error state |
| 06_resume | Resume-trip banner; app-only |
| 07_header_request | Embedded inside booking-stage0 already paired |
| 07_header_pickup | Embedded inside booking-stage1 already paired |
| 07_header_waiting | Embedded inside booking-stage2 already paired |
| 07_header_on_trip | Embedded inside booking-stage3 already paired |

---

## Quantitative findings (EN / 390 px)

### Theme — intentional divergence (DD-01)

The prototype is **dark** (`--bg: #101216; --surface: #1B1E25; --text: #F2F3F7; --brand: #FF4500`). The app is **light**. This is **intentional per DD-01** (decision log `07-design-decision-log.md:43`): *"The app stays light. The prototype supplies layout, structure, and component hierarchy only — not surface colours."* Dark colours appear only as graphics (icons, status rings, brand marks).

### Text colour conformance — PASS

All rendered text colours fall within the token palette (`02-design-system.md §1.1`). No off-token text colours found.

| Colour | Token | Surfaces |
|---|---|---|
| `#3A3A3C` | `text` | 18 surfaces (titles, addresses, prices) |
| `#5C6474` | `text.secondary` | 26 surfaces (labels, hints, meta) |
| `#1C784D` | `stage.onTrip` / `success.text` | 6 (online pill, on-trip headers, "Completed" badge) |
| `#CC3700` | `brand.text` | 5 (logo, active tab, countdown ring, "Driver" label) |
| `#FFFFFF` | `action.textOnAction` | 10 (button labels, avatar on brand) |
| `#A33A00` | `stage.request` | 1 (request header) |
| `#1A579E` | `stage.pickup` | 3 (pickup/waiting headers, online text) |
| `#86650A` | `warning.text` | 2 (offline banner, meter estimate) |
| `#D32F2F` | `danger` | 2 ("Cancel request", "Cancel" badge) |
| `#6B7588` | `text.disabled` | 3 (disabled "Submit for review", "Contact support" link, approval gate) |

`inherit` (no explicit colour): 3 instances in `07_on_trip` (meter values — inherited from white text inside gradient ring), 1 in `03_otp` (description text).

### Controls

| Widget | Expected | Measured (EN/390) | Source |
|---|---|---|---|
| TButton (primary) | 390 − 2×20 = **350 × 56** | 350 × 56 ✓ | `TButton.size` |
| TIconButton (icon) | **48 × 48** | 48 × 48 ✓ | Tap-target ≥ 48 |
| App-bar TIconButton | **56 × 64** | 56 × 64 ✓ | `07 §5` |
| Approval TButton (secondary) | **308 × 48** | 308 × 48 ✓ | 390 − 2×(20+21) = 308; height 48 |
| Sheet TButton (primary) | **348 × 56** | 348 × 56 ✓ | Sheet 390 − 2×21 = 348 |
| Sheet TButton (secondary) | **348 × 48** | 348 × 48 ✓ | Same width, secondary height |
| Location pill | **342 × 48** | 342 × 48 ✓ | Sheet width − 6px each side |
| Force-update button | **292 × 56** | 292 × 56 ✓ | Full-width minus sheet padding |
| Offline pill | height 24 | ✓ | Compact banner |

### Type scale

Sizes in use: **12, 13, 14, 15, 16, 17, 18, 24, 30** px at `w400` / `w700`. All use the KantumruyPro family. Weights are `FontWeight.w400` (body, secondary) and `FontWeight.w700` (labels, titles, buttons). Tabular numerals applied to prices, timers, distances, codes.

Fractional sizes (`15.4`, `16.8`, `18.9`) are avatar-initial fallbacks (`size × 0.35` in `TContent`), not token-scale text — acceptable.

Two off-scale sizes found:

| Size | Token source | Override | Source |
|---|---|---|---|
| **19 px** | `numericLg` (22 px) | `.copyWith(fontSize: 19)` | `show_distand_and_price_widget.dart:33` (meter values) |
| **26 px** | — | hardcoded | `otp/view.dart:173` (OTP input digits) |

Neither deviates from the prototype's visual weight (OTP digits at 26 are larger than headline 24 for legibility; meter at 19 is denser than numericLg 22 to fit inside the countdown ring).

### Radii

On-token: **0, 12, 14, 16, 20, 22, 999** — all conforming to `Radii.sm/md/control/lg/xl/sheet/full`.

Off-token:

| Radius | Source | Deviation |
|---|---|---|
| **10** | `t_selection.dart:81` (TTabs pill indicator) | Token `md` is 12; pill uses 10 for tighter visual |
| **28** | `splash_screen/view.dart:47` (wordmark container) | No token; custom for the splash logo ring |

Sheet top corners correctly use `22, 22, 0, 0` (`Radii.sheetRadius` top-only pattern per `07 §4`).

### Fills and borders

The `#000000` fill appearances (7 surfaces) are a **reporting artifact** — `Colors.transparent` encodes as `0x00000000`, and the hex extractor takes `substring(2)` → `#000000`. No actual `Colors.black` exists in the codebase. Similarly, `#FF4500` fills are **allowed graphic-only brand** colours (rings, icons, badges) per DD-02/roadmap guard; no surface fills use brand.

| Fill colour | Surfaces | Verdict |
|---|---|---|
| `#000000` | 7 | Transparent artifact — not a defect |
| `#FF4500` | booking, receipt | Brand graphic fill — allowed |
| `#10CF7C` | success states | Brand-success graphic — allowed |
| `#FFB020` | 1 | Brand-warning graphic — allowed |
| `#5C6474`, `#86650A`, `#D32F2F`, `#A33A00` | various | Token fills used in status-specific backgrounds |

All major border colours are on-token: `#E2E2E5` (divider), `#8F90A6` (control/field), `#1C784D` (success border), `#CC3700` (brand border).

### Paddings

All surfaces respect the spacing scale (`02 §3`): 12, 16, 20, 21, 24, 40, 48, 64. The horizontal content gutter of 20 px (`Insets.s20`) and sheet inner padding of 21 px (`Insets.s21`) are consistent across all sheets and lists. Status-card horizontal padding is 12 px.

---

## Defects found — harness fidelity (fixed)

| Issue | Surface | Fix |
|---|---|---|
| `File('...renders').createSync(recursive: true)` creates a file, not a directory | All | Changed to `Directory('...renders').createSync(recursive: true)` |
| `#000000` hex confusion | reported from `Colors.transparent` | Acceptable — no black in palette; `#000000` = transparent |
| `'MY_WALLET_label'` / `'commission label'` — harness literals, not `.tr()` keys | 11_wallet | Replaced with `'MY_WALLET'.tr()` and `'COMMISSION_FARE'.tr()` |
| `'NO_INTERNET_RECONNECTING'` passed raw to TBanner without `.tr()` | 05_offline_banner | Changed to `'NO_INTERNET_RECONNECTING'.tr()` |
| Sheet surfaces overflowed in `localizedHost` (unbounded `SingleChildScrollView`) | 07_request/pickup/at_pickup/on_trip | Wrapped in `Scaffold(body: _sheet(n), page: true)` matching a11y pattern |
| `RenderParagraph` cast unreliable (renderObject can be `RenderSemanticsAnnotations`) | 09_history_tabs | Changed to read `w.data ?? w.textSpan?.toPlainText()` |

---

## Deviations from token system — summary

| Deviation | Location | Impact | Verdict |
|---|---|---|---|
| `fontSize: 19` override of `numericLg` (22) | `show_distand_and_price_widget.dart:33` | Meter values | Acceptable — fit constraint inside countdown ring; prototype uses visually smaller numerals |
| `fontSize: 26` (no token) | `otp/view.dart:173` | OTP input digits | Acceptable — digit-only input needs extra legibility; no matching token for 26 |
| `radius: 10` in TTabs pill | `t_selection.dart:81` | Tab/segment indicator | Acceptable — tighter than `md` (12) for pill shape |
| `radius: 28` in splash wordmark | `splash_screen/view.dart:47` | Logo container | Acceptable — decorative; no token conflict |
| `fontSize: size * 0.35` in TContent | `t_content.dart:49` | Avatar initials | Acceptable — tile-relative computation, not scale text |

---

## Artifacts

| Path | Count | Description |
|---|---|---|
| `docs/qa/q1/renders/*.png` | 136 | App renders (34 surfaces × 2 locales × 2 widths) |
| `docs/qa/q1/geometry/*.json` | 136 | Machine-readable audit data per render |
| `docs/qa/q1/proto/*.png` | 136 | Prototype captures (matching combos) |
| `docs/qa/q1/pairs/*.png` | 100 | Side-by-side (app left, prototype right) for 25 mapped surfaces |
| `docs/qa/q1/qa1_contact_en_390.png` | 1 | Contact sheet: 22 surfaces at EN/390 |

---

## Next steps

1. **User review**: Open `docs/qa/q1/pairs/` and `qa1_contact_en_390.png` to verify structural match against the prototype. Flag any layout, spacing or component-order mismatches.
2. **Q2 — Functional regression**: Device-only; live-backend regression across the trip flow (FCM, sockets, navigation, G0 baseline comparison). Carry from Q1 as no device was available.
3. **Q3 — Performance review**: Frame timings, jank metrics, APK size.
