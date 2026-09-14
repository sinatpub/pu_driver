# 05 — Interactions & UI States

> Every interaction below is traced to actual code (inline `onclick`, `addEventListener`, or the router). Where the prototype only simulates something (no real backend/network), that is stated explicitly.

## 1. Interaction inventory

### 1.1 Splash / boot
```
App load
  ↓ jump('s-splash')  → boots[] lines appended every ~600ms (location→session→ready)
  ↓ after 2.6s (or "Skip →" click)  → jump('s-login')
```

### 1.2 Login
```
Next button click (or Enter in input)
  ↓ doLogin(): strip non-digits; if length < 8 → error text + .shake on field + error beep
  ↓ valid → otpPhone label = "+855 <digits>" → jump('s-otp') → startOtp()
```
- Validation: **min 8 digits** only (regex `\D` stripped; no format check beyond length). Error shown in `#phoneErr`.

### 1.3 OTP
```
4 single-digit inputs: auto-advance focus on input; Backspace moves back
  ↓ all 4 filled → success beep → 700ms later goTab('home') + welcome toast
Countdown 60s (startOtp → every 1s) → at 0: hide timer, show "Send again" (resendOtp restarts)
```
- OTP accepts **any 4 digits** (demo note on screen: "type any 4 digits").

### 1.4 Registration
```
Name input (oninput) → renderPhotos() re-evaluates button enable
Photo slots (4) click → togglePhoto(i) toggles S.photos[i], renders .done state, tick sound + toast
Submit button: disabled until name.trim().length ≥ 2 AND all 4 photos done
  ↓ finishRegister(): S.approval='pending' → goTab('home') + toast
```
- Validation logic is **CONFIRMED in JS**: name ≥ 2 chars + 4/4 photos → enable. No server check.

### 1.5 Online toggle (shell)
```
#onlinePill click → toggleOnline():
  - if S.approval !== 'none' → toast "Waiting for approval" + error beep (blocked)
  - if going online while S.offline → "No internet" toast (blocked)
  - else S.online toggles → pill restyles → re-render shell
      online ON  → success beep + toast, then after 4.5s startBooking(false) (incoming request)
      online OFF → toast "OFFLINE"
```

### 1.6 Drawer (navigation)
```
menu icon → openDrawer() renders profile + 7 nav items + online/sound/language/logout
item click → goTab('x')  (jump('shell:x')) → closeDrawer
backdrop click → closeDrawer()
```
- Drawer is the only app navigation menu (no bottom bar).

### 1.7 Booking flow (state machine)
```
Incoming request → startBooking(): S.stage=0, toast + request beep, 30s countdown ring
Stage 0 (New request)  → Accept button → acceptRide(): stage=1, marker animates to pickup (8s), toast
                       → Cancel → askCancelReq() dialog → Yes: stop countdown, goTab('home')
                       → 30s expires → toast "Request expired", goTab('home')
Stage 1 (Go to pickup) → "I've arrived" → arriveRide(): stage=2, toast
Stage 2 (At pickup)    → "Start ride" → startRide(): stage=3, marker animates along route (26s), startMeter()
Stage 3 (On trip)      → live meter (time/dist/fare update each 1s) → "Drop off" → dropRide(): compute fare → jump('s-fee')
```
- **Driver-driven only — no auto-advance** (source comment). Each transition is an explicit button tap.
- Passenger cancel (demo) → dialog with auto-dismiss progress bar (10s) → goTab('home').

### 1.8 Payment (s-fee)
```
renderFee(): receipt + server fare (estFare(dist) × 1.04 rounded to 100s)
"Payment done" → collectPayment(): S.paid=true, success beep, #paySuccess overlay
  ↓ 1.6s → earnings += fare, tripsToday++, hide overlay, goTab('home')
```

### 1.9 History / detail
```
History tab: completed/cancelled tabs filter (S.histTab) → re-render
Tap card → jump('s-hdetail') (always shows HIST_DONE[0] — hardcoded)
"Replay route" → moveMarker() animates hist-driver along 3 points (5s) + toast
Refresh icon → toast "↻ Refreshed" (no data change)
```

### 1.10 Wallet
```
Filter chips (All/In/Out) → S.txFilter → re-render
Withdraw button → openSheet(): amount input (prefilled balance) + rail chips (KHQR/ABA/Wing)
Confirm → doWithdraw(): parse int; if ≤0 or > balance → "Insufficient" toast + error beep
          else balance -= amount, prepend tx, closeSheet, success toast, re-render
```

### 1.11 Referral
```
Sub-tabs (Invite / Referrals / Rewards)
Invite: QR (procedurally drawn), code + Copy (toast + tick), Share (toast only)
Referrals: tap row → openSheet() top-up history
Rewards: Transfer button (disabled unless available ≥ $2.50) → dialog with rate (1 USD = ៛4,100),
         fee free → Confirm → doTransfer(): mark rewards transferred, wallet += amount, prepend tx
```

### 1.12 News
```
Tap card → openNews(): marks unread=0, renders detail, jump('s-newsdetail')
Ticker (under appbar) → click → goTab('news')
```

