# 07 — Design Tokens and Assets

**Scope:** the visual language of the driver app — colors, typography, Material theme, asset inventory, locale files, and how strings/assets are consumed.

**Status:** READ-ONLY. Claims carry `CONFIRMED` / `INFERRED` / `UNCLEAR — NEEDS CONFIRMATION` + `file:line`.

---

## 1. Colors

`core/theme/colors.dart` (`AppColors`) — **CONFIRMED**:

| Token | Hex | Notes |
|---|---|---|
| `main` | `0xFFFF4500` | brand orange — primary CTA |
| `red` | `0xFFFF1100` | payment/drop/price accents |
| `darker` | `0xFFCC3700` | main-dark |
| `lighter` | `0xFFFFA84C` | main-light |
| `subtitle` | `0xFFFFA07A` | |
| `error` | `0xFFD32F2F` | |
| `info` | `0xFF1976D2` | wallet blue accents (total price in-trip, distance strip) |
| `success` | `0xFF10CF7C` | wallet balance green |
| `dark1..dark4` | `0xFF3A3A3C / 6B7588 / 8F90A6 / C7C9D9` | text scale |
| `light1..light4` | `0xFFE2E2E5 / EBEBF0 / F2F2F5 / FAFAFC` | surfaces |

Material theme (`core/theme/app_theme.dart`): `useMaterial3: true`, `primaryColor: main`, `scaffoldBackgroundColor: light4` (`app_theme.dart:5-25`).

---

## 2. Typography

`core/theme/text_styles.dart` — **CONFIRMED**:

- Font family **KantumruyPro** (Khmer-capable): `KantumruyPro-Regular.ttf`, `KantumruyPro-SemiBold.ttf`, `KantumruyPro-VariableFont_wght.ttf` (registered in `pubspec.yaml:121-130`).
- `ThemeConstands` (legacy table, `text_styles.dart:17-62`) — sizes 10/12/14/16/18/20/22/24/28 × Regular/SemiBold. Quirk (**UNCLEAR—flagged**): `font10SemiBold` is actually size **14.0**, mislabeled (`text_styles.dart`).
- `AppTextStyles` (newer set, `text_styles.dart:3-15`): `heading` (24 bold), `body` (16 regular).
- Both tables are used across screens (e.g. `ride_request_bottom_pop_widget.dart:144-150` uses `ThemeConstands`, `:108` uses `AppTextStyles.body`).

---

## 3. Asset inventory

`core/resources/asset_resource.dart` (`ImageAssets`) + `pubspec.yaml:99-118` (**CONFIRMED**):

| Category | Assets |
|---|---|
| Nav icons `assets/nav_icon/` | `profile(.svg/_fill)`, `book(.svg/_outline)`, `home`, `home-angle-2-svgrepo-com` |
| Icon SVGs `assets/icon/svg/` | logout, dashboard, pin-outline, date-time, time-out, payment-out, current-location, map-out, no-image, waiting-approve, license/ID/vehicle/profile upload icons, bxs-map |
| Icon PNGs `assets/icon/png/` | `flag-en.png`, `logo_app.jpg` |
| Image PNGs `assets/image/png/` | `image_map.png`, `placeholder.jpg`, `contact_image.png`, `Tara2.png`, `company_logo.png` |
| Country flags `assets/image/country/` | Cambodia/Thailand/Vietnam/UK SVGs + Laos PNG (language picker) |
| Markers `assets/marker/` | `destination_icon`, `car_marker`, `rickshaw_icon_svg`, `alphard_vip`, `passenger_marker`, `Rickshaw`, `taxi_marker.svg`, `mini_van`, `classis_car`, `SUV` |
| Sounds `assets/sounds/` | `booking_sound.wav` |
| Fonts `fonts/` | 3× KantumruyPro |

Marker ↔ vehicle-type mapping consumed in `core/utils/load_custom_marker.dart:20-36` and `app/funtion_convert.dart:97-107` (types 1–5).

---

## 4. Localization

- Files: `assets/translations/en.json` (98 lines) and `km.json` (97 lines); registered in `pubspec.yaml:115-118`; `supportedLocales [Locale('km'), Locale('en')]`, `startLocale en` (`main.dart:52-54`).
- `eacsy_localization` runtime set-up at boot (`main.dart:40-41`); `AppConstant.khmerCode/englishCode` constants (`app_constant.dart:6-7`).
- Representitive booking strings (`en.json`, consumed at the cited lines): `NEW_RIDE_REQUEST` / `GO_TO_PASSENGER` / `PREPAIR_TO_GO` / `CARRYING_PASSENGER` (`booking/view.dart:611-620`), `ACCEPT`/`ARRIVE`/`START_RIDE`/`DROP` (`ride_request_bottom_pop_widget.dart:327-336`), `CANCEL_BOOK`/`CONTANCT_CELCEL_BOOK` (`:352-353`), `PAYMENT_DONE`/`CALCULATE_FEE`/`TOTAL_PRICE` (`calculate_fee/view.dart`), `ONLINE`/`OFFLINE` (`switch_online_widget`), `WAITING_APPROVED_FROM_ADMIN` (`drawer/view.dart:344-379`), `NO_INTERNET_CONNECTION` (`drawer/view.dart:321-343`), `NOTIFICATION` channel labels (`notification_logic.dart`).
- Push/notification copy keys: `NEWREQUEST`/`DESREQUEST` (`socket_service.dart:165-168`), `ACCEPT`/`DESACCEPT`, `ARRIVE`/`DESARRIVED`, `START_RIDE`/`DESSTART`, `COMPLETE_RIDE`/`DESCOMPLED` (`booking/logic.dart:46-49, 88-91, 109-112, 142-145`).
- Source files are hand-maintained `.json` (no ARB pipeline) — **INFERRED** from repo layout.

---

## 5. UX-visible constants

- Fare/format helpers (`app/funtion_convert.dart`): `formatRielAmount` (thousands, `៛` prefix), `formatWalletAmountWithSymbol`, `formatDuration` (HH:MM:SS), `formatDateTime`, `getDurationFromDistance`, `convertMaterToKm`, `convertKmToKmM`, `formatDistanceWithUnits`.
- Vehicle-type labels `typeVehicle()`: Rickshaw / Classic Car / Mini Van / SUV / Alphard VIP (`funtion_convert.dart:97-107`).
- Countdown default `timeOut:30` for resumes (`home/logic.dart:241`); request timeout from the payload (`route_arguments.dart`/`new_ride_payload_parser.dart:50`).

---

## 6. Confidence summary

- **CONFIRMED:** color/text tables, theme config, all asset paths, font families, locale set + keys consumed at the cited call sites, vehicle-type label mapping.
- **UNCLEAR — NEEDS CONFIRMATION:** `font10SemiBold` size 14 quirk (keep or fix); whether the `TELEGRAM_BOT_TOKEN`-backed error reporter posts Khmer or English copy; whether more strings exist untranslated in `km.json` (only key-count sampled here); whether `assets/translations/` contains any locale beyond km/en in practice (`main.dart:52` lists only km/en).