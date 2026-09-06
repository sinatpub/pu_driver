# tara_driver_application

Driver app for the Taarraa taxi platform. Currently mid-migration from BLoC to GetX — see
`../.agent/` in the parent `pu_taxi_system/` repo for the modernization plan, architecture
target, and current status. This file describes what's actually in the tree today, not an
aspirational template.

## Actual architecture (as of this migration)

This app started from a generic "Clean Architecture + BLoC + get_it" boilerplate, but that
template was never really followed — `get_it`'s `injection_container.dart` is dead code
(`init()` is never called), and `lib/domain/` contains only an abandoned coffee-shop
tutorial, not real feature logic. Treat any reference to that template (including in old
commit history or design docs) as stale.

What's actually here, mid-migration:

- **Screens migrated to GetX** (`GetxController` + injected repositories) as each feature
  is ported — see `.agent/PROGRESS.md` in the parent repo for what's done.
- **Remaining BLoC screens** — `MultiBlocProvider`-provided blocs in
  `lib/presentation/blocs/`, being collapsed/ported per `.agent/skills/getx-migration.md`.
- **Trip lifecycle** — extracted from `setState` inside `booking_screen.dart` into an
  explicit `TripStateMachine` + `TripController` (GetX), with unit tests. This was the
  highest-risk piece of the app; see `.agent/PROGRESS.md` D-06 for how it was done.
- **`core/contracts/`** — shared booking-status, FCM-type, and socket-event constants.
  **Note:** the booking-status mapping here is a client-owner-supplied assumption, not yet
  backend-confirmed — see `.agent/DECISIONS.md` Q-1 before relying on it.

For the target end-state (folder layout, layer responsibilities, GetX pattern), see
`.agent/skills/architecture.md` in the parent repo.

## Secrets

Runtime secrets are compiled in via `--dart-define-from-file`, not hardcoded. Copy
`dart_defines.example.json` to `dart_defines.json`, fill in real values, then:

```sh
flutter run --dart-define-from-file=dart_defines.json
flutter build apk --dart-define-from-file=dart_defines.json
flutter build ios --dart-define-from-file=dart_defines.json
```

`dart_defines.json` is gitignored — never commit it. CI should inject it from a secrets
store at build time.

**Current coverage:** `API_BASE_URL` and `SOCKET_BASE_URL` are overridable via
`--dart-define`, defaulting to production if unset — so an ordinary build is unaffected.
`API_BEARER_TOKEN` and `GOOGLE_MAPS_API_KEY` are env-only (no hardcoded fallback).

**This does not mean credential hygiene is resolved.** The *old* values that were
previously hardcoded in source (Google Maps key, Telegram bot token, a bearer token) have
been committed to this repo's history and a public-facing remote, and **have not been
rotated**. See `.agent/PLAN.md` Phase 0.1 in the parent repo — that's still outstanding and
is the single highest-priority open item independent of any feature work.

## Getting started

Standard Flutter project. Target Flutter `3.38.9` per `.fvmrc`, SDK `>=3.4.3 <4.0.0`.
`flutter analyze`'s analysis server is broken in this dev environment — use
`dart analyze <path>` instead (see `.agent/skills/flutter-dart.md`).
