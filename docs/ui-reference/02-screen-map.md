# 02 — Screen Map & Navigation

> All IDs, entry/exit paths, and relationships below are taken directly from the HTML/JS (`NAMES`, `JUMPS`, `jump()`, `goTab()`, inline `onclick`, and render functions).

## 1. Classification legend

- **SCREEN** — full-page destination (a `<section class="screen">`)
- **TAB** — destination inside the Shell screen (`#tabBody`)
- **OVERLAY** — full-screen layer over a screen (approval, pay-success)
- **BOTTOM SHEET** — `.sheet` inside `#sheetRoot`, or `.bsheet` (booking), or the drawer
- **DIALOG** — `.dialog` inside `#dialogRoot`
- **TOAST** — transient notification (`#toast`)
- **COMPONENT** — reusable piece (documented in 03, not a destination)

## 2. Screen inventory

| ID | Screen / State | Type | Source | Entry | Exit | Key components |
| --- | --- | --- | --- | --- | --- | --- |
| `s-splash` | Splash / boot | SCREEN | static `<section>` | initial `jump('s-splash')`; boot steps then auto-advance | auto-advance after 2.6s → `s-login`; manual "Skip →" → `s-login` | `.splash-logo`, `.logo-badge`, `#bootSteps` |
| `s-login` | Login (phone entry) | SCREEN | static | from splash (auto/skip); from logout dialog; back from OTP | valid phone → `s-otp` | `.steps`, `.seg` (lang), `.field` phone, `#phoneErr`, CTA |
| `s-otp` | OTP verification | SCREEN | static | from login (valid phone) | 4 digits entered → `shell:home`; back → `s-login`; "New driver?" → `s-register` | 4× `.otp` inputs, `#otpTimer`, resend |
| `s-register` | Driver registration | SCREEN | static | from OTP ("New driver? Register") | submit → `shell:home` (+ approval pending); back → `s-otp` | fields, `.photo-grid` (4 slots), CTA |
| `s-shell` | App shell (5+ tabs) | SCREEN | static | post-OTP / post-register / booking cancel / pay-success | logout → `s-login` | shell appbar, `#tabBody`, drawer, ticker, offline bar, approval overlay |
| `shell:home` | Home (map) | TAB | rendered into `#tabBody` | default tab after login; `goTab('home')` | other tab / booking | full-bleed map, `.earn-card`, `.qr-fab` |
| `shell:history` | Riding History | TAB | rendered | drawer item / jump | `s-hdetail` (tap card); other tab | `.tabs`, `.hcard` list |
| `shell:wallet` | My Wallet | TAB | rendered | drawer item / jump | withdraw sheet | `.wal-grid` cards, withdraw btn, `.chips`, `.tx` list |
| `shell:referral` | Refer & Earn | TAB | rendered | drawer item / jump | detail sheet, transfer dialog, QR dialog | summary card, 3 sub-tabs, QR, lists |
| `shell:news` | Announcements | TAB | rendered | drawer item / jump / ticker tap | `s-newsdetail` (tap card); other tab | `.news` cards |
| `shell:terms` | Terms & Conditions | TAB | rendered | drawer item / jump | other tab | numbered `.term` rows |
| `shell:contact` | Contact Us | TAB | rendered | drawer item / jump | other tab | `.prow` rows (phone/email) |
| `s-hdetail` | History detail | SCREEN | static | tap `.hcard` in history → `jump('s-hdetail')` | back → `shell:history` | mini-map, `.card` detail, replay btn |
| `s-newsdetail` | News detail | SCREEN | static | tap `.news` card → `jump('s-newsdetail')` | back → `shell:news` | `.card` body + image placeholder |
| `s-booking` | Booking · live trip | SCREEN | static | demo "New request", auto 4.5s after going online, or jump | Accept→Arrived→Start→Drop → `s-fee`; cancel → `shell:home`; expiry → `shell:home` | map, `#bookStatus`, `.count-ring`, `.bsheet`, `.timeline` |
| `s-fee` | Collect payment | SCREEN | static | drop-off from booking (`jump('s-fee')`) | confirm → `shell:home` (auto 1.6s) | receipt, `.total-box`, CTA, `#paySuccess` overlay |

## 3. Overlays / sheets / dialogs

| ID / anchor | Type | Purpose | Entry | Exit |
| --- | --- | --- | --- | --- |
| `#drawerRoot` (`.drawer`) | BOTTOM SHEET-like side drawer | profile + navigation | `openDrawer()` (menu btn) | `closeDrawer()` (backdrop, nav) |
| `#sheetRoot` (`.sheet`) | BOTTOM SHEET (generic) | referral detail, withdraw, jump sheet | `openSheet(html)` | `closeSheet()` (backdrop, Escape) |
| `#dialogRoot` (`.dialog`) | DIALOG (generic) | logout, cancel request, passenger-cancel, QR, transfer, approval | `openDialog(html)` | `closeDialog()` / buttons / Escape |
| `#approvalOv` | OVERLAY (full-screen) | pending / rejected approval states over shell | `S.approval` set + `renderApproval()` | none (persists until demo cycles state) |
| `#paySuccess` | OVERLAY (full-screen) | payment-confirmed state | `collectPayment()` | auto-hide 1.6s → home |
| `#toast` | TOAST | transient feedback | `toast(msg)` everywhere | auto-hide 2.4s |
| `#offlineBar` | OVERLAY (floating pill) | "No internet — reconnecting…" | `demoOffline()` / `S.offline` | toggle off |
| `#ticker` | OVERLAY (inline bar) | live announcements marquee | `S.tickerOn` | toggle off |

