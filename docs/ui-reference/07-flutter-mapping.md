# 07 — Flutter Mapping (Conceptual Only)

> This section maps the prototype's concepts to Flutter equivalents to aid a future implementation agent. **No Flutter code is written and no new architecture is prescribed** beyond what the prototype's structure implies. The prototype is the target UI/UX.

## 1. Core concept mapping

| HTML Concept | Flutter Concept | Notes |
| --- | --- | --- |
| CSS custom property (`--bg`, `--brand`…) | `ThemeExtension` / design-token class | one source of truth for colors/radii/spacing |
| `:root` token set | `ThemeData` (ColorScheme + custom extension) | map each `--*` var to a named token |
| `<section class="screen">` (SPA "page") | `Screen`/`Page` widget + Navigator route (or an indexed shell) | prototype uses a custom `jump()` router |
| `.screen.active` toggle | route transition / `IndexedStack` | screen swap has `fadeUp` animation |
| `#tabBody` + tab renderers | `IndexedStack`/`TabBarView` inside a shell Scaffold | shell holds 5+ tabs |
| Drawer `.drawer` | `Drawer` / `endDrawer` | the prototype's only nav menu (no bottom bar) |
| `.sheet` / `.bsheet` | `showModalBottomSheet` | grab handle + rounded top corners |
| `.dialog` | `AlertDialog`/`Dialog` | centered modal |
| `#toast` | `SnackBar` (custom styled) | light surface, green check |
| `.btn`, `.icon-btn`, `.chip`, `.badge` | reusable widget components | shared styles → widgets |
| Reused render functions (`mapSVG`, `qrSVG`) | `CustomPainter` widgets | both are procedural drawings |
| `flex`/`grid` CSS | `Row`/`Column`/`Wrap`/`GridView`/`LayoutBuilder` | e.g. `.wal-grid`/`.photo-grid` → `GridView.count(crossAxisCount:2)` |
| CSS `:focus-within` / `:disabled` / `.on` | widget `FocusNode` state / `onChanged` / `enabled` / selected flags | class toggles become state |
| `S{}` mutable state + re-render | `StatefulWidget` + `setState` (or a state-management layer of choice) | single global-ish state object |
| `data-i18n` + `I18N` dict | `AppLocalizations` / `intl` `.arb` (EN + km) | Khmer = `km` locale |
| CSS keyframe animations (`fadeUp`,`up`,`pop`,`shake`,`pl`,`tickmove`,`ringx`) | `AnimationController` + `Tween`/`Curves` | e.g. `fadeUp` ≈ FadeTransition + SlideTransition(0→10px) |
| `moveMarker()` RAF loop | `AnimationController` driving a `Transform.translate` | route replay + driver motion |
| WebAudio `beep()` | `SystemSound` / `audioplayers` / `just_audio` | short notification sounds |
| `@media (prefers-reduced-motion)` | `MediaQuery.disableAnimations` / accessibility | ticker pause |
| `viewport-fit=cover` + safe areas | `SafeArea` | status-bar top padding (46px in prototype) |

## 2. Structural mapping

| Prototype structure | Flutter structure |
| --- | --- |
| `s-shell` + `#tabBody` (drawer-nav tabs) | One `Scaffold` with `drawer`, a custom top app bar, and an `IndexedStack` of tab pages |
| `s-splash` → `s-login` → `s-otp` → `s-register` | Auth flow of screens (Navigator push/pushReplacement) |
| `s-booking`, `s-fee` | Trip-flow screens pushed over the shell |
| `s-hdetail`, `s-newsdetail` | Detail screens (push, with back button) |
| `#approvalOv`, `#paySuccess` overlays | full-screen overlay widgets / `Stack` layers (or dedicated screens) |
| `#ticker`, `#offlineBar` | inline banner widgets in shell `Column` |

## 3. Key mapping decisions the prototype implies (evidence-based)

1. **Dark theme only** — the prototype has a single dark palette (no light theme). A `ThemeData.dark()` base is implied.
2. **Map-first home** — home is a full-bleed map with a floating earnings card + QR FAB; in Flutter this is a `Stack` (map widget + positioned card/FAB). The prototype's map is a placeholder (`CustomPaint`); the production map provider is NOT specified by the prototype.
3. **Bottom-sheet trip flow** — booking stages all live in a persistent bottom sheet over the map; map + sheet are siblings in a `Stack`.
4. **Drawer as primary nav** — no bottom navigation bar; port the drawer, not a `BottomNavigationBar`.
5. **Runtime i18n EN/KM** — every visible string is in the `I18N` dict; Flutter side needs `km` localization resources.
6. **State machine for trip stages** — `S.stage` (0..3) + `STAGES[]` config maps directly to an enum + per-stage sheet widget.
7. **Local-only interactions** — login/OTP/booking/fare/wallet/referral are all simulated in JS; the Flutter agent will need real services (auth, booking, payments) that the prototype does not define.

## 4. Reusable widget candidates (for the implementation agent)

`PrimaryButton` (`.btn` + variants), `TextButton` (`.tbtn/.link`), `IconButton` (`.icon-btn`), `Badge`/`StatusPill`, `Chip`, `SegmentedControl` (`.seg`), `Tabs` (`.tabs`), `Field` (`.field`), `StepsIndicator` (`.steps`), `Avatar` (3 sizes), `AddressRow`, `KeyValueRow`, `Card`, `AppBar`, `BottomSheet`/`Dialog`/`Toast` wrappers, `TripTimeline` (`.tstep`), `FareStrip`, `Receipt`, `EarningsCard`, `QrFab`, `TickerBar`, `OfflineBar`, `PhotoSlotGrid`, `OtpInput`, `CountdownRing`, `DarkMap` (CustomPainter), `QrPlaceholder` (CustomPainter), `NewsCard`, `HistoryCard`, `TransactionRow`, `WalletStatCard`, `DrawerMenu`.

## 5. Explicitly out of scope for this document

- No Flutter code, packages, folder layout, or architecture is prescribed here.
- No API/back-end structure is invented (see 06/05 docs for what data the UI expects).
- No map provider is assumed (prototype map is a placeholder).
