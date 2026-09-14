# 04 — Design Tokens

> All values are copied exactly from the prototype's `<style>` block (CSS variables in `:root` unless noted). Confidence: CONFIRMED (verbatim values).

## 1. Color palette

### Core variables (defined in `:root`)

| Token | CSS var | HEX | RGB | Role |
| --- | --- | --- | --- | --- |
| Background | `--bg` | `#101216` | 16,18,22 | app background (dark) |
| Surface | `--surface` | `#1B1E25` | 27,30,37 | cards/sheets/inputs |
| Surface 2 | `--surface2` | `#262B36` | 38,43,54 | raised elements, chips bg, disabled |
| Line / border | `--line` | `#333948` | 51,57,72 | borders, dividers, grab handle |
| Text | `--text` | `#F2F3F7` | 242,243,247 | primary text |
| Sub-text | `--sub` | `#A7AEC0` | 167,174,192 | secondary text |
| Muted | `--muted` | `#6E7688` | 110,118,136 | tertiary text, placeholders |
| Brand | `--brand` | `#FF4500` | 255,69,0 | primary (orangered) |
| Brand 2 | `--brand2` | `#FF6A00` | 255,106,0 | gradient top / accent |
| Brand dim | `--brand-dim` | `rgba(255,69,0,.16)` | — | brand tint backgrounds |
| Green | `--green` | `#25E08A` | 37,224,138 | success / money / online |
| Green dim | `--green-dim` | `rgba(37,224,138,.14)` | — | success tint |
| Blue | `--blue` | `#4D9FFF` | 77,159,255 | informational |
| Blue dim | `--blue-dim` | `rgba(77,159,255,.14)` | — | info tint |
| Amber | `--amber` | `#FFB020` | 255,176,32 | warning / pending |
| Amber dim | `--amber-dim` | `rgba(255,176,32,.14)` | — | warning tint |
| Red | `--red` | `#FF5A5A` | 255,90,90 | error / destructive |
| Red dim | `--red-dim` | `rgba(255,90,90,.13)` | — | error tint |

### Hard-coded colors (NOT variables — inline literals)

| Value | Where | Purpose |
| --- | --- | --- |
| `#20232e` | `body` background | page behind phone frame |
| `#000` | `.phone` | device bezel |
| `#262b3a` / `#dfe3ee` / `#9aa3bd` / `#313752` / `#8b93ad` / `#cfd5e8` / `#4a5470` | `.panel` (prototype sidebar) | prototype-only console |
| `#ECEEF4` / `#14161c` | `#toast` | light toast surface + dark text |
| `#12B76A` | `.btn.green` gradient stop + `#toast .ic` | success green (darker than `--green`) |
| `#2BF095` | `.btn.green` gradient start | success green light |
| `#0A7A47` | `.total-box` gradient stop | dark green |
| `#C23300` | `.logo-badge` gradient stop | deep brand |
| `#B73CFF` | avatar gradients | purple accent |
| `#2F6BFF` / `#7A5CFF` | `.pavatar` gradient | passenger avatar blue→purple |
| `#F5A623` | star icon fill (rating) | rating gold |
| `#FFD58A` / `#FF8A8A` / `#5A2A20` | `#ticker` text/border | alert marquee |
| `#FF8A3D` / `#3A1C08` / `#7A3A12` | `.st-req` status pill | "New request" pill (orange) |
| `#6FB3FF` / `#0E2A4D` / `#1D4E86` | `.st-go` status pill | "Go to pickup" pill (blue) |
| `#3FEC9E` / `#0B3524` / `#166B45` | `.st-carry` pill, `.fare-strip`, wallet balance card | on-trip / money (green) |
| `#3A1114` / `#FF8A8A` | `#offlineBar` | offline banner |
| `#14171E` / `#1B2029` / `#1C3327` / `#20392C` / `#1D3A55` / `#2E4E73` / `#262C38` / `#39424F` / `#414B5E` / `#8B93A8` | `mapSVG()` | procedural map fills/strokes |
| `#D32F2F` | booking stage-3 "Drop off" inline gradient | destructive drop button |
| `#0E3A26` / `#2A1508` / `#3A2E08` / `#7A5F12` | `.wal-card` / referral gradients | stat card gradients |