## 4. Screen map table (concise)

| ID | Screen | Type | Source | Entry | Exit | Key components |
| -- | ------ | ---- | ------ | ----- | ---- | -------------- |
| S01 | Splash | SCREEN | static | app start | auto 2.6s / Skip | logo-badge, boot steps |
| S02 | Login | SCREEN | static | splash, logout, back | Next → OTP | phone field, steps, lang seg |
| S03 | OTP | SCREEN | static | login | 4 digits → home | otp-row, timer, resend |
| S04 | Register | SCREEN | static | OTP link | submit → home | photo-grid, vehicle form |
| S05 | Shell·Home | TAB | render | post-auth | tabs / booking | map, earn-card, QR fab |
| S06 | Shell·History | TAB | render | drawer / tabs | detail | hcard list, tabs |
| S07 | Shell·Wallet | TAB | render | drawer | withdraw sheet | wal-grid, tx list |
| S08 | Shell·Referral | TAB | render | drawer | sheets/dialogs | QR, sub-tabs, lists |
| S09 | Shell·News | TAB | render | drawer / ticker | detail | news cards |
| S10 | Shell·Terms | TAB | render | drawer | tabs | term rows |
| S11 | Shell·Contact | TAB | render | drawer | tabs | contact rows |
| S12 | History detail | SCREEN | static | history card | back | minimap, replay |
| S13 | News detail | SCREEN | static | news card | back | card + img-ph |
| S14 | Booking · trip | SCREEN | static | demo/online | s-fee / home | map, sheet, countdown |
| S15 | Collect payment | SCREEN | static | drop-off | home | receipt, total-box |

## 5. Navigation graph (Mermaid)

```mermaid
flowchart TD
    subgraph Auth
        A["s-splash<br/>(auto→ s-login)"]
        B["s-login"]
        C["s-otp"]
        D["s-register"]
    end

    subgraph Shell ["s-shell"]
        H["shell:home (map)"]
        HY["shell:history"]
        W["shell:wallet"]
        R["shell:referral"]
        N["shell:news"]
        T["shell:terms"]
        CT["shell:contact"]
    end

    subgraph Detail
        HD["s-hdetail"]
        ND["s-newsdetail"]
    end

    subgraph Trip
        BK["s-booking"]
        F["s-fee"]
    end

    A -->|auto / Skip| B
    B -->|valid phone| C
    B -->|logout dialog| B
    C -->|4 digits| H
    C -->|back| B
    C -->|"New driver?"| D
    D -->|submit| H

    H -->|goOnline + 4.5s / demoRequest| BK
    BK -->|Accept→Arrive→Start→Drop| F
    BK -->|expired / cancel / pax-cancel| H
    F -->|confirm (1.6s)| H

    H <-->|drawer / goTab| HY
    H <-->|drawer| W
    H <-->|drawer| R
    H <-->|drawer| N
    H <-->|drawer| T
    H <-->|drawer| CT

    HY -->|tap card| HD
    HD -->|back| HY
    N -->|tap card| ND
    ND -->|back| N
    N -->|ticker tap| N

    H -->|logout dialog| B
```

### Notes on navigation (evidence-based)

- Tab switches are a **star topology** centered on the drawer and `goTab()`; there is **no bottom navigation bar**. The drawer (`.drawer`) is the only in-app navigation menu.
- `s-booking` is entered from the shell home (demo or going online), never from tabs directly (jump list is prototype-only).
- The booking flow is strictly **driver-driven**: `Accept → I've arrived → Start ride → Drop off`. There is no auto-advance in the happy path (comment in source: "transitions (driver-driven only — no auto-advance)").
- The only "back" navigation in-app is: history detail → history, news detail → news, and OTP/register back buttons. Other screens rely on the drawer/shell.

## 6. Related screens (edge list)

- `s-splash` → `s-login`
- `s-login` ⇄ `s-otp`; `s-otp` → `s-register`; `s-otp` → `shell:home`; `s-register` → `shell:home`
- `shell:*` ⇄ each other via drawer
- `shell:history` → `s-hdetail`; `shell:news` → `s-newsdetail`; ticker → `shell:news`
- `shell:home` ⇄ `s-booking`; `s-booking` → `s-fee`; `s-fee` → `shell:home`
- logout dialog → `s-login`
