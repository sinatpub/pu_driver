# 01 — Tech Stack and Project Structure

**Scope:** what `pu_driver` is built from, how it is organised, and how the moving parts (DI, networking, storage, navigation, state management) fit together.

**Status:** READ-ONLY reverse-engineering document. All claims carry a `CONFIRMED` / `INFERRED` / `UNCLEAR — NEEDS CONFIRMATION` marker and a `file:line` citation into the current source tree.

---

## 1. Identity

| Fact | Value | Source |
|---|---|---|
| Dart package name | `tara_driver_application` | `pu_driver/pubspec.yaml:1` |
| Description | "The Tara Taxi Driver App helps drivers get ride requests, navigate with live maps, manage trips, and track earnings…" | `pu_driver/pubspec.yaml:2` |
| Version | `1.1.9+1191` | `pu_driver/pubspec.yaml:6` |
| Dart SDK constraint | `>=3.4.3 <4.0.0` | `pu_driver/pubspec.yaml:9` |
| Pinned Flutter (FVM) | `3.38.9` | `pu_driver/.fvmrc` |
| Android namespace / applicationId | `com.tara.driver_application` | `pu_driver/android/app/build.gradle.kts` (namespace + defaultConfig) |
| Android SDK levels | `compileSdk 36`, `targetSdk 35`, NDK `27.0.12077973`, Java 11, desugaring + multidex enabled | `pu_driver/android/app/build.gradle.kts` |
| iOS store bundle | `com.tara.driver.application` | `pu_driver/lib/firebase_options.dart` (`firebase_options.dart` iOS bundleId) |
| Firebase project | `taarraa-passenger` (shared with passenger app) | `pu_driver/lib/firebase_options.dart:56` |
| App display title | `TAARRAA` | `pu_driver/lib/core/utils/app_constant.dart:9` |

Environments are injected at build time via `--dart-define`/`--dart-define-from-file`, centralised in `AppConfig` — **CONFIRMED** (`pu_driver/lib/core/config/app_config.dart`):
- `API_BASE_URL` default `https://taxi-api.simpledevelopertools.com` (`app_config.dart:31-34`)
- `SOCKET_BASE_URL` default same host; Socket.IO mounted on the REST host, not a separate host (`app_config.dart:36-39`)
- `GOOGLE_MAPS_API_KEY`, `API_BEARER_TOKEN`, `TELEGRAM_BOT_TOKEN` from environment (`app_config.dart:42-51`)
- `GOOGLE_MAPS_API_KEY` is the only *required* runtime key; `missingRequiredKeys` is designed to fail configuration at startup (`app_config.dart:68-76`)
- Debug-only `DEBUG_OTP_BYPASS` / `DEBUG_LOGIN_PHONE` / `DEBUG_LOGIN_PASSWORD` (`app_config.dart:56-63`)

`AppConstant` now delegates to `AppConfig` for every environment value — one source of truth (`app_constant.dart:11-17`).

---

## 2. Third-party dependencies

From `pu_driver/pubspec.yaml:11-81` (**CONFIRMED**):

| Package | Purpose (as used in source) |
|---|---|
| `get` ^4.7.3 | State management, DI, navigation (`app_pages.dart`, every `logic.dart`) |
| `dio` ^5.7.0 | HTTP client (both API layers) |
| `pretty_dio_logger` ^1.4.0 | Request/response logging interceptor |
| `http` ^1.2.2 | Telegram error reporting (per earlier migration docs) |
| `shared_preferences` ^2.3.2 | Legacy storage + FCM token (`core/storage/*`) |
| `flutter_secure_storage` ^10.3.1 | Session token (`core/storage/token_store.dart:8`) |
| `socket_io_client` ^3.0.0 | Realtime (`services/socket_service.dart`) |
| `firebase_core` / `firebase_messaging` / `firebase_crashlytics` | Push, crash reporting (`main.dart:25-36`) |
| `geolocator` ^14.0.1 (`geolocator_android` 4.6.1 override), `geocoding`, `location` | GPS + reverse geocoding |
| `google_maps_flutter` ^2.6.1 | Maps (home, booking, history detail) |
| `flutter_polyline_points` ^2.1.0 | Directions polyline routing |
| `flutter_local_notifications` ^19.5.0 | Local booking sounds/notifications |
| `easy_localization` ^3.0.0 | km/en translations (`main.dart:51-55`) |
| `flutter_easyloading` ^3.0.5 | Loading overlays |
| `shimmer`, `flutter_svg`, `dotted_line`, `flutter_switch`, `pinput`, `dropdown_button2`, `image_picker`, `permission_handler`, `device_info_plus`, `url_launcher`, `keyboard_dismisser`, `internet_connection_checker_plus`, `logger`, `cupertino_icons` | Individual screens/widgets |