**Semantic mapping (as used in the app):**

- primary/brand = `--brand`/`--brand2` (orange)
- success/money/online = `--green` (+ darker `#12B76A`/`#3FEC9E` family)
- warning/pending = `--amber`
- error/destructive = `--red`
- info/transit = `--blue`
- neutral text hierarchy = `--text` → `--sub` → `--muted`
- neutral surfaces = `--bg` → `--surface` → `--surface2`

## 2. Typography

### Font family (CONFIRMED — no `@font-face`, no external font loaded)

```
font-family: "Kantumruy Pro", -apple-system, BlinkMacSystemFont, "Segoe UI",
             Roboto, "Noto Sans Khmer", "Khmer OS Siemreap", "Khmer OS", sans-serif;
```
`"Kantumruy Pro"` is declared first but **not bundled/loaded** — in practice it will fall back to the system stack (UNCLEAR whether the production app ships Kantumruy Pro; prototype does not include it).

### Sizes & weights in use (semantic grouping, evidence-based)

| Role | Selector | Size / weight / notes |
| --- | --- | --- |
| Display / screen title | `h1` | 24px, margin 18/6, letter-spacing −0.2px (weight inherited ~bold) |
| Splash name | `.splash-name` | 30px / 800 / letter-spacing 3px |
| Section title | `h2` | 17px |
| Dialog title | `.dialog h3` | 18px |
| Body | base `body` | default (16px), color `--text` |
| Body-secondary | `.dialog p`, `.news p` | 14px, `--sub`, line-height 1.55–1.65 |
| Label | `.lbl` | 13px / 700 / `--sub` |
| Field text | `input,select,textarea` | 15px |
| Button | `.btn` | 16px / 800 |
| Small button | `.btn.sm` | 14px |
| Text button | `.tbtn` | 15px / 800 |
| Link | `.link` | 14px / 700 |
| Caption / meta | `.tiny` | 12px |
| Muted meta | `.tiny.muted`, `.hmeta`, `.dt` | 12px, `--sub`/`--muted` |
| Badge | `.badge` | 12px / 800 |
| Micro label | `.t1` (addr label), `.grp` | 11px / 800, uppercase |
| Amount (large) | `.earn-card .amt`, `.total-box b` | 24px / 30px, 800 |
| OTP digit | `.otp` | 26px / 800 |
| Numeric alignment | `.mono` | `font-variant-numeric: tabular-nums; letter-spacing:.2px` |

### Line height
- `.dialog p`: 1.55; `.news p`: 1.55; `.term`: 1.6; `.newsdetail p`: 1.65; `.panel .sub`: 1.65. No global line-height is set.

### Letter spacing
- `h1`: −0.2px; `.splash-name`: 3px; `.shell-title`: 1.5px; `.shell-title small`: 2px; `.mono`: 0.2px; `.t1`/`.grp`: 0.5px / 1px (uppercase).

## 3. Spacing scale

Observed values (no formal scale variable; values recur consistently):

| Value | Usage examples |
| --- | --- |
| 4px | minor gaps (`.term` inner, paddings) |
| 6px | `#ticker` margin, steps gap |
| 8px | button gap, `.chips` gap, timeline inner |
| 10px | field gap, avatar gaps, `.wal-grid`/`.photo-grid` gap |
| 12px | appbar gap, divider margin, receipt padding |
| 14px | appbar margin-bottom, field/input padding, badge padding |
| 16px | card padding, section padding |
| 20px | screen horizontal padding, dialog/sheet padding |
| 26px | sheet bottom padding |
| Screen padding | `.screen { padding: 46px 20px 20px }` (top reserved for status bar) |
| Shell padding | `#s-shell { padding: 46px 0 0 }`; `.scroll { padding: 6px 16px 26px }` |
| Sheet padding | `.sheet { padding: 12px 20px 26px }` |
| Dialog padding | `.dialog { padding: 22px }` |

## 4. Border radius (variables + literals)

