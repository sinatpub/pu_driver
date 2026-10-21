# PU Taxi Driver app: architecture and handover

Oct 3, 2026 · @Mobile Spirit

The driver app is a Flutter app that talks to one REST backend and one socket. Invite, rewards, reward transfer and ride credit are built in the app but run on mock data only: the backend has no endpoints for them yet.

## At a glance

&#91;embedded content: app layers · screens, logic, services, two backends\]

A screen never calls the network itself: its view asks its logic, the logic asks a repository, and the repository goes through the one `ApiClient`. Mock mode replaces what sits under that client, the socket and the GPS, so the same screens run with no backend.

- Built with Flutter, with GetX for state and navigation. Text is in English and Khmer; Khmer is the default.
- A release build removes the mock layer entirely, so it can never reach production.
- Invite, rewards and transfer screens are shown only while the mock backend is active.

## The two pots of money

&#91;embedded content: money flow · reward balance, wallet balance, commission\]

The driver has two balances. Rewards from invites collect in the reward balance; only the wallet balance pays the company's commission, so the driver moves rewards across when they want to use them.

|  | Wallet balance | Reward balance |
| --- | --- | --- |
| What it is | Working money | Prize money from invites |
| Money in | Top-up, trip earning on wallet or card trips, ride credit, reward transfer | 1% of an invited driver's top-ups, 10% of commission on an invited passenger's trips |
| Money out | Commission on each trip | Transfer to the wallet balance |
| Cash withdrawal | No endpoint exists | Not allowed |

How commission is charged (the wallet model, DD-43): on a cash trip the driver keeps the cash and the wallet is charged the commission. On a wallet or card trip the platform holds the fare, and the wallet receives the fare less commission. If the wallet cannot cover a commission, the shortfall is debt, and the next money in pays the debt first.

## Invite flow

&#91;embedded content: invite flow · 6 steps, 1 decision\]

A wrong code sends the new person back to the field; a right one links them to the inviter, and every later top-up or trip adds a reward.

- The QR holds a link. The app the new person signs up in decides whether they joined as a driver or as a passenger.
- The inviter can also share the link or read out the code (example `PU7K2M`). The "My QR" sheet has copy and share buttons.
- At sign-up the code field is optional. The code is checked when typing pauses and shows "Invited by Sokha Vann" or "Code not recognised".
- A wrong code blocks "Submit" until it is fixed or cleared. The code cannot be added later, so dropping it silently would lose the invite for good.
- The scanner accepts only an invite: a link whose last part is 4 to 12 letters and digits, or such a code alone.
- The inviter sees the result in the wallet's reward card and on the "Invite rewards" screen: who joined, and what each person has earned them.

## Reward rules

The reward depends only on who was invited, not on who invited them. Every reward is paid from the company's share; the invited person and their driver pay nothing extra.

| Invited person | Inviter earns | When | Ends |
| --- | --- | --- | --- |
| Driver | 1% of each wallet top-up that driver makes | At each top-up | Never |
| Passenger | 10% of the company's commission on each trip they take | At each paid trip | Never |

Example for a passenger: the trip fare is ៛12,000 and the commission rate is 10%, so the company's commission is ៛1,200. The inviter earns 10% of that: ៛120.

Example for a driver: the invited driver tops up ៛100,000. The inviter earns ៛1,000.

Rules that apply to every invite:

- One QR and one invite code per person. The same code invites drivers and passengers.
- Both drivers and passengers can invite and earn.
- One level only. The inviter earns from the people they invited directly. If Dara invites Sokha and Sokha invites Bopha, Dara earns from Sokha and nothing from Bopha.
- The invited person earns nothing for joining. Only the inviter is rewarded.
- A code can be given only at sign-up. It cannot be added later.
- The server must refuse a self-invite (same phone or device).

## Transfer to balance

Rewards are not usable until the driver moves them into the wallet balance by hand. Nothing is transferred automatically, not even when the driver owes commission.

What the driver does:

