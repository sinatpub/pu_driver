# 01 — HTML Structure & Architecture

> Source of truth: `taarraa-driver-prototype (1).html` (single file, 1,065 lines, ~101 KB).
> Inspection date: 2026-09-11. This document describes what the prototype **actually contains**; nothing is inferred beyond the code.

## 1. Prototype type

| Question | Answer | Confidence |
| --- | --- | --- |
| One file or many? | **One** self-contained HTML file | CONFIRMED |
| Page model | Single-file **SPA** (single `<html>` document; "pages" are `<section>` elements toggled by JS) | CONFIRMED |
| Static or JS-driven? | **JavaScript-driven** — a custom vanilla-JS router + render functions generate most UI | CONFIRMED |
| CSS approach | **Custom CSS** (hand-written). No Tailwind, no Bootstrap, no framework | CONFIRMED |
| JS framework | **None** — vanilla ES6. No jQuery, React, Vue, etc. | CONFIRMED |
| Build artifacts | None (no bundler output, no minified app code) | CONFIRMED |
| Design tokens | **CSS custom properties** in `:root` | CONFIRMED |
| Icons | **Inline SVG `<symbol>` sprite** (stroke icons, 24×24 viewBox) referenced via `<use>` | CONFIRMED |
| Maps | **Procedurally generated inline SVG** (a `mapSVG()` JS function draws a dark stylized grid map) — no real map provider | CONFIRMED |
| Audio | **WebAudio API** (`AudioContext` + oscillators) — no audio files | CONFIRMED |
| i18n | Runtime **EN / Khmer dictionary** (`I18N` object + `data-i18n` attributes) | CONFIRMED |
| Data | Hard-coded **JS object literals** (trips, transactions, news, referrals, rewards) | CONFIRMED |

**Conclusion:** static-prototype SPA, fully self-contained, no network dependencies for UI rendering.

## 2. File structure (logical)

```
taarraa-driver-prototype (1).html
├── <head>
│   ├── meta viewport (width=device-width, initial-scale=1, viewport-fit=cover)
│   ├── meta theme-color (#101216)
│   └── <style>  — ALL CSS (single block, ~250 lines)
├── <body>
│   ├── <svg> icon sprite — 32 <symbol> definitions (i-home … i-qr)
│   ├── .stage (flex row: prototype sidebar + phone frame)
│   │   ├── .panel (prototype control sidebar — NOT part of app UI)
│   │   └── .phone > .host (device frame — the "app viewport")
│   │       ├── .statusbar (static: 21:47 · 5G · signal · battery)
│   │       ├── section#s-splash   (screen)
│   │       ├── section#s-login    (screen)
│   │       ├── section#s-otp      (screen)
│   │       ├── section#s-register (screen)
│   │       ├── section#s-shell    (screen: app bar + tab body + drawer + overlays)
│   │       ├── section#s-booking  (screen: map + bottom sheet)
│   │       ├── section#s-fee      (screen: receipt + pay-success overlay)
│   │       ├── section#s-hdetail  (screen)
│   │       ├── section#s-newsdetail (screen)
│   │       ├── button#protoFab    (prototype-only jump control — NOT app UI)
│   │       ├── #sheetRoot   (generic bottom sheet + backdrop)
│   │       ├── #dialogRoot  (generic dialog + backdrop)
│   │       └── #toast       (global toast)
│   └── <script>  — ALL application JS (single block)
│       ├── data constants (TRIP, HIST_*, TXS, NEWS, ALERTS, TERMS, REFERRALS, REWARDS)
│       ├── I18N dictionary + applyLang()
│       ├── state object S{} + simulation helpers (later/every/clearSim)
│       ├── toast / openSheet / openDialog helpers
│       ├── WebAudio beep() + 4 sound effects
│       ├── mapSVG() / moveMarker() (procedural map + marker animation)
│       ├── router: jump() / show() / goTab() / NAMES / JUMPS
│       ├── auth: doLogin / OTP / register / photos
│       ├── shell renderers: renderShell + tabHistory/Wallet/Referral/News/Terms/Contact
│       ├── referral: qrSVG / transfer / withdraw
│       ├── booking: startBooking / renderBooking / countdown / stages / meter
│       ├── fee: renderFee / collectPayment
│       ├── history detail: renderHDetail / replayRoute
│       └── demo event handlers (demoRequest, demoPaxCancel, …)
└── <script>  — Cloudflare challenge artifact (see §5)
```

