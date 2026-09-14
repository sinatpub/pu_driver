# 04 — Component Specification

**Locations (PROPOSED):**
- Shared components go in `lib/presentation/widgets/ds/`.
- Feature components go in `lib/presentation/screens/<feature>/widgets/`.
- The `T` prefix follows the existing `TImageWidget`.

**Rule: components are presentational.** They take values and callbacks and never call `Get.find`. There are three exceptions, marked **connected**: `OnlineStatusPill`, `ApprovalGate`, `OfflineBanner`. Each reads app-lifetime state the same way today's `SwitchOnlineWidget` does (`switch_online_widget.dart:14`).

**Tiers:**
- **A — Shared:** reusable across screens.
- **B — Feature:** driver and trip.
- **C — Screen-specific:** listed in a table only, so as not to split things into too many components.

---

# A — Shared components

# Component: TButton
## Purpose
Every tappable action rendered as a button.
## Visual Design
The variants `primary`, `success`, `secondary`, `destructiveOutline` and `tertiary`, in sizes `regular` (56) and `small` (48). Full specification in `02 §7`.
## States
Default · pressed (scale .97 + pressed colour) · disabled · loading (spinner, width unchanged).
## Behavior
- Ignores taps while `loading` or disabled.
- An optional leading icon.
- Labels are always sentence case.
## Inputs
`label`, `variant`, `size`, `onPressed` (null = disabled), `loading`, `icon`, `expand` (default true).
## Events
`onPressed`.
## Existing Equivalent
`FBTNWidget` (`widgets/fbtn_widget.dart`, used by booking sheet, login, register, wallet, calculate_fee); `XButton` (register).
## Recommended Flutter Structure
A `StatelessWidget` wrapping `Material` + `InkWell`, with `AnimatedScale` for the press. The gradient is a `DecoratedBox`; `ConstrainedBox(minHeight)` sets the height.
## Used By
All screens.

# Component: TIconButton
## Purpose
Icon-only actions: menu, back, bell, refresh, call.
## Visual Design
- 48×48 target, `bg.raised`, 1 px `border.control`, `r.md`, 22 px icon.
- Optional dot badge (`.icon-btn` HTML:86-87).
- Tone variant `success` for "call" (green border and icon, HTML:923).
## States
Default · pressed · disabled.
## Behavior
Requires `semanticLabel`.
## Inputs
`icon`, `onPressed`, `semanticLabel`, `tone`, `showDot`.
## Events
`onPressed`.
## Existing Equivalent
Assorted `IconButton`s (`drawer/view.dart:84-93`, `ride_request_bottom_pop_widget.dart:156-164`).
## Recommended Flutter Structure
`Semantics` + `InkWell` inside a `SizedBox.square(48)`.
## Used By
Shell, trip, history, wallet, details, OTP, register.

# Component: TTextField (+ `TTextField.phone`)
## Purpose
Labelled input.
## Visual Design
`02 §8`. The phone variant has a `+855` prefix and a divider.
## States
Default · focused · error (border + message + shake) · disabled.
## Behavior
- **The component takes the input formatters as a parameter; it doesn't own any.** The login screen passes the existing `CardNumberInputFormatter` unchanged.
- The error text comes from the caller.
## Inputs
`label`, `controller`, `hint`, `errorText`, `prefix`, `keyboardType`, `inputFormatters`, `enabled`, `onSubmitted`.
## Events
`onChanged`, `onSubmitted`.
## Existing Equivalent
`XTextField` (login), `text_field_decoration.dart`, `ShakeWidget` (kept and wrapped).
## Recommended Flutter Structure
A `Column` of the label, a `TextField` with a themed `InputDecoration` (OutlineInputBorder tokens) and the error row. `ShakeWidget` wraps the field.
## Used By
Login, register.

# Component: TCard
## Purpose
Surface container.
## Visual Design
`bg.surface`, `border.divider` hairline, `r.lg`, padding 16. Variants `raised` (`bg.raised`) and `tinted(fill, border)` for wallet cards.
## States
Static. When tappable, it shows ink.
## Behavior
Optional `onTap`.
## Inputs
`child`, `padding`, `variant`, `onTap`.
## Events
`onTap`.
## Existing Equivalent
Ad-hoc `Container` + `BoxShadow` throughout, e.g. `calculate_fee/view.dart:141-155`.
## Recommended Flutter Structure
`Material` + `InkWell` + `Ink(decoration)`.
## Used By
History detail, receipt, wallet, news detail, approval gate, status card.