1. Taps "Transfer to balance" on the wallet's reward card, on the rewards screen, or in the debt warning.
2. Types the amount. "All" fills in the whole reward balance. The field starts empty.
3. Reads the result on the sheet: "Balance after", "Rewards left", and how much pays debt first when they owe.
4. Taps "Transfer ៛2,000". The button is off until the amount is above zero and not more than the reward balance.

Rules:

- One way. A transfer cannot be moved back.
- No minimum. No maximum other than the reward balance.
- No cash withdrawal to a bank.
- If the driver owes commission, the transferred money pays that debt first. Only the rest reaches the balance.
- Riel takes whole numbers. Other currencies take two decimals.

Safety, and what the backend must enforce:

- The app sends the amount and a request id. The server must refuse an amount that is zero, negative, finer than the currency allows, or more than the reward balance it holds. The check on screen is only a convenience.
- A repeat of the same request id must not move money twice.
- The button is disabled while a transfer is in flight.
- After a transfer the app fetches the rewards again and refreshes the wallet in place, so both show the server's figures.

In the wallet history a transfer is one row, "Reward transfer +៛2,000". Single rewards are not wallet rows; they are in the reward history, so nothing is counted twice.

## Ride credit

A passenger's invite rewards are ride credit: at payment the passenger chooses to pay part or all of a trip with it. This is half-built in the driver app and not yet committed.

The rule for a cash trip, with fare ៛12,000 and ៛3,000 of credit used:

| Figure | Amount | Where the driver sees it |
| --- | --- | --- |
| Cash to collect | ៛9,000 | Payment screen, as the large amount |
| Paid by ride credit | ៛3,000 | Payment screen, green line; wallet row "Ride credit +៛3,000" |
| Commission (10% of the full fare) | ៛1,200 | Wallet row "Commission −៛1,200" |

- The driver always receives the full fare: cash plus credit.
- The company covers the credit. It never comes out of the driver's share.
- Commission is on the full fare, because the fare did not change.
- If credit covers the whole fare, the screen says "Paid by ride credit" and "Nothing to collect", and the button reads "Finish trip".
- On a wallet or card trip the platform already holds the whole fare, so credit changes nothing for the driver and is not shown.
- Passengers cannot withdraw credit as cash.

State of the work: the fare split (`calculate_fee/payment_split.dart`), the payment screen, the trip detail line, the wallet row type and a QA panel switch are written and compile. Tests are not written, it has not been run on the emulator, and it is not committed. The passenger app side (earning credit, choosing it at payment) is not built.

## Screens and code

Each screen is a folder under `lib/presentation/screens/` holding `view.dart` (widgets), `logic.dart` (a GetX controller), `state.dart` (reactive fields) and `binding.dart` (dependency registration). A screen that owns data also has `data/datasource`, `data/repository` and `data/models`.

| What the driver sees | Where it is opened | Files (under `lib/presentation/screens/`) |
| --- | --- | --- |
| QR button on the map | Home tab | `home/view.dart`, `invite/widgets/invite_widgets.dart` (`InviteFab`) |
| "My QR" sheet: QR, code, copy, share, rules | QR button | `invite/my_qr_sheet.dart` |
| Reward card under the balance | Wallet tab | `wallet/view.dart`, `invite/widgets/invite_widgets.dart` (`RewardBalanceCard`) |
| "Invite rewards" screen, tabs Rewards and People | Wallet card, or the line on the QR sheet | `invite/rewards_view.dart`, `invite/people_view.dart` |
| Transfer sheet | "Transfer to balance" buttons | `invite/transfer_sheet.dart`, `invite/widgets/invite_widgets.dart` (`TransferAmountBody`) |
| Invite code field and QR scanner | Sign-up form | `register/view.dart`, `register/logic.dart`, `invite/widgets/invite_code_field.dart`, `invite/scan_view.dart` |
| Wallet balance, debt warning, transactions | Wallet tab | `wallet/view.dart`, `wallet/widgets/wallet_widgets.dart` |
| Payment screen with the ride credit line | End of a trip | `calculate_fee/view.dart`, `calculate_fee/widgets/receipt_card.dart` |