### 1.13 Dialog / sheet / toast / keyboard
- `Escape` key closes sheet + dialog + drawer.
- Toast auto-hides after 2.4s (single shared timer).
- `document.addEventListener('pointerdown', …, {once:true})` lazily unlocks the WebAudio context (autoplay policy).

### 1.14 Sounds (WebAudio, no files)
| Effect | Triggers | Waveform |
| --- | --- | --- |
| `sndRequest` | incoming request, topup demo | 3 rising sine beeps (660/880/990Hz) |
| `sndTick` | photo attach, copy, countdown ≤10s | 1200Hz square |
| `sndOk` | OTP complete, accept/arrive/start/pay/withdraw/transfer/online | ascending sine (523/659/784Hz) |
| `sndErr` | invalid phone, offline/approval block, cancel | 180Hz sawtooth |

## 2. UI states (explicitly represented)

### Screen-level
| State | Where | Visual difference | Trigger | Available actions |
| --- | --- | --- | --- | --- |
| Splash boot | `s-splash` | logo pop-in + boot log lines | app load | Skip |
| Login error | `#phoneErr` + `.field.shake` | red text + shake animation | invalid phone | retry |
| OTP countdown / resend | `#otpTimer`, `#resendBtn` | timer pill; resend appears at 0 | 60s timer | resend |
| Register photo done | `.photo-slot.done` | dashed→solid green border, green text | photo toggle | remove (toggle) |
| Register submit disabled | `.btn:disabled` | grey surface, no shadow | name/photos incomplete | (none) |
| Approval **pending** | `#approvalOv` | amber clock icon + "Waiting for admin approval" | register submit / demo | "Contact support" |
| Approval **rejected** | `#approvalOv` | red X icon + reason text | demo | "Contact support" |
| Online | `#onlinePill.on` | green pill + pulsing dot, "ONLINE" | toggle | go offline |
| Offline (default) | `#onlinePill` | grey pill, "OFFLINE" | toggle | go online |
| Offline (network) | `#offlineBar` | floating red pill "No internet — reconnecting…" | demo | blocks going online |
| Booking stage 0 | `#s-booking` | "New request" orange pill + countdown ring | incoming request | Accept / Cancel |
| Booking stage 1 | `#s-booking` | "Go to pickup" blue pill | Accept | I've arrived |
| Booking stage 2 | `#s-booking` | "At pickup" blue pill | Arrive | Start ride |
| Booking stage 3 | `#s-booking` | "On trip" green pill + live fare strip | Start | Drop off |
| Countdown warn | `.count-ring.warn` | amber seconds + tick sound ≤10s | timer | — |
| Payment success | `#paySuccess` | green check circle overlay | confirm payment | auto-return |
| Passenger-cancel | dialog | red emoji title + auto progress bar | demo | OK / auto |
| Unread news | `.news.unread` | brand border + dot | data (`un:1`) | read |
| Toast visible | `#toast.show` | slide-up light toast | toast() | auto-hide |

### Data/component states (class-based)
- `.badge` color variants → semantic statuses: green (done/active/online/in), amber (pending/cash), red (error/cancelled/out), orange (brand), blue (info), grey (inactive).
- `.tstep.on` / `.tstep.done` → trip progress timeline.
- `.chip.on`, `.tabs button.on`, `.seg button.on` → selected filters/segments.
- `.tx .amt.in` (green) / `.amt.out` (red) → credit/debit.
- `.wal-card.bal` (green gradient) / `.wal-card.com` (orange gradient) → balance vs commission.
- `.btn:disabled`, `.btn green/ghost/danger-ghost` → button variants.

## 3. Loading / empty / error states

- **Loading:** only the splash boot log and the `.autobar` progress (passenger-cancel auto-dismiss) and the countdown ring. **No spinners/skeletons exist.** CONFIRMED.
- **Empty states:** none implemented (lists always have hardcoded data). CONFIRMED.
- **Error states:** login validation, "insufficient balance", "no internet", "waiting for approval". All are toast/error-text based. CONFIRMED.

## 4. What is simulated vs real

| Capability | Implementation | Confidence |
| --- | --- | --- |
| Maps | `mapSVG()` draws a stylized SVG grid; markers/route are positioned with hardcoded x/y coordinates; `moveMarker()` animates along points via requestAnimationFrame | CONFIRMED — visual placeholder, no real geolocation/navigation |
| GPS / location | Splash prints "Requesting location…" text only; no geolocation API | CONFIRMED — simulated |
| OTP | Any 4 digits accepted; countdown is a JS interval | CONFIRMED — simulated |
| Booking auto-request | `setTimeout` 4.5s after going online | CONFIRMED — simulated |
| Fare | `estFare(km) = km≤1 ? 4000 : 4000+(km-1)*1800` (៛); server fare = ×1.04 rounded to 100 | CONFIRMED — client-side formula |
| QR | `qrSVG()` pseudorandom grid (not a scannable QR code) | CONFIRMED — decorative |
| Sounds | WebAudio oscillators | CONFIRMED — real audio synthesis |
| Withdraw/transfer | Mutates in-memory state `S` / arrays only | CONFIRMED — no backend |
