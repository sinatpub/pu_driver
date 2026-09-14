# 01 — Design Direction

> **Phase:** design & analysis only. No Flutter code, pubspec, route or asset was changed.
> **Behaviour truth:** `docs/reverse-engineering/01–08` + Flutter source (`lib/`).
> **Target UI truth:** `docs/ui-reference/01–07` + `docs/taarraa-driver-prototype.html` (cited as `HTML:<line>`).
> **Standing project rules also applied:** `../.agent/RULES.md` (quirks, payload policy, Definition of Done) and `../ux_ui_design/ui-layout-system.md` (accessibility floors).
> **Decisions** live once in `07-design-decision-log.md` as `DD-xx`; other docs only reference them.

Input notes: the reverse-engineering set is named `02-auth-and-session … 08-redesign-blueprint`, not `02-app-flow … 07-design-tokens` as the task brief lists; coverage is equivalent. `docs/ui-reference` calls the prototype `taarraa-driver-prototype (1).html`; the repo file is `docs/taarraa-driver-prototype.html`.

**Markers used in every doc:** `CONFIRMED` (read in source), `INFERRED` (follows from source, not observed at runtime), `UNCLEAR` (needs an owner answer), `PROPOSED` (new design value or decision).

---

## 1. Goal

Re-skin `pu_driver` into the prototype's map-first layout language, in light mode. The aim is for a driver to read the app's state and the next action at a glance. Every transition, request, socket emit, timer, route and validation the app performs today stays the same.

## 2. Design principles

1. **Behaviour is fixed; presentation moves.**
   - Out of scope: controllers, `TripStateMachine`, datasources, socket/FCM, `LocationService`, routes and route arguments.
   - New widgets read the existing `Rx` state and call the existing methods.
2. **One next action.** Each trip stage has exactly one primary action. It is pinned to the bottom of the sheet, 56 px tall, in the same place at every stage.
3. **State is always on screen.** Each of these has its own always-visible indicator: online/offline, approval, network, trip stage and the request countdown.
4. **Glanceable.**
   - Each stage leads with one large fact: where to go, or how much to collect.
   - Nothing smaller than 12 px.
   - No marquees, no emoji icons, no decorative animation.
5. **Truthful money.**
   - Server figures are shown plainly. Client estimates always carry "≈ Est.".
   - No figure is shown that the app can't compute today, so no earnings card and no ratings (DD-07, DD-15, DD-31).
6. **Accessible by construction.** Every colour pair in `02` was measured against WCAG 2.1. Where the prototype fails, its look is kept and the value corrected (DD-02, DD-03).

## 3. Driver context → UI obligations

| Context | What the UI must do |
|---|---|
| Driving | Primary CTA in the thumb zone, 56 px. Labels ≥16 px. The action can be found without reading. |
| Waiting for requests | Home clearly states "online, receiving requests" or "offline". The status pill is readable at arm's length. |
| Request arrives | The countdown and Accept dominate. Cancel is reachable, but a sloppy Accept tap can't hit it. |
| Pickup | The pickup address is the largest text. Calling the passenger is one tap. |
| On trip | Meter and destination are visible; details can collapse. Drop off stays pinned. |
| Poor network | A persistent banner that doesn't alarm. Actions show a spinner inside the button; the screen never freezes. |
| Poor GPS / no permission | Home shows a clear location state with the existing "open settings" action. |
| Realtime events | A passenger cancellation or an expired request is explained on screen, not silent. |

## 4. Visual direction

- **Surfaces:** light — a `#F2F2F5` page behind `#FFFFFF` cards, hairline dividers, and opaque white cards floating over the map.
- **Brand orange:**
  - `#FF4500` is the identity colour: logo, route line, active indicators.
  - Buttons use a deeper `#CC3700` fill so white labels pass AA (DD-02).
- **Semantic colours** always mean status:

  | Colour | Means |
  |---|---|
  | Green | online, trip in progress, confirmation |
  | Blue | heading to or waiting at pickup |
  | Amber | pending, warning, countdown ≤10 s |
  | Red | destructive text and errors only |

- **Type:** Kantumruy Pro (already bundled), bold weights for figures, tabular numerals for money and timers.
- **Rounded geometry:** 14 px controls, 16 px cards, 20 px dialogs, 22 px sheet tops, fully round pills.

## 5. Information hierarchy

| Surface | Priority, top to bottom |
|---|---|
| Shell / Home | online state → blocking states (approval, update, location) → map |
| Trip | stage (pill and timeline) → primary action → next place → passenger → metrics |
| Payment | amount to collect → confirm action → trip facts → addresses |
| Lists (history, wallet, news) | what the row is → amount or status → metadata |

## 6. Safety and usability rules

- **Accept vs Cancel** (DD-11):
  - They are never side-by-side buttons of similar weight.
  - Accept is full-width primary.
  - Cancel is a text action below it, ≥16 px away, behind the existing confirm dialog.
- **During an in-flight trip request, every trip action is disabled**, not only the one tapped (DD-17). This takes over the blocking role of today's full-screen `LoadingWidget`. It matters because the Cancel path emits a socket event before the controller guard runs.
- **Drop off** is a forward action and isn't styled as destructive (DD-12). Whether to add a confirmation step is an OPEN product decision (DD-13).
- **Nothing delays navigation for decoration.** There's no 1.6 s "payment confirmed" overlay (DD-18).
- **Motion:**
  - Nothing animates for more than 300 ms except the map.
  - Live dots pulse only when `MediaQuery.disableAnimations` is false.
  - Money values never animate.

## 7. What changes and what must not

**Changes:**
- theme and tokens (light, rebuilt on measured values — DD-01)
- type scale, spacing, radius and elevation
- every screen's layout and its components
- dialog, sheet and toast styling
- map presentation: default light styling, route colour, padding (DD-28)
- a few labels, via *new* translation keys (DD-29)
- loading, empty and error visuals

**Must not change.** The full checklist with sources is in `05 §11`. Headlines:
- `TripStateMachine` transitions and "advance only after REST succeeds" (`booking/logic.dart:33-156`).
- Socket event names and payloads, and the order of emits. This includes `driverCancelDrive` being emitted **before** the REST cancel (`ride_request_bottom_pop_widget.dart:355-367`).
- Countdown expiry → `Get.offAllNamed('/home')` (`count_down_widget.dart:32-37`).
- The passenger-cancel dialog's 10 s auto-return (`cancel_book_dialog_widget.dart:23-27`).
- Resume routing, including the 2 s dialog and quirk M-21 (`home/logic.dart:204-277`).
- The approval gate fails closed. The online toggle is optimistic and rolls back on error (`app/logic.dart:24-25, 61-75`).
- Payment: REST → `acceptPayment` emit → profile refetch → home (`calculate_fee/logic.dart:68-91`).
- Validation quirks:
  - Driver phone is rejected under 10 characters, counted on the unnormalised text (`login/logic.dart:68-83`).
  - Register is enabled unless name **and** plate are both empty (`register/view.dart:408-411`).
- Error-dialog dismissal semantics, including the double pop (DD-33).
- `LocationService` ownership, camera behaviour and location reporting.
- Routes, route-argument classes and bindings.