# Component: TBadge
## Purpose
Short status label.
## Visual Design
`micro`, padding 5×11, `r.full`. Tones: success / danger / warning / brand / info / neutral (`02 §13`).
## States
Static.
## Behavior
Always has text; an optional leading icon for status meanings.
## Inputs
`label`, `tone`, `icon`.
## Events
—
## Existing Equivalent
None; today status is plain text (`history_card_widget.dart:98`).
## Recommended Flutter Structure
`DecoratedBox` + `Padding` + `Row`.
## Used By
History, payment (method), status card, drawer.

# Component: TSegmented
## Purpose
Two-to-three-option exclusive switch.
## Visual Design
`.seg` (HTML:83-85): `bg.raised` track, `r.full`. The selected segment is `bg.surface` + `elev.selected`.
## States
Selected / unselected per option.
## Behavior
Each segment has a ≥48 px target, even though it's visually 34 px tall.
## Inputs
`options`, `selected`.
## Events
`onChanged`.
## Existing Equivalent
`ChangeLanguage` bottom sheet (`widgets/widget_change_laguage.dart`).
## Recommended Flutter Structure
A `Row` of `Expanded` `InkWell`s, with an `AnimatedContainer` for the selected state.
## Used By
`LanguageSegment` (login, drawer).

# Component: TTabs
## Purpose
Content filter tabs.
## Visual Design
`.tabs` (HTML:216-218): `bg.raised` track, `r.control`. The selected tab is `bg.surface` with `text.primary` + `elev.selected`; the rest are `text.secondary`, in `label`.
## States
Selected / unselected.
## Behavior
Tapping only changes the filter.
## Inputs
`labels`, `index`.
## Events
`onChanged(index)`.
## Existing Equivalent
History's `_tab` underline buttons (`history/view.dart:114-144`).
## Recommended Flutter Structure
The same structure as `TSegmented`, full width.
## Used By
History.

# Component: TChip
## Purpose
Filter chip.
## Visual Design
`.chip` (HTML:236-237), `label`, padding 8×16, `r.full`. Unselected: `bg.surface` + `border.control`. Selected: `brand.tint` fill with a `brand.text` border and label.
## States
Selected / unselected.
## Behavior
Single-select, in a horizontal scroll.
## Inputs
`label`, `selected`.
## Events
`onTap`.
## Existing Equivalent
`_filterChip` (`wallet/view.dart:231-253`).
## Recommended Flutter Structure
`InkWell` + `AnimatedContainer`.
## Used By
Wallet.

# Component: TAvatar
## Purpose
Person image with a fallback.
## Visual Design
Circle at 44 / 48 / 54; network photo. Fallback: initials on `avatar.fallback` (`02 §1.1`). The prototype's orange→purple gradient carried white initials at 2.87:1 and is not used.
## States
Loading (fallback fill) · image · error → initials.
## Behavior
Initials come from the first letters of the name.
## Inputs
`imageUrl`, `name`, `size`, `tone` (driver / passenger).
## Events
—
## Existing Equivalent
`TImageWidget` (booking sheet, profile header, history card, calculate_fee).
## Recommended Flutter Structure
`ClipOval` + `Image.network` with `errorBuilder` / `loadingBuilder`.
## Used By
Passenger row, drawer, history, payment.

# Component: TKeyValueRow
## Purpose
Label on the left, value on the right.
## Visual Design
`.kv` (HTML:207-208). The value is tabular when numeric.
## States
Static. When the value is null: "—" in `text.secondary`.
## Behavior
The value wraps and is never truncated (money rule).
## Inputs
`label`, `value`, `valueStyle`, `numeric`.
## Events
—
## Existing Equivalent
Ad-hoc `Row`s (`calculate_fee/view.dart:281-298`).
## Recommended Flutter Structure
`Row` + `Flexible` value.
## Used By
Payment, history detail, trip (est. fare).