The rules are kept out of the widgets, in pure files that have their own tests:

| File | What it decides |
| --- | --- |
| `invite/invite_presentation.dart` | Reading a code out of a QR link, reward totals, reward balance, the typed transfer amount, where a transfer goes (debt first), the reward history order |
| `wallet/wallet_presentation.dart` | Money format, transaction kinds and their direction (+ or −), commission rate text, debt |
| `calculate_fee/payment_split.dart` | Fare split into cash and ride credit |
| `invite/invite_feature.dart` | Whether invite screens are shown at all (today: mock mode only) |

Other places a new developer needs:

- `lib/routes/app_routes.dart` and `app_pages.dart`: route names and which bindings each route loads.
- `lib/core/network/api_client.dart`: the one HTTP client. Every call returns `Result<T>`, never throws.
- `lib/core/theme/tokens.dart` and `lib/presentation/widgets/ds/`: colours, spacing and the shared widgets (`TCard`, `TButton`, `TTextField`, `TTabs`).
- `assets/translations/en.json` and `km.json`: every string. The two files must hold the same keys; a test enforces it.
- `docs/ux-redesign/07-design-decision-log.md`: why each screen is the way it is. Invite and rewards are DD-45 to DD-51.

The Dart package is `pu_taxi_driver`. The Android and iOS application id is still `com.tara.driver_application`.

## Backend contract

Three endpoints and three payload fields do not exist on the backend yet. The paths and field names below are the app's proposal; only the mock backend answers them.

| Endpoint | Status | Request | Response the app reads |
| --- | --- | --- | --- |
| `GET /taxi-driver/wallet` | Exists | none | `balance`, `debted`, `commission_fare`, `currency`, `transactions[]` (`type_name`, `amount`, `created_at`, `status_name`) |
| `POST /taxi-driver/register` | Exists; new field | adds `invite_code`, sent only when the driver gave one | unchanged |
| `GET /taxi-driver/referral` | Proposed | none | `code`, `link`, `currency`, `driver_top_up_rate`, `passenger_commission_rate`, `reward_balance`, `invitees[]`, `rewards[]`, `transfers[]` |
| `GET /taxi-driver/referral/check-code` | Proposed | `code` in the query; no token, the driver has no session yet | `valid`, `inviter_name` |
| `POST /taxi-driver/referral/transfer` | Proposed | `amount`, `request_id` | `transferred`, `reward_balance` |
| Trip payloads (`complete-drive`, `get-current-drive-info`, `history-drive-info`) | Exist; new field | none | adds `payment.ride_credit`: credit the passenger used on the trip |

Shapes of the lists in the referral response:

| List | Fields |
| --- | --- |
| `invitees[]` | `id`, `name`, `profile_image`, `role` ("driver" or "passenger"), `joined_at`, `earned` |
| `rewards[]` | `id`, `invitee_name`, `invitee_role`, `amount`, `base_amount` (the top-up; absent for a trip reward), `created_at` |
| `transfers[]` | `id`, `amount`, `created_at` |

What the server must do, beyond returning data:

- Create a reward when an invited driver tops up (1% of the top-up) and when an invited passenger's trip is paid (10% of the commission). Only the direct inviter is rewarded: one level, no chain.
- Validate a transfer: amount above zero, not more than the reward balance; pay debt first; treat a repeated `request_id` as the same transfer.
- Write wallet transactions the app can name. The app matches words in `type_name` until type codes are documented: "Top Up", "Trip Earning", "Commission", "Withdraw", "Reward Transfer", "Ride Credit".
- On a cash trip with ride credit: pay the credited part into the driver's wallet and charge commission on the full fare.
- Refuse self-invites.

Still to confirm with the backend team from earlier work: that `commission_fare` is a percentage and `debted` is unpaid commission, and the top-up endpoint. There is no automatic debt limit: the company stops a driver by hand from the admin panel.

## Mock mode

Mock mode replaces the backend, not the app: every screen, controller and repository runs as normal, and a fake server answers underneath them. It is the only way to see invite, rewards, transfer and ride credit today.

