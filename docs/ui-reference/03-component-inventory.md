# 03 — Component Inventory

> Classification: **REUSED** = same CSS classes used in ≥2 places (or a shared render function); **VISUALLY SIMILAR** = same look achieved with duplicated markup/CSS. Each component lists its DOM structure, CSS classes, variants, states, interactions, and consumers.

## 1. Shared primitives (reused)

### Button — `.btn`
- **Purpose:** primary full-width CTA.
- **HTML:** `<button class="btn">…</button>`, flex row, optional `<svg class="ic">` + label.
- **CSS classes:** `.btn`, variants `.green`, `.ghost`, `.danger-ghost`, `.sm`; disabled via `[disabled]` (`.btn:disabled`).
- **Variants:** default (brand gradient, white text), green (success gradient), ghost (surface2 + border), danger-ghost (red tint), small (`.sm` 46px).
- **States:** default, `:active` (scale .97), `:disabled` (surface2/muted, no shadow).
- **Interactions:** `onclick` handlers wired per instance (login, accept, arrive, start, drop, pay, withdraw, transfer, submit…).
- **Used by:** login, register, booking sheet (all stages), fee, referral, withdraw sheet, dialogs, approval overlay. REUSED.

### Text button — `.tbtn` / `.link`
- **Purpose:** secondary/inline text action.
- **HTML:** `<button class="tbtn">` (padding 12px) or `<button class="link">`.
- **States:** default only (no explicit hover/disabled).
- **Used by:** "Skip →" (splash), OTP "New driver? Register", resend link, booking cancel, dialog "Cancel". REUSED (two near-identical classes).

### Icon button — `.icon-btn`
- **Purpose:** square icon action with optional notification dot.
- **HTML:** `<button class="icon-btn"><svg class="ic"><use …/></svg></button>`; optional `<span class="dot">` child.
- **States:** default; `:active` scale.
- **Interactions:** inline `onclick` (back, menu/drawer, refresh, call passenger).
- **Used by:** OTP back, register back, shell menu, history refresh, wallet refresh, history/news detail back, booking call-passenger. REUSED.

### Field / Input — `.field`
- **Purpose:** labeled input/select container.
- **HTML:** `<div class="field">[<span class="prefix">] <input|select> </div>`; label is a sibling `.lbl`.
- **CSS:** 54px height, surface bg, 1.5px `--line` border, radius 14px; `:focus-within` → brand border; `.prefix` right border.
- **States:** default, `:focus-within` (brand border), select options styled dark.
- **Used by:** login phone (`+855` prefix), register (name, vehicle select, color, plate), withdraw amount. REUSED.

### Badge / status pill — `.badge`
- **Purpose:** small status label.
- **HTML:** `<span class="badge green">…</span>`.
- **Variants (colors):** `.green`, `.red`, `.amber`, `.orange`, `.blue`, `.grey` (each a dim bg + colored text).
- **Used by:** earn-card status, history cards, referral rows, rewards, wallet, fee receipt, drawer online badge. REUSED.

### Avatar — `.davatar` / `.havatar` / `.pavatar`
- **Purpose:** circular initials avatar.
- **HTML:** `<div class="havatar">ML</div>` etc.
- **Sizes:** 54px (`.davatar` drawer), 44px (`.havatar` history), 48px (`.pavatar` booking).
- **Gradients:** `.davatar`/`.havatar` = orange→purple `linear-gradient(135deg,#FF6A00,#B73CFF)`; `.pavatar` = blue→purple `linear-gradient(135deg,#2F6BFF,#7A5CFF)`.
- **Used by:** drawer profile, history list, history detail, booking passenger row, fee receipt, referral list. REUSED (3 size variants).

### Icon — `.ic`
- **Purpose:** sprite icon.
- **HTML:** `<svg class="ic [sm|lg|fill]"><use href="#i-…"/></svg>`.
- **Sizes:** 22px default, `.sm` 16px, `.lg` 28px; `.fill` switches stroke→fill.
- **Used by:** everywhere. REUSED.

### Segmented control — `.seg`
- **Purpose:** 2-option pill toggle.
- **HTML:** `<div class="seg"><button class="on">…</button><button>…</button></div>`.
- **States:** `.on` (surface bg, text color, shadow).
- **Used by:** login language (EN/ខ្មែរ), drawer language. REUSED.

### Tabs — `.tabs`
- **Purpose:** content filter tabs (history completed/cancelled; referral invite/referrals/rewards).
- **HTML:** `<div class="tabs"><button class="on">…</button>…</div>`.
- **Used by:** history, referral. REUSED.

### Chip — `.chip`
- **Purpose:** filter/tag button.
- **States:** `.on` (brand border + dim bg).
- **Used by:** wallet transaction filter (All/In/Out), withdraw rail select (KHQR/ABA/Wing), referral copy-code button. REUSED.

### Steps indicator — `.steps`
- **Purpose:** progress dots for multi-step auth.
- **HTML:** `<div class="steps"><i class="on"></i><i></i><i></i></div>`.
- **Used by:** login (step1), OTP (step2), register (step3). REUSED.

