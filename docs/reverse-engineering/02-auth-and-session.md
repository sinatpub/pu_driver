# 02 — Auth and Session

**Scope:** boot sequence, session/token lifecycle, splash routing, login/OTP/register flows, driver approval + online/offline gating, and the debug auth bypass.

**Status:** READ-ONLY. Claims carry `CONFIRMED` / `INFERRED` / `UNCLEAR — NEEDS CONFIRMATION` + `file:line`.

---

## 1. Boot sequence

`main()` in `pu_driver/lib/main.dart:20-58` (**CONFIRMED**):

1. `BaseHttpClient.init()` — shared Dio instance (`main.dart:21`).
2. `WidgetsFlutterBinding.ensureInitialized()` (`main.dart:22`).
3. `NotificationLogic().setupInteractedMessage()` — `Firebase.initializeApp()` + FCM registration before anything else, because Crashlytics depends on Firebase (`main.dart:25`; `notification_logic.dart:15-20`).
4. Crashlytics enabled only in release (debug crashes are not collected): `setCrashlyticsCollectionEnabled(!kDebugMode)`, `FlutterError.onError` + `PlatformDispatcher.onError` wired (`main.dart:30-36`).
5. `NotificationLocal().initLocationNotification()` — local-notifications channel/booking sound (`main.dart:39`; `core/helper/local_notification_helper.dart`).
6. `EasyLocalization.ensureInitialized()`; locale defaults to `en`, supports `km`+`en` (`main.dart:40-41, 51-55`).
7. `TaxiLocation.shared.onInit()` — legacy location singleton init (`main.dart:44`).
8. `configLoading()` — EasyLoading appearance (`main.dart:46, 60-74`).
9. `await initialService()` — permanent DI (`main.dart:49`; `app/service.dart:9-12`).
10. `runApp(Root)` (`main.dart:50-57`).

`Root` (`app/root_main.dart`): `GetMaterialApp` with `EasyLoading.init()` applied through the builder (a discarded `EasyLoading.init()` previously left overlayEntry null — fixed per comment `root_main.dart:21-27`), `NavigationService` navigatorKey, `AppTheme.lightTheme`, initial route `/splash`, `AppPages.pages` (`root_main.dart:40-56`). Accessibility: `textScaler` clamped to `1.0–1.3`, no longer pinned (`root_main.dart:29-43`).

---

## 2. Session token

`SessionService` (`services/session_service.dart`) — **CONFIRMED**:

- Singleton `SessionService.instance` over `TokenStore` (`session_service.dart:7-12`).
- `getToken()`: in-memory cache → secure storage → **legacy plaintext `register_data` blob** one-time migration (`session_service.dart:20-35`; `_readLegacyToken` at `:53-56` reads `StorageGet.getDriverData().data.token`).
- `saveToken` / `clear` (`:37-45`).
- `handleUnauthorized()`: clears token, **stops the GPS stream** (`LocationService.instance.stop()`), navigates to `/login` (`session_service.dart:47-51`). Invoked from both API layers on 401 (`base_api_service.dart:123-125`, `api_client.dart:42-47`); `forbidden` (403) deliberately does **not** end the session (`api_exception.dart:30`).

---

## 3. Splash → routing

`SplashLogic` (`presentation/screens/splash_screen/logic.dart`) — **CONFIRMED**:

- 3-second splash (`splashDelay` at `:25`), requests location permission, then `checkDriverToken()` via timer (`:30-34`).
- With a token: `Taxi.shared.checkDriverAvailability()` then `Get.offNamed('/home')` (`:49-54`).
- Without a token (or any storage error): `Get.offNamed('/login')` (`:55-57`). The token check is exception-safe so a corrupt legacy blob falls to login instead of stranding the driver (comment `:11-18`).
- `checkDriverAvailability` (`taxi_single_ton/taxi.dart:55-67`) hits `getStatusDriver()` and caches `isDriverActive` into `driver_service` pref.

---

## 4. Auth endpoints

All via the new `ApiClient`/`Result` layer, `AuthDatasource` (`features/auth/data/datasource/auth_datasource.dart`) — **CONFIRMED**:

| Flow | Endpoint | Notes |
|---|---|---|
| Phone submit | `POST /taxi-driver/login-phone`, body `{phone}`, `requiresToken:false` → `PhoneNumberModel` | `auth_datasource.dart:15-23` |
| OTP verify | `POST /taxi-driver/verify-phone-otp`, body `{phone, otp_code}`, `requiresToken:false` → `RegisterModel` | `auth_datasource.dart:25-36` |
| Register | `POST /taxi-driver/register` multipart: `fullname, phone, type_vehicle_id, color, plate_number, device_token, platform` + 4 images (`card_image`, `profile_image`, `vehicle_image`, `driver_license_image`) → `RegisterModel` | `auth_datasource.dart:38-73` |

`RegisterModel` (`data/models/register_model.dart`) carries `data.driver` + `data.token`; the token is stored via `StorageSet.storeDriverData(...)` after OTP (`otp/logic.dart:132`) — so the legacy blob is the original token store, consistent with the SessionService migration bridge.

---

## 5. Login flow

`LoginLogic` (`login/logic.dart`) — **CONFIRMED**:

- Phone validation on the **unnormalised** field text: empty → shake + `isInvalidPhone`; `<10` chars → shake + `isRequired8Digit` (`:68-83`).
- `normalisePhone` strips all non-digits before the wire call — fixes formatted `"90 000 0001"` being sent verbatim (captured on device 2026-09-06); deliberately does **not** force a leading `0` (that is the passenger app's rule) (`:85-99`).
- `submit()` → `login-phone`; on ok stores `PhoneNumberModel`, sets phone in prefs, navigates `/otp` with typed `OtpPageArgs` including an `onResend` bound to the same controller (`:101-125`, `login/logic.dart:45-56`).
- UI: `+855` prefix field, digits-only input, `CardNumberInputFormatter`, `ShakeWidget`, `LoadingWidget` (`login/view.dart:127-199, 211`).

---

## 6. OTP flow

`OtpLogic` (`otp/logic.dart`) — **CONFIRMED**:

- 4-digit `Pinput`, autofocus, SMS retriever commented out (`otp/view.dart:81-84`).
- Countdown from `phoneNumberModel.data.seconde ?? 60`, resend re-enabled at 0 (`otp/logic.dart:47, 60-67`); resend calls the login controller's `onResend` (`route_arguments.dart:9-20`).
- `verify(phone, otpCode)`: debug bypass first (`DebugAuthBypass.accepts`, `otp/logic.dart:92`), else `verify-phone-otp`. Success with a driver+token → `/home`; a new/converting driver (no driver or token) → `/register` (`otp/logic.dart:71-74`). Failure clears the pin + error dialog (`:75-86`).
- `DebugAuthBypass` lives in `core/utils/debug_auth_bypass.dart`, gated by `AppConfig.debugOtpBypass` (`app_config.dart:56-63`); excluded from `dart_defines.example.json`.

---

## 7. Register flow

`RegisterLogic` (`register/logic.dart`) + view — **CONFIRMED**:

- Collects: full name, vehicle type (`SearchableDropdown<SingleVehical>` from `get-vehical`), vehicle color, plate number, plus **4 photo uploads**: driver license, ID card, profile, vehicle (`register/view.dart:119-398`; picker gallery/camera modal `:444-518`).
- `register()` posts multipart via `AuthDatasource` (section 4).
- Success → `Taxi.shared.checkDriverAvailability()` + `/home` (`register/logic.dart:55-56`).
- `VehicleController.getAllVehicles()` (`presentation/controllers/vehicle_controller.dart`) powers both register and the booking screen's per-vehicle `minimumFare`.

---

## 8. Driver approval + online/offline gating

`AppState`/`AppLogic` (`app/state.dart`, `app/logic.dart`) — **CONFIRMED**:

- `DriverApprovalStatus { unknown, pending, approved, rejected }`; mapping from `driver.status` int on `get-current-drive-info`: `0=pending, 1=approved, 2=rejected`, `unknown` default (gate fails closed) (`app/state.dart:4-23`).
- `AppLogic.toggle(turnOn)`: cannot go online unless approved; optimistic flip with rollback on error; EasyLoading shown and always dismissed (`app/logic.dart:61-75`).
- Online state from `GET /taxi-driver/check-status`; set via `POST /taxi-driver/set-status` body `{status: 1|0}` (`features/home/data/datasource/home_datasource.dart:13-26`; legacy mirrors in `data/datasources/set_status_api.dart:5-27`).
- Status type (`set_status_model.dart`): `id, userId, vehicleId, licenseNumber, rating, isAvailable` — `isAvailable == 1` means online.
- UI: online toggle (`home/widgets/switch_online_widget.dart`) shown only on the home tab (`drawer/view.dart:94-98`); un-approved drivers get a full-bottom "WAITING_APPROVED_FROM_ADMIN" overlay (`drawer/view.dart:344-379`).
- `fetchCurrentDriveInfo()` is triggered once from `DrawerLogic.onInit` and feeds **both** the approval gate and the ride-status router (`app/logic.dart:36-45`; `drawer/logic.dart:29`; `home/logic.dart:88-93`).

---

## 9. Logout

- Drawer UI logout is currently commented out (`drawer/view.dart:252-298`); `AlertWidget.logout()` (`app/alert_widget.dart:15-31`) still implements: confirm dialog → `StorageRemove.removeDriverData()` → `LocationService.instance.stop()` → `/login`.

---

## 10. Confidence summary

- **CONFIRMED:** full boot order, SessionService 3-tier token read + migration, splash routing, all three auth endpoints and payloads, OTP/register screen wiring, approval mapping, online gating, 403-vs-401 handling.
- **INFERRED:** that `verify-phone-otp` returning a driver+token vs driver-less distinguishes existing vs newly-registering drivers (from `otp/logic.dart:71-74` branch).
- **UNCLEAR — NEEDS CONFIRMATION:** the semantics of `PhoneNumberModel.data.seconde` (server-sent OTP TTL) — see `otp/logic.dart:47`; whether `register` is ever reachable in production given OTP normally returns an existing driver; whether the commented-out drawer logout should return; backend confirmation of the `driver.status` int mapping beyond the recorded client-owner statement (`app/state.dart:4-9`).