Run on a device or emulator:

```bash
fvm flutter run --dart-define-from-file=dart_defines.json --dart-define=USE_MOCK_DATA=true
```

Build an APK for a real phone (profile, because a release build removes mock mode):

```bash
fvm flutter build apk --profile --dart-define-from-file=dart_defines.json --dart-define=USE_MOCK_DATA=true
```

`dart_defines.json` is not in git. Copy `dart_defines.example.json` and fill it in.

| To see | Do this |
| --- | --- |
| Sign in as the mock driver, Dara Sok | Any phone number, any OTP except `9999` and `1111` |
| The sign-up form with the invite code field | OTP `1111` |
| A valid invite code | `SOKHA88` or `BOPHA21`; anything else is "not recognised" |
| The driver's own QR and code | QR button on the home map; the code is `PU7K2M` |
| Rewards | Wallet tab: reward balance ៛5,160 from five invited people |
| The reward balance again after transferring | QA panel (red "MOCK" tab on the left edge), "Reset all mock data" |
| A trip paid partly with ride credit | QA panel, "Passenger uses ride credit", then run a trip |
| Error cases (payment fails, session expires, no network) | QA panel, "Scenario" |

Where the mock lives: `lib/mock/`. `mock_backend.dart` is the fake server, `mock_fixtures.dart` holds its data, `mock_mode.dart` holds the settings, and `mock_dev_panel.dart` is the QA panel. Full guide: `docs/qa/MOCK_MODE.md`.

Against the real backend the invite screens are hidden. `invite_feature.dart` returns true only while the mock backend is serving the app; change it when the endpoints exist.

Tests: `fvm flutter test test/presentation test/mock test/core test/a11y test/l10n`. Do not run `test/qa`: it rewrites files under `docs/qa`. Twelve tests failed before this work and still fail (drawer and login text clipping, vehicle parsing, app config defaults, one hardcoded string).

## Status and open questions

The driver side of invite, rewards and transfer is built and pushed to the `dev` branch; none of it works against the real backend until the endpoints exist.

| Part | State |
| --- | --- |
| QR button, "My QR" sheet, share, copy | Built, pushed, checked on an emulator |
| Invite code at sign-up, with checks | Built, pushed, checked on an emulator |
| QR scanner at sign-up | Built, pushed; real scanning not tested (needs a phone with camera access) |
| Reward balance, rewards and people tabs | Built, pushed, checked on an emulator |
| Transfer to balance, typed amount | Built, pushed, checked on an emulator; on-screen keyboard not checked on a phone |
| Debt paid first on transfer, and the debt warning's transfer offer | Built, pushed; covered by tests only, because the mock wallet never owes |
| Ride credit on the payment screen | Written, compiles; no tests, not run, not committed |
| Passenger app: QR, rewards, ride credit at payment | Not built |
| Web page the QR link opens ("I want a ride" / "I want to drive") | Not built |
| Backend: referral endpoints, rewards, transfer, ride credit | Not built |

Open questions:

| Question | Answer from the product owner, 3 Oct 2026 |
| --- | --- |
| Does the invited person receive anything for joining? | Nothing, at joining or later. Only the inviter earns, and only after the invited person tops up (driver) or pays for a ride (passenger). |
| What is the real link domain for the QR? | Keep the placeholder `putaxi.example` for now. A real domain is needed before launch. |
| What format is the invite code? | Keep six random letters and digits. |
| At what debt does the driver stop receiving ride requests? | No automatic limit. The company watches debt in the admin panel and stops a driver by hand. The app shows the debt and never blocks requests itself. |
| Who reviews the Khmer text? | The product owner, a native speaker. |

Still open:

- [ ] Khmer review of the new strings by the product owner.
- [ ] The real link domain, before launch.

Decisions already made, with the reasons, are in `docs/ux-redesign/07-design-decision-log.md`: DD-43 (wallet model), DD-45 (invite and QR), DD-46 to DD-49 (rewards under the wallet, reward balance, transfer), DD-50 (page background), DD-51 (ride credit).