# Component: TAddressRow
## Purpose
Pickup or destination line.
## Visual Design
`.addr-row` (HTML:192-197). `kind` sets the dot; `emphasis: focus` switches the primary line to `title`.
## States
Loaded · loading (a skeleton line while the address string is empty).
## Behavior
2-line clamp on the primary line and 1 on the secondary; the full text is available through `Semantics`.
## Inputs
`kind` (pickup / destination), `overline`, `primary`, `secondary`, `emphasis`, `loading`.
## Events
—
## Existing Equivalent
Icon + "LABEL: (text)" rows (`ride_request_bottom_pop_widget.dart:200-264`; `calculate_fee/view.dart:310-362`).
## Recommended Flutter Structure
`Row` + dot + `Column`.
## Used By
Trip sheet, payment, history card (compact variant).

# Component: TSheet
## Purpose
Modal bottom sheet.
## Visual Design
`02 §10`, generic.
## States
Opening · open · closing.
## Behavior
Dismissed by the scrim or a drag. Keyboard-aware.
## Inputs
`child`, `title`, `isScrollControlled`.
## Events
`onClosed`.
## Existing Equivalent
`xShowModalBottomSheet` (register photo picker); the drawer's language `showModalBottomSheet`.
## Recommended Flutter Structure
A `showTSheet()` helper over `showModalBottomSheet` with a themed `BottomSheetThemeData`.
## Used By
Register photo picker.

# Component: TDialog
## Purpose
Every modal dialog.
## Visual Design
`02 §11`. Variants:
- `confirm`: title, body, and a `[destructiveOutline | primary]` or `[secondary | primary]` pair.
- `error`: `danger` icon, title, body, one action.
- `autoDismiss`: + progress bar.
- `progress`: spinner + title, no actions.
- `blocking`: can't be dismissed; for force update.
## States
Open · closing.
## Behavior
**Dismissal, barrier and navigation stay with the caller's existing logic.** In detail:
- `error` accepts `popRouteOnConfirm`. This reproduces `showErrorCustomDialog(..., comfirmBook: true)`, which pops twice (DD-33).
- `autoDismiss` only *draws* progress. The navigating timer stays in `showCancelBookingDialog`'s logic (DD-25).
## Inputs
`title`, `message`, `icon`, `actions`, `barrierDismissible`, `progressDuration`, `popRouteOnConfirm`.
## Events
Action callbacks.
## Existing Equivalent
`showYesNoCustomDialog`, `showErrorCustomDialog`, `showCancelBookingDialog`, `showPocessBookingLoadingDialog`, `WidgetUpdate`.
## Recommended Flutter Structure
**Keep the existing function signatures** (`show…Dialog(...)`) and change only the builder body to a `TDialog`, so no call site changes.
## Used By
Trip, payment, auth errors, shell (resume, force update).

# Component: TToast
## Purpose
Transient feedback that isn't tied to a state.
## Visual Design
`02 §11`.
## States
Showing (2.4 s) · hidden.
## Behavior
Floats above the safe area; one at a time.
## Inputs
`message`, `icon`.
## Events
—
## Existing Equivalent
`EasyLoading.showToast` (`switch_online_widget.dart:33`).
## Recommended Flutter Structure
A helper that wraps `Get.snackbar` or `ScaffoldMessenger`, styled with tokens. Keep `EasyLoading.showToast` call sites until they migrate (DD-27).
## Used By
Online-toggle refusal; the optional expiry notice.

# Component: TBanner
## Purpose
Persistent inline notice.
## Visual Design
Pill; tones `warning` / `danger` / `info`; icon + `micro` text.
## States
Visible / hidden; animated with a 200 ms slide.
## Behavior
Not dismissible.
## Inputs
`message`, `tone`, `icon`.
## Events
—
## Existing Equivalent
The red `Container` banner (`drawer/view.dart:321-343`).
## Recommended Flutter Structure
`AnimatedSwitcher` + `DecoratedBox`.
## Used By
`OfflineBanner`.

# Component: TEmptyState / TErrorState
## Purpose
List-level empty or failed content.
## Visual Design
Centred:
- 28 px icon in `text.secondary`
- `subtitle` title
- `bodySecondary` message
- optional `secondary` action

`TErrorState` uses a `danger` icon and "Try again" (layout-system §11 pattern).
## States
Static.
## Behavior
The action is a callback.
## Inputs
`icon`, `title`, `message`, `actionLabel`, `onAction`.
## Events
`onAction`.
## Existing Equivalent
Wallet `_errorState` (`wallet/view.dart:162-186`); history and announcement error text.
## Recommended Flutter Structure
`Center` + `Column`.
## Used By
History, wallet, announcements, home (location), approval gate.