Flutter test dependency: only `flutter_test` + `flutter_lints` (`pubspec.yaml:86-91`).

---

## 3. Project structure (current, post-migration)

Top-level under `pu_driver/lib/` (**CONFIRMED** — directory listing):

```
lib/
  app/                  # permanent DI + app-lifetime controller
    main.dart           # boot sequence          (main.dart:20-58)
    root_main.dart      # GetMaterialApp shell   (root_main.dart)
    service.dart        # initialService() — the only permanent DI  (service.dart:9-12)
    logic.dart          # AppLogic — online/offline + approval + active ride
    state.dart          # AppState + DriverApprovalStatus
    alert_widget.dart   # logout / cancelBooking / onProcessBooking dialogs
    funtion_convert.dart# formatting/type-vehicle/geocoding helpers
  core/
    api_service/        # LEGACY API layer (BaseApiService + Dio client)
    config/app_config.dart
    contracts/          # booking_status.dart (server status ints), fcm_type.dart
    helper/             # local_notification_helper, get_address_latlng_helper
    network/            # NEW API layer (ApiClient, Result<T>, ApiException)
    pagination/
    resources/asset_resource.dart
    storage/            # SharedPreferences + TokenStore(secure)
    theme/              # colors, text_styles, app_theme
    utils/              # app_constant, fare_estimate, load_custom_marker, money, json_*, …
  data/
    datasources/        # LEGACY datasources still on BaseApiService (set_status, update_driver_location, get_vehical, device_info)
    models/             # register, current_driver_info, confirm_booking, complete_driver, set_status, driver_location, vehical
  features/             # DATA-ONLY feature slices
    auth/ data/         # login-phone, verify-phone-otp, register
    home/ data/         # check-status, set-status, get-current-drive-info
    trip/ data/ domain/ # trip lifecycle REST + TripStateMachine
    payment/ data/      # accept-payment
    history/ data/      # history-drive-info
    wallet/             # wallet data + wallet_presentation.dart
    notifications/ data # announcements API
    version_check/ data
    earnings/ domain/   # pure-domain earnings math (no backend)
    referral/ domain/   # pure-domain referral reward logic (no backend)
  presentation/
    controllers/        # vehicle_controller.dart
    screens/<screen>/   # {binding,logic,state,view}.dart per screen
    widgets/            # shared widgets (fbtn, countdown, dialogs, shimmer, …)
  routes/               # app_routes, app_pages, route_arguments
  services/             # socket, location, session, navigation, notification_logic
  taxi_single_ton/      # Taxi, TaxiLocation (legacy singletons)
  firebase_options.dart
```

Size: 192 Dart files under `lib/`, ~17,488 lines, 24 test files (`test/`) (**CONFIRMED** — `find … | wc -l`, test listing).

**Screens** (each a `{binding,logic,state,view}.dart` unit, per `screens/` listing): `splash_screen, login, otp, register, home, drawer, profile, history, history_detail, wallet, booking, calculate_fee, announcement, announcement_detail, term_condition, contact_us`. `profile` and `term_condition`/`contact_us` render via widgets inside the drawer shell rather than standalone `view.dart` bodies (**CONFIRMED** — `drawer/state.dart:5` `DrawerTab`, `app_pages.dart:62-76`).

---

## 4. Architecture & layers

**Clean-ish layering, GetX at the seams** — **INFERRED** from the directory shape, **CONFIRMED** in detail by these rules:

- **Presentation/feature data separation:** `features/*` are data/domain layers; screens live in `presentation/screens/<screen>/` with a strict `{binding,logic,state,view}` split (`app_pages.dart` imports bindings/views; `presentation/screens/booking/{binding,logic,state,view}.dart` all exist).
- **Screens are thin widgets** orchestrated by GetX controllers; views reach controllers via `Get.find<T>()` (e.g. `booking/view.dart:55`, `home/view.dart:29`). Controllers own `Rx` state in a sibling `state.dart`.
- **App-lifetime state** lives in exactly one `AppLogic` (`app/logic.dart:18-25`), registered permanently in exactly one place `initialService()` (`app/service.dart:9-12`). Comment cites the convention rule as `` `14` §3.5 `` (`service.dart:7`). Trip/screen state is registered per-route by a binding with `fenix: true` (e.g. `booking/binding.dart:15-29`).
- **Route args are typed classes** in `routes/route_arguments.dart` (F-06) — `BookingScreenArgs`, `OtpPageArgs`, `NotificationDetailArgs`, `MapHistoryDetailArgs`, `CalculateFeeScreenArgs`. Unpacked in bindings, not the view (`booking/binding.dart:14-24`), so views carry no route plumbing (`app_pages.dart:82-87`).
- **No BLoC remains.** Comments state controllers replace the old `HomeBloc`, `BookingBloc`, `PhoneLoginBloc`, `CurrentDriverInfoBloc`, `LocationBloc` (`app/logic.dart:7`, `booking/logic.dart:9`, `login/logic.dart:13`, `home/logic.dart:84`).
- **Data-only features** (`earnings/domain`, `referral/domain`) are pure Dart with no I/O; they are new-feature scaffolding awaiting a backend (**CONFIRMED** — `features/referral/domain/*.dart` pure enums/functions; no datasource exists).

---

## 5. Dependency injection

- **Permanent:** `Get.put<HomeRepository>…` and `Get.put<AppLogic>…` with `permanent: true` in `initialService()` (`app/service.dart:10-11`). Call sites: `main.dart:49` before `runApp`.
- **Per-route:** a binding per page registered in `AppPages.pages` (`routes/app_pages.dart:37-104`). `DrawerScreen`'s route carries all its tab bindings (`app_pages.dart:62-76`), matching the passenger app's shell pattern.
- **Singletons (static/service-style):** `DriverSocketService()` (factory singleton, `socket_service.dart:106-112`), `LocationService.instance` (`location_service.dart:15-17`), `SessionService.instance` (`session_service.dart:7-12`), `NavigationService()` (`navigation_service.dart`), `Taxi.shared` (`taxi_single_ton/taxi.dart:16-21`).

---

## 6. Networking

Two API layers coexist (**CONFIRMED**; the migration is mid-flight — `trip_datasource.dart:7-8` references an `accept-payment` still "on the old `BookingApi`" while `payment_datasource.dart` already uses `ApiClient`):

**Legacy layer** — `core/api_service/`:
- `BaseApiService.onRequest<T>` (`base_api_service.dart:20-97`): token via `SessionService` (`:36-43`), FormData conversion incl. files (`:50-63`), 401 → `SessionService.handleUnauthorized` (`:123-125`), typed exceptions `DioErrorException/ServerErrorException/ServerResponseException` (`api_service/client/http_exception.dart`).
- Dio client: single `BaseHttpClient.init()`, base URL from `AppConstant.baseUrlApi`, 1-minute timeouts, `PrettyDioLogger` interceptor (`api_service/client/dio_http_client.dart:9-25`).
- Consumers still on this layer: `data/datasources/set_status_api.dart`, `update_driver_location_api.dart`, `get_vehical_remote_data_source.dart`, `device_info_repo.dart`.

**New layer** — `core/network/`:
- `ApiClient.request<T>` returns `Result<T>` (`api_client.dart:18-51`); `DioException` → `ApiException.fromDioException`; `endsSession` true **only** for 401, explicitly not 403 (`api_exception.dart:30`, `base_api_service.dart:120-123`).
- `Result<T>` is a sealed type `ok/err` with `when()` (`result.dart:4-22`).
- Consumers: `features/trip`, `features/payment`, `features/auth`, `features/home`, `features/history`, `features/wallet`, `features/version_check` datasources.