### Address row — `.addr-row`
- **Purpose:** pickup/destination line with dot marker.
- **HTML:** `<div class="addr-row"><span class="dot-pickup|dot-dest"></span><div><div class="t1">…</div><div class="t2">…</div><div class="t3">…</div></div></div>`.
- **Used by:** booking sheet (all stages), fee receipt. REUSED.

### Key-value row — `.kv`
- **Purpose:** label-left / value-right line.
- **HTML:** `<div class="kv"><span>Label</span><b>Value</b></div>`.
- **Used by:** booking sheet, fee receipt, history detail, transfer dialog, referral detail sheet. REUSED.

### Divider — `.divider` / `.dash`
- **Purpose:** horizontal rule (solid 1px `--line`, or dashed 2px).
- **Used by:** drawer, fee receipt (`.dash`). REUSED.

### Toast — `#toast`
- **Purpose:** transient global notification (light surface, dark text, green check icon).
- **JS:** `toast(msg)` → show 2.4s.
- **Used by:** 40+ call sites. REUSED.

### Bottom sheet — `#sheetRoot` + `.sheet`
- **Purpose:** generic bottom sheet (grab handle + injected HTML).
- **JS:** `openSheet(html)`, `closeSheet()`.
- **Used by:** referral detail, withdraw, prototype jump sheet. REUSED.

### Dialog — `#dialogRoot` + `.dialog`
- **Purpose:** centered modal (injected HTML).
- **JS:** `openDialog(html)`, `closeDialog()`; Escape key closes.
- **Used by:** logout, cancel-request, passenger-cancel, QR, transfer, approval-rejected/appeal. REUSED.

### Card — `.card`
- **Purpose:** surface container.
- **HTML:** `<div class="card">…</div>` (radius `--r-l`, surface bg, 1px line border, 16px padding).
- **Used by:** history detail, news detail, referral summary/how-it-works/rules. REUSED.

### App bar — `.appbar`
- **Purpose:** title + optional leading icon button.
- **Used by:** s-fee, s-hdetail, s-newsdetail (static); shell has its own `.shell-appbar`. REUSED (3 static instances + 1 shell variant).

### Mini-map — `.minimap`
- **Purpose:** small static route map (200px) with overlay layer.
- **Used by:** history detail. REUSED (single use — near-duplicate of full map concept).

### List rows
- `.hcard` (history card) — REUSED by history list & referral list.
- `.tx` (transaction row) — REUSED by wallet list, referral detail sheet, rewards list.
- `.news` (news card) — news list only.
- `.prow` (profile/contact row) — contact tab only.
- `.term` (numbered terms row) — terms tab + referral "how it works" steps. REUSED.
- `.wal-card` (wallet stat card) — wallet + referral rewards. REUSED.

## 2. Compound / screen-specific components

| Component | Purpose | Notes |
| --- | --- | --- |
| `.logo-badge` | Brand mark (gradient rounded square + star) | Used on splash & contact tab |
| `.count-ring` | Request-accept countdown (30s SVG arc + secs) | booking only; `.warn` turns amber ≤10s |
| `.status-pill` (`.st-req`/`.st-go`/`.st-carry`) | Live trip status pill with pulsing dot | booking only |
| `.timeline` / `.tstep` | 4-step trip progress (Accept→Arrive→Start→Drop) | booking only; states `.on`/`.done` |
| `.fare-strip` | Live meter (time / distance / fare) | booking stage 3 only |
| `.receipt` + `.total-box` | Payment breakdown + total | fee screen |
| `.check-big` | Success check circle | pay-success overlay |
| `.earn-card` | Today's earnings floating card | home tab |
| `.qr-fab` + `.qr-box` | Referral QR (procedurally drawn SVG) | home + referral + QR dialog |
| `#ticker` | Scrolling alerts marquee (`.tick-*`) | shell, under app bar |
| `.photo-slot` / `.photo-grid` | Document upload slots (2×2) | register; `.done` state |
| `.otp` / `.otp-row` | 4 single-digit OTP inputs | OTP screen |
| `.boot-steps` | Splash boot log | splash |
| `.drow-menu` | Drawer navigation item | drawer |
| `.pax-row` | Passenger row (avatar + name + rating + call btn) | booking sheet, fee receipt |
| `.est-note` | "≈ estimated" amber note | booking stage 3 |

## 3. Truly reused vs visually similar

- **Truly reused (shared classes + often shared render functions):** `.btn`, `.icon-btn`, `.badge`, `.chip`, `.tabs`, `.card`, `.kv`, `.addr-row`, `.hcard`, `.tx`, `.wal-card`, `.field`, `.seg`, `.steps`, `.term`, `.pax-row`, `.ic`, avatars (3 size variants), toast/sheet/dialog.
- **Visually similar but separate implementations:** the three avatars (`.davatar`/`.havatar`/`.pavatar`) differ only by size/gradient; the app bars (`.appbar` vs `.shell-appbar`) are separate; `.mapwrap` appears in both home and booking but map content is generated by the same `mapSVG()` helper.

## 4. Components NOT present (no evidence in code)

- No bottom navigation bar component exists.
- No pull-to-refresh, no swipe gestures, no drag-to-dismiss sheets (backdrop-only dismissal).
- No search input (the `i-search` icon is defined but unused).
- No pagination / infinite scroll / skeleton loaders.