# Component: TSkeleton
## Purpose
Loading placeholder shaped like the content it replaces.
## Visual Design
`bg.raised` blocks with a 1.4 s shimmer toward `border.divider`, radius matching the content.
## States
Animating; static when `disableAnimations` is true.
## Behavior
—
## Inputs
`width`, `height`, `radius`.
## Events
—
## Existing Equivalent
`simmer_widget.dart` (`ShimmerProfile`, `ShimmerWalletCard`, `ShimmerBookStory`, `ShimmerNotification`), using the `shimmer` package.
## Recommended Flutter Structure
Keep the four compositions and swap their colours to tokens. Build new compositions from `TSkeleton`.
## Used By
Drawer profile, wallet, history, announcements, address lines.

# Component: TAmount
## Purpose
A consistent money figure.
## Visual Design
Tabular; `text.primary`; styles `row` (bodyStrong) / `hero` (display) / `estimate` (prefixed "≈", + caption qualifier).
## States
Known · unknown ("—").
## Behavior
**Takes an already-formatted string** from the existing formatters (`formatRielAmount`, `formatWalletAmountWithSymbol`); it never formats money itself. Non-breaking space between symbol and number; never truncated.
## Inputs
`text`, `style`, `isEstimate`.
## Events
—
## Existing Equivalent
Ad-hoc `Text("៛${formatRielAmount(...)}")`.
## Recommended Flutter Structure
A `Text` with `FontFeature.tabularFigures()`.
## Used By
Trip, payment, history, wallet.

---

# B — Feature components (driver / trip)

# Component: OnlineStatusPill (connected)
## Purpose
Show and toggle availability.
## Visual Design
`02 §13` online pill.
## States
Off · on · busy (toggle in flight) · locked (not approved: same look as off, with a lock hint icon).
## Behavior
- Tap → the same logic as `SwitchOnlineWidget.onToggle`: if unapproved, show the existing toast; otherwise call `AppLogic.toggle(!isOnline)`.
- The optimistic flip and rollback live in `AppLogic`.
- EasyLoading keeps showing, themed (DD-09).
## Inputs
None; reads `AppLogic.state.isOnline` and `isApproved`.
## Events
—
## Existing Equivalent
`SwitchOnlineWidget` (`home/widgets/switch_online_widget.dart`).
## Recommended Flutter Structure
`Obx` over a presentational `TOnlinePillView(isOnline, busy, locked, onTap)`.
## Used By
Shell app bar (home tab only).

# Component: ApprovalGate (connected)
## Purpose
Block the body while the driver isn't approved.
## Visual Design
Full-body `bg.blocking` layer with a centred `TCard`: an 84 px round icon well (`.appr-ic` HTML:163), a `headline` title, `bodySecondary` text and actions (`03 S05`).
## States
`unknown` / `pending` / `rejected` / hidden (`approved`).
## Behavior
Covers the body only; the app bar stays reachable. "Retry" → `AppLogic.fetchCurrentDriveInfo`. "Contact support" → `ContactUsLogic.callPhone` (DD-08).
## Inputs
Reads `AppState.approvalStatus`.
## Events
Retry, contact.
## Existing Equivalent
The two approval `Obx` blocks (`drawer/view.dart:344-379`).
## Recommended Flutter Structure
`Obx` → `AnimatedSwitcher` → `TApprovalView(status, onRetry, onContact)`.
## Used By
Shell.

# Component: OfflineBanner (connected)
## Purpose
State network loss.
## Visual Design
`TBanner`, warning tone, "No internet — reconnecting…".
## States
Hidden (connected) · visible.
## Behavior
Renders `SizedBox.shrink()` while connected, exactly as today.
## Inputs
Reads `DrawerState.connection`.
## Events
—
## Existing Equivalent
`drawer/view.dart:321-343`.
## Recommended Flutter Structure
`Obx` + `Positioned` under the app bar.
## Used By
Shell. Showing it on the booking screen needs connectivity state lifted out of `DrawerLogic`; that's a separate change (DD-26).