---

## 7. Navigation

- Named routes defined in `AppRoutes` (`routes/app_routes.dart:5-18`): `/splash /login /otp /register /home /notification /notification-detail /map-history-detail /calculate-fee /booking`.
- `GetPage` table with per-page binding (`routes/app_pages.dart:37-104`); `/home` uses `Transition.noTransition` because every arrival clears the stack first (`app_pages.dart:30-33, 63-65`).
- Screens shown inline inside `DrawerScreen` (history, wallet, term-condition, contact-us, announcement/CHANNEL, profile header) have **no routes** (`app_routes.dart:2-4`).
- A `NavigationService` holds a `navigatorKey` (`services/navigation_service.dart`), wired into `GetMaterialApp` (`root_main.dart:50`).

---

## 8. Storage

- `core/storage/token_store.dart` — `TokenStore` over `FlutterSecureStorage`, key `session_token` (`token_store.dart:8`), via `SessionService` in-memory-first with a one-time legacy-blob migration bridge (`session_service.dart:20-56`).
- `core/storage/{get,set,remove}_storages.dart` — SharedPreferences-backed helpers keyed in `key_storages.dart` (`phone_number`, `driver_service`, `register_data`, `fcm_token_data`). `StorageGet.getDriverData()` deserialises the legacy `RegisterModel` blob (`get_storages.dart:22-32`); `StorageSet.storeDriverData` writes it (`set_storages.dart:31-35`).

---

## 9. State-management pattern

- GetX `Rx` values in per-screen `state.dart`; controllers mutate and expose them; views rebuild via `Obx`.
- Cross-controller reaction via `ever(...)` workers (e.g. `booking/view.dart:371-373` reacts to `lastResult`/`lastError` to drive socket emits and navigation; `login/logic.dart:36`; `calculate_fee/logic.dart:65`; `home/logic.dart:88-93`).
- Trip results are a `sealed class TripActionResult` (accepted/arrived/started/completed/cancelled) with error enum `TripActionError` (`booking/state.dart:16-47`). Deliberately non-`const` so `ever()` sees value changes (`booking/state.dart:12-15`).
- The trip *lifecycle* is a pure `TripStateMachine` (`features/trip/domain/trip_state_machine.dart`).

---

## 10. Tests

24 test files, organised mirror of `lib/` (**CONFIRMED** — `test/` recursive listing):

- `core/`: `app_config_test`, `booking_status_test`, `api_exception_test`, fare/currency/json helpers.
- `taxi_single_ton/`: `socket_event_contract_test.dart` (pins the 9 wire event strings) and `socket_emit_contract_test.dart` (pins payload shapes + reconnection policy).
- `features/`: `trip/domain/trip_state_machine_test`, `trip/data/new_ride_payload_parser_test`, referral (7 files), earnings, wallet (2), history models.
- `presentation/`: `booking/logic_test`, `login/logic_test`.
- `app/`: `format_riel_amount_test`.

Note: `flutter test` cannot run in this environment — `flutter_tester` is absent from the local Flutter SDK cache (see session notes). This is an environment limitation, **not** a codebase defect.

---

## 11. Confidence summary

- **CONFIRMED by source:** identity, build config, dependency set, directory layout, DI registration, both API layers, route table, storage keys, state-management pattern, test inventory, socket contract (also pinned by tests), booking-status int mapping, trip-state machine.
- **INFERRED:** "clean layering" intent (creatable from comments but not enforced by analysis), server behaviour from client code.
- **UNCLEAR — NEEDS CONFIRMATION:** whether the old `data/datasources/confirm_booking_api.dart` still exists (referenced by `trip_datasource.dart:7-8` but absent from the tree — the reference is now stale since `payment_datasource.dart` owns `accept-payment`); exact WhatsApp/Telegram error-reporter wiring; whether any staged/multi-flavour build exists (scaffolding explicitly deferred pending Q-12/Q-13, `app_config.dart:8-12`).