| Radius | CSS var / literal | Where |
| --- | --- | --- |
| small | `--r-s: 8px` | (defined; rarely used directly) |
| medium | `--r-m: 12px` | drawer rows, referral steps, tabs-inner, `.hroute`, `.tick-item` |
| large | `--r-l: 16px` | cards, wallet cards, receipt, news, minimap, earn-card |
| xl | `--r-xl: 20px` | dialog |
| button | `14px` (`.btn`, `.field`, `.otp`, `.tx`, `.pax-row`, `.addr` rows) | primary controls/inputs |
| icon-btn | `12px` | `.icon-btn` |
| badge/pill | `99px` | pills, chips, avatar, segments, count-ring, grab handle, timer |
| sheet | `22px 22px 0 0` (top corners) | `.sheet`, `.bsheet` |
| logo | `28px` (splash) / `20px` (contact) | `.logo-badge` |
| phone frame | `44px` (bezel) / `34px` (host) | `.phone` / `.host` |

## 5. Shadows / elevation

| Token | Value | Where |
| --- | --- | --- |
| `--sh` | `0 10px 30px rgba(0,0,0,.45)` | dialog, toast, trip-card, status-pill, count-ring, earn-card, offline bar, protoFab |
| Button (brand) | `0 8px 22px rgba(255,69,0,.35)` | `.btn` |
| Button (green) | `0 8px 22px rgba(37,224,138,.3)` | `.btn.green` |
| Button (drop/red inline) | `0 8px 22px rgba(255,90,90,.3)` | stage-3 drop button (inline) |
| Logo glow | `0 16px 40px rgba(255,69,0,.45)` | `.logo-badge` |
| QR FAB | `0 8px 22px rgba(255,69,0,.45)` + animated ring | `.qr-fab` |
| Sheet (bottom) | `0 -12px 34px rgba(0,0,0,.5)` | `.bsheet` |
| Seg/tab selected | `0 2px 6px rgba(0,0,0,.4)` | `.seg button.on`, `.tabs button.on` |
| Timeline step (on) | `0 4px 10px rgba(255,69,0,.4)` | `.tstep.on .td` |
| Total box (green) | `0 8px 22px rgba(37,224,138,.25)` | `.total-box` |
| Phone frame | `0 30px 80px rgba(0,0,0,.5)` | `.phone` |
| Online pill glow | `0 0 10px var(--green)` (animated pulse) | `#onlinePill.on .cdot` |

## 6. Icons

- **Library:** none — **32 hand-authored inline SVG `<symbol>`s**, 24×24 viewBox, stroke-based (`fill:none; stroke:currentColor; stroke-width:2; round caps/joins`), consumed via `<svg class="ic"><use href="#i-…"/></svg>`.
- **Defined symbols:** `i-home, i-cal, i-user, i-bell, i-back, i-search, i-phone, i-star, i-x, i-locate, i-shield, i-chev, i-pin, i-car, i-clock, i-route, i-check, i-globe, i-out, i-doc, i-mail, i-cam, i-menu, i-wallet, i-vol, i-volx, i-grid, i-warn, i-info, i-refresh, i-gift, i-qr`.
- **Defined but NOT referenced anywhere (dead):** `i-search`, `i-user`, `i-shield`, `i-pin` (CONFIRMED via usage grep).
- **Dynamic usage** (icon chosen at runtime): drawer items (`#i-home/#i-cal/#i-wallet/#i-gift/#i-bell/#i-doc/#i-mail`), photo slots (`#i-check/#i-cam`), sound toggle (`#i-vol/#i-volx`), referral detail (`#i-check/#i-x`).
- Icon color is inherited from `currentColor`; size via `.ic` (22px) / `.ic.sm` (16px) / `.ic.lg` (28px).
- Emoji are also used for icons in places: `🔔 🚫 🛡️ 📡 🔊 💸 ⏩ 📢 🌐 ↺ 📞 💳 📅 🟢 ⚫ ✅ ⏱ ✉️ 📍 🎉 💰 ⛈️ 🌊 ✦` (drawer/panel/ticker/demo texts). CONFIRMED.