# Component: DriverDrawer
## Purpose
Navigation and profile.
## Visual Design
`02 §12`. Profile head, menu rows, language row, optional version.
## States
Profile loading / error / loaded. The active row follows `activeTab`.
## Behavior
Item → `onSelect(tab)`, and the drawer closes (`Navigator.pop`, as today).
## Inputs
`activeTab`, `profile` (name, phone, vehicleLabel, driverId, imageUrl), `profileStatus`, `locale`.
## Events
`onSelect(DrawerTab)`, `onLocaleChanged`.
## Existing Equivalent
The `drawer:` subtree (`drawer/view.dart:102-305`) + `ProfileHeaderWidget`.
## Recommended Flutter Structure
A `Drawer` with a custom child. The profile head is split into its own widget.
## Used By
Shell.

# Component: DriverStatusCard
## Purpose
Home's statement of availability.
## Visual Design
A floating card with `.earn-card` geometry (HTML:150): opaque `bg.floating`, `border.divider`, `r.lg`, `elev.float`. `TBadge` + `subtitle` + `caption`.
## States
Online · offline.
## Behavior
Not interactive (DD-09).
## Inputs
`isOnline`.
## Events
—
## Existing Equivalent
None.
## Recommended Flutter Structure
`Positioned(bottom: 16 + safe)` inside the home `Stack`.
## Used By
Home.

# Component: LocationStateView
## Purpose
Home content while there's no location fix.
## Visual Design
`TEmptyState` variants on `bg.page`, with a map skeleton for loading.
## States
inProgress · permissionDenied · failure.
## Behavior
"Open settings" → `openAppSettings()` (the existing call).
## Inputs
`LocationLoadStatus`, `errorText`.
## Events
`onOpenSettings`.
## Existing Equivalent
`_buildGoogleMap` non-success branches (`home/view.dart:69-116`).
## Recommended Flutter Structure
`switch` on the status.
## Used By
Home.

# Component: TripScreenScaffold
## Purpose
Map + header + countdown + sheet layout for `/booking`.
## Visual Design
`03 S07` diagram.
## States
Driven by its children.
## Behavior
Measures the sheet height and gives it to the map's `padding.bottom`. It doesn't own a `GoogleMap` controller.
## Inputs
`map` (widget), `header`, `overlay` (countdown), `sheet`.
## Events
`onSheetHeightChanged`.
## Existing Equivalent
`booking/view.dart` build `Stack` (`:628-720`).
## Recommended Flutter Structure
`Stack` + `LayoutBuilder` + a `SizeChangedLayoutNotifier` (or `GlobalKey` measure) on the sheet.
## Used By
Trip.

# Component: TripHeader
## Purpose
Stage identity over the map.
## Visual Design
A floating pill-card: `stage.*` palette border, pulse dot, `bodyStrong` stage title, tabular `#bookingCode` `caption` on the right (HTML:168-175 merged, DD-10).
## States
request / pickup (two titles) / onTrip.
## Behavior
Tap toggles the sheet's collapse (optional).
## Inputs
`stage` (`TripStage`), `bookingCode`.
## Events
`onTap`.
## Existing Equivalent
AppBar stage title (`booking/view.dart:609-622`).
## Recommended Flutter Structure
`SafeArea` + `Padding(16)` + `DecoratedBox`.
## Used By
Trip.

# Component: RequestCountdown
## Purpose
Time left to decide on a request.
## Visual Design
`02 §13` countdown pill. The arc turns `warning` at ≤10 s.
## States
Running · warning (≤10 s) · expired (triggers navigation).
## Behavior
**Keeps `SmoothCircularCountdown`'s engine:** an `AnimationController` over `countDuration` which, on dismiss with `isPop`, calls `Get.offAllNamed('/home')`. Only the drawing changes. No sound (DD-16).
## Inputs
`countDuration`, `isPop`.
## Events
— (navigation as today).
## Existing Equivalent
`SmoothCircularCountdown` (`widgets/count_down_widget.dart`).
## Recommended Flutter Structure
Rewrite `build()` inside the same `State` class, e.g. a `CustomPaint` ring + text. Leave `initState` and the listener untouched.
## Used By
Trip (request stage).