## 3. Top-level DOM structure (semantic)

```
<body>
└── .stage                              # flex row; prototype presentation shell
    ├── .panel                          # PROTOTYPE CONTROL PANEL (not app UI)
    │   ├── header (title + happy-path hint)
    │   ├── #jumpList (screen jump buttons, generated from JUMPS)
    │   ├── demo event buttons (request/cancel/approval/offline/sound/topup/advance/ticker)
    │   ├── row2: language toggle + reset
    │   └── #curName (current screen label)
    └── .phone > .host                  # the simulated mobile device
        ├── .statusbar                  # 21:47 · 5G · ▂▄▆ · 🔋 (static, pointer-events:none)
        ├── [ 9 × <section class="screen"> ]   # the "pages" (see 02-screen-map)
        ├── #protoFab                   # "Prototype" FAB → jump sheet (prototype-only)
        ├── #sheetRoot > .backdrop + .sheet   # generic bottom sheet
        ├── #dialogRoot > .backdrop + .dialog # generic dialog
        └── #toast                      # global toast notification
```

## 4. Screen switching mechanism (the "router")

- Every page is a `<section class="screen">`; CSS keeps them `display:none` and only `.screen.active` is visible (`#s-shell.active` becomes `display:flex`).
- `jump(key)` is the router: clears timers/overlays, deactivates all `.screen`s, activates the target, and re-renders it.
- `key` values come from `NAMES`/`JUMPS` (15 destinations): 9 physical screens + 6 in-shell tabs addressed as `shell:<tab>`.
- `show(id)` is an alias of `jump(id)` used by inline `onclick` handlers.
- `goTab(tab)` = `jump('shell:'+tab)`.
- Screen transition: `.screen.active { animation: fadeUp .28s ease }` (opacity + 10px translateY).

## 5. Artifacts / non-app content (excluded from target-UI analysis)

| Element | Why it's not app UI | Confidence |
| --- | --- | --- |
| `.panel` sidebar | Prototype-only navigation/demo console rendered next to the phone | CONFIRMED |
| `#protoFab` + `openJumps()` sheet | Prototype-only "jump to screen / demo events" control | CONFIRMED |
| `#curName` / `#jumpList` | Prototype-only current-screen indicator and screen list | CONFIRMED |
| Cloudflare script (line 1064) | Copied-page artifact; injects a 1px iframe + challenge script. Not part of the prototype's intent | CONFIRMED (artifact) |
| Static `.statusbar` (21:47, 5G, ▂▄▆, 🔋) | Cosmetic device chrome inside the phone frame; not a functional component | CONFIRMED |

## 6. Architectural summary

- **Map-first shell.** The primary "home" state is a full-bleed dark map with a floating earnings card and a referral-QR FAB; everything else lives in tabs rendered into `#tabBody`.
- **Everything is generated at runtime.** Only the 9 screen shells + icon sprite are in static HTML; tab content (history, wallet, referral, news, terms, contact), booking sheet content, fee receipt, drawer, and dialogs are all built by JS template-literal renderers.
- **Single shared state object `S`** drives online status, approval, trip stage, tab selection, filters, wallet, and counters; all demo events mutate `S` and re-render.
- **Simulation utilities** (`later`, `every`, `clearSim`) manage all timers so navigation can cleanly cancel pending timers/RAF loops.
