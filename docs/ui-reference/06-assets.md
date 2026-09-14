# 06 — Asset Inventory

> The prototype is **fully self-contained**: no external image, font, icon, audio, or data files are loaded. All visual assets are generated inline (SVG/CSS). Confidence: CONFIRMED via grep of the source (no `http(s)://`, `<link>`, `@import`, `@font-face`, `<img>`, `.png/.jpg/.webp/.gif` references).

## 1. Referenced assets table

| Asset | Type | Path / location | Screen | Purpose |
| --- | --- | --- | --- | --- |
| Icon sprite (32 symbols) | Inline SVG `<symbol>` | `<body>` top (`i-home` … `i-qr`) | all | UI icons via `<use>` |
| Logo badge | CSS gradient + star icon | `.logo-badge` (`linear-gradient(135deg,#FF6A00,#FF4500 60%,#C23300)`) | Splash, Contact | brand mark |
| Map (home) | JS-generated SVG (`mapSVG('home',…)`) | `#tabBody` | Home | dark stylized grid map + driver marker + radar |
| Map (booking) | JS-generated SVG (`mapSVG('book',…)`) | `#mapBook` | Booking | route/dash lines, pickup/dest/driver markers |
| Map (history) | JS-generated SVG (`mapSVG('hist',…)`) | `#mapHist` | History detail | static route replay |
| QR code | JS-generated SVG (`qrSVG()`) | `.qr-box` (home fab dialog, referral invite) | Home / Referral | decorative pseudo-QR |
| Avatars | CSS gradients + initials text | `.davatar/.havatar/.pavatar` | Drawer, History, Booking, Fee, Referral | passenger/driver identities |
| Placeholder illustration | CSS gradient `.img-ph` + bell icon | `#newsDetail` | News detail | news image placeholder |
| Audio effects | WebAudio oscillators (no files) | `beep()` | global | request/tick/ok/error sounds |
| Font "Kantumruy Pro" | **Declared, not loaded** | `font-family` (falls back to system stack) | global | body text (falls back in prototype) |
| Cloudflare challenge script | external artifact | line 1064 (relative `/cdn-cgi/...`) | — | copied-page artifact, not app UI |

## 2. Image assets

- **None.** No `<img>`, no background-image, no raster files. All "images" are inline SVG or CSS gradients. CONFIRMED.

## 3. Font assets

- **None bundled.** `"Kantumruy Pro"` is listed first in the font stack but no `@font-face` or `<link>` loads it — the prototype renders with the device's system font stack (which includes Khmer fallbacks `Noto Sans Khmer`, `Khmer OS Siemreap`, `Khmer OS`). UNCLEAR — NEEDS CONFIRMATION: whether the production Flutter app should bundle Kantumruy Pro.

## 4. Icon assets

- 32 inline SVG symbols (24×24, stroke=currentColor, stroke-width 2, round caps/joins). Full list in `04-design-tokens.md §6`.
- 4 symbols are defined but unused: `i-search`, `i-user`, `i-shield`, `i-pin`.

## 5. Data assets (in-code, not files)

| Constant | Content | Used by |
| --- | --- | --- |
| `TRIP` | single active trip (pax, pickup, dest, 3.2 km, code #8821) | booking, fee |
| `HIST_DONE` | 3 completed trips | history |
| `HIST_CANCEL` | 1 cancelled trip | history |
| `TXS` | 5 wallet transactions | wallet |
| `NEWS` | 3 announcements (2 unread) | news |
| `ALERTS` | 3 high-level EN/KM alerts | ticker |
| `TERMS` | 5 terms lines | terms tab |
| `REFERRALS` | 4 referred drivers + top-ups | referral |
| `REWARDS` | 4 reward entries (available/pending) | referral rewards |
| `I18N` | full EN/KM dictionary (~150 keys) | all |
| `S` | runtime state (online, approval, stage, balances…) | global |

## 6. Hard-coded "external-looking" data (business-flavored strings)

These are labels/content only (not real integrations): phone numbers `+855 70 427 213`, `+855 12 285 048`, email `tarataxi24@gmail.com` (contact tab); `Smart`/`Cellcard` carrier names; withdrawal rails `KHQR`/`ABA`/`Wing`; rate `1 USD = ៛4,100`; min transfer `$2.50`; commission 12% (news text). All are prototype content, NOT API calls.