# Component: TripTimeline
## Purpose
Show progress through the 4 driver actions.
## Visual Design
`02 §13` timeline, with labels Accept / Arrive / Start / Drop.
## States
Derived from the stage:
- `requestReceived` → step 0 current
- `enRouteToPickup` → step 1
- `waitingAtPickup` → step 2
- `inProgress` → step 3
- `completing` → all done
## Behavior
Display-only.
## Inputs
`stage`.
## Events
—
## Existing Equivalent
None.
## Recommended Flutter Structure
`Row` of `Expanded` steps + a painted connector.
## Used By
Trip sheet.

# Component: PassengerRow
## Purpose
Who you're picking up, plus a way to call them.
## Visual Design
`.pax-row` (HTML:190, 923): `TAvatar` 48, name `bodyStrong`, phone `caption` tabular, and a `TIconButton` call with success tone. No rating (DD-15).
## States
Default · `showCall: false` (payment).
## Behavior
Call → `launchUrl('tel:…')`, the same as today.
## Inputs
`name`, `phone`, `imageUrl`, `showCall`.
## Events
`onCall`.
## Existing Equivalent
`ride_request_bottom_pop_widget.dart:124-166`; `calculate_fee/view.dart:162-202`.
## Recommended Flutter Structure
`Row` inside a `DecoratedBox`.
## Used By
Trip sheet, payment receipt.

# Component: TripSheet
## Purpose
Persistent trip sheet with collapsible content and a pinned footer.
## Visual Design
`02 §10` trip sheet.
## States
Expanded · collapsed.
## Behavior
- Initial collapsed = `stage == inProgress` **at first build**. This mirrors `isExpanded` init (`ride_request_bottom_pop_widget.dart:55-64`).
- The meter and footer stay visible when collapsed.
- Content scrolls; the footer never does.
## Inputs
`header` (timeline), `pinnedTop` (meter), `content`, `footer`, `initiallyExpanded`.
## Events
`onHeightChanged`.
## Existing Equivalent
`ModelBottomSheetNewRequestWidget`'s `ExpansionTile` container.
## Recommended Flutter Structure
**Keep the class name and constructor of `ModelBottomSheetNewRequestWidget`** so `booking/view.dart` changes minimally. Internally: `AnimatedSize` + `ConstrainedBox(maxHeight: 74%)` + a `Column(header, Flexible(scroll), footer)`.
## Used By
Trip.

# Component: TripActionBar
## Purpose
The stage's primary action, plus Cancel on a request.
## Visual Design
Primary or success `TButton` (56). On a request: 16 px gap, then a tertiary-danger "Cancel request" (48).
## States
Idle · loading (the tapped button) · disabled (siblings while loading).
## Behavior
- Cancel opens the existing `showYesNoCustomDialog` flow, restyled (`TDialog.confirm`). Its `onYes` body is unchanged: `DriverSocketService().driverCancelDrive(...)`, then `onCancel()`.
- **Cancel is disabled while `isLoading`** (DD-17).
## Inputs
`stage`, `isLoading`, `onPrimary`, `onCancel`, the cancel payload (bookingId, bookingCode, passengerId).
## Events
`onPrimary`, `onCancel`.
## Existing Equivalent
`ride_request_bottom_pop_widget.dart:318-398`.
## Recommended Flutter Structure
`SafeArea(top: false)` + `Column`.
## Used By
Trip sheet.

# Component: TripMeterStrip
## Purpose
Live in-trip time / distance / estimated fare.
## Visual Design
`.fare-strip` (HTML:198-203): `stage.onTrip` container, 3 cells with dividers, `numericLg`-ish 19/700 values, `caption` labels. The fare cell is prefixed "≈". Below it, an estimate note in `warning` with the `i-info` icon (`.est-note` HTML:203).
## States
Running. The fare may be absent before the minimum fare loads; the existing value branches decide.
## Behavior
Receives **already-formatted strings** from `booking/view.dart` (the same expressions as today's `ShowDistandWidget` arguments, `:663-676`).
## Inputs
`duration`, `distance`, `fare`.
## Events
—
## Existing Equivalent
`ShowDistandWidget` (`booking/widgets/show_distand_and_price_widget.dart`).
## Recommended Flutter Structure
`Row` of 3 `Expanded` + `VerticalDivider`.
## Used By
Trip sheet (inProgress).

# Component: ReceiptCard + TotalBox
## Purpose
What to collect, and the trip facts behind it.
## Visual Design
- **ReceiptCard:** `TCard` (padding 18) → `PassengerRow(showCall: false)` + optional method `TBadge` → dashed divider (`.dash` HTML:206) → `TKeyValueRow` ×3 → dashed → `TAddressRow` ×2.
- **TotalBox:** `bg.raised`, `r.lg`, padding 16. `caption` "Total to collect" on the left, `TAmount.hero` on the right (DD-04, DD-18).
## States
Static. The method badge is absent when there's no value.
## Behavior
Display only.
## Inputs
`passenger`, `method`, `distance`, `duration`, `dateTime`, `startAddress`, `endAddress`, `amount` (formatted).
## Events
—
## Existing Equivalent
`CalculateFeeScreen.bodyRecive` (`calculate_fee/view.dart:129-397`).
## Recommended Flutter Structure
`StatelessWidget`s. The view keeps choosing the payload via `logic.isFromDropBooking`.
## Used By
Payment.

---

# C — Screen-specific components

| Component | Purpose / visual | Existing equivalent | Screen |
|---|---|---|---|
| `HistoryCard` | `.hcard` (HTML:219-225): avatar, invoice, amount, badge, route box, meta. Completed cards are tappable (DD-19) | `HistoryCardWidget` | History |
| `TransactionRow` | `.tx` (HTML:238-240): icon, type, date · status, neutral amount | `_transactionRow` (`wallet/view.dart:255-307`) | Wallet |
| `WalletBalanceCard` | `.wal-card` (HTML:228-234): label, amount, tinted fill (`success.tint` / `brand.tint`) | `_balanceCard` (`wallet/view.dart:311-365`) | Wallet |
| `NewsCard` | `.news` (HTML:241-246): unread border + dot | list item in `announcement/view.dart` | Announcements |
| `TermRow` | `.term` (HTML:248-249): numbered badge + text | row in `term_condition/view.dart` | Terms |
| `ContactRow` | `.prow` (HTML:250-252): icon, label, chevron | `ListTile`s in `contact_us/view.dart` | Contact |
| `PhotoSlotGrid` | `.photo-grid` / `.photo-slot` (HTML:131-133): dashed → solid success when attached | 4× `CardUploadAttachment` | Register |
| `OtpInput` | Pinput theme (`02 §8`) | `Pinput` + `defaultPinTheme` (`otp/view.dart:81-100`) | OTP |
| `LanguageSegment` | `TSegmented` EN / ខ្មែរ calling `context.setLocale` | `ChangeLanguage` | Login, drawer |
| `SplashMark` | `.logo-badge` + wordmark (HTML:119-123) | `splash_screen/view.dart` | Splash |

---

## Replacement map (existing → target)

| Existing | Target | Notes |
|---|---|---|
| `FBTNWidget`, `XButton` | `TButton` | `loadingBut` → `loading` |
| `LoadingWidget` (booking, login, register) | Button `loading` + disabled siblings | Only keep a scrim where no button owns the action |
| `showYesNoCustomDialog` | `TDialog.confirm` (same signature) | |
| `showErrorCustomDialog` | `TDialog.error` (same signature) | **Keep the `comfirmBook` double pop** (DD-33) |
| `showCancelBookingDialog` | `TDialog.autoDismiss` (same signature) | The timer logic stays (DD-25) |
| `showPocessBookingLoadingDialog` | `TDialog.progress` | 2 s timing lives in `HomeLogic` (DD-32) |
| `WidgetUpdate` | `TDialog.blocking` | |
| `SmoothCircularCountdown` | `RequestCountdown` (same class, new `build`) | |
| `ShowDistandWidget` | `TripMeterStrip` (booking) / `TCard` + `TKeyValueRow` (history detail) | |
| `ModelBottomSheetNewRequestWidget` | `TripSheet` + `TripTimeline` + `PassengerRow` + `TripActionBar` | Same constructor |
| `SwitchOnlineWidget` (`flutter_switch`) | `OnlineStatusPill` | |
| `ChangeLanguage` sheet | `LanguageSegment` | |
| `XTextField`, `text_field_decoration.dart` | `TTextField` | |
| `TImageWidget` | Inside `TAvatar` | |
| `Shimmer*` | Token-coloured compositions | |
| `DecoratedInputBorder` | — | No importers found. Leave it; deleting it is an unrelated change |
