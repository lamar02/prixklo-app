# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter run                          # Run on connected device/emulator
flutter build apk                    # Build Android APK
flutter analyze                      # Static analysis (flutter_lints)
flutter test                         # Run all tests
flutter test test/path/to_test.dart  # Run a single test file
flutter pub get                      # Install dependencies
flutter pub upgrade                  # Upgrade dependencies
```

## Architecture

**PrixKlo** is a Flutter 3.x app for citizen price monitoring in Côte d'Ivoire. Citizens report abusive prices, earn gamification points, and view a map of violations.

### GetX Module Structure

Every feature follows the strict **Binding → Controller → View** pattern:

```
lib/
├── main.dart                    ← GetMaterialApp, StorageService init, ConnectivityService
└── app/
    ├── core/
    │   ├── app_binding.dart     ← AppBinding: ApiService + AuthController (permanent)
    │   ├── theme/app_theme.dart ← AppColors + AppTheme.light (Material 3, DM Sans font)
    │   └── utils/               ← connectivity_util.dart, date_formatter.dart
    ├── data/
    │   ├── models/              ← Plain Dart models with fromJson/toJson
    │   └── providers/           ← offline_queue_model.dart
    ├── routes/
    │   ├── app_routes.dart      ← abstract class AppRoutes { static const ... }
    │   └── app_pages.dart       ← AppPages.pages list of GetPage
    ├── services/
    │   ├── api_service.dart     ← GetConnect singleton, all HTTP calls
    │   ├── storage_service.dart ← SharedPreferences wrapper (GetxService)
    │   └── connectivity_service.dart ← reactive online/offline state
    └── modules/<module>/
        ├── bindings/            ← <Module>Binding extends Bindings
        ├── controllers/         ← <Module>Controller extends GetxController
        └── views/               ← <Module>View extends GetView<Controller>
```

### App Bootstrap Sequence

1. `StorageService` is initialized synchronously before `runApp` via `Get.putAsync`
2. `ConnectivityService` is put permanently (drives global offline overlay in `main.dart`)
3. `AppBinding` registers `ApiService` + `AuthController` as permanent singletons
4. `SplashController.onReady()` decides the initial route: onboarding → login → main

### Navigation & Routes

| Route | Module |
|---|---|
| `/` | splash |
| `/onboarding` | onboarding |
| `/login`, `/register` | auth (AuthController already permanent) |
| `/main` | main_nav (IndexedStack, 4 tabs: Home/Map/Report/Profile) |
| `/history` | history |
| `/leaderboard` | leaderboard |

`MainNavBinding` lazy-puts all 4 tab controllers at once. Tabs persist in memory once built (`IndexedStack`).

### Services

**`ApiService`** (`GetConnect`):
- Base URL: `https://prixklobackend.vercel.app/api`
- 8s timeout; auto-injects `Authorization: Bearer <token>` on every request
- On `401`: clears token + `Get.offAllNamed('/login')`

**`StorageService`** (`GetxService`, SharedPreferences):
- `token` / `saveToken()` / `clearToken()` → key `auth_token`
- `onboardingDone` / `markOnboardingDone()` → key `onboarding_done`
- `pendingReports` / `savePendingReports()` → key `pending_reports` (offline queue)

**`ConnectivityService`**:
- Exposes `isOnline` (`RxBool`); the root widget wraps everything in an `Obx` that overlays a "no connection" screen when offline

### Key Implementation Patterns

**Reactive state:**
```dart
final field = value.obs;   // declare
field.value = newVal;      // update
Obx(() => Text('${field.value}'))  // react
```

**Dependency injection:**
```dart
Get.lazyPut<T>(() => T())          // in bindings (lazy)
Get.put<T>(T(), permanent: true)   // for app-lifetime singletons
Get.find<T>()                      // retrieve anywhere
```

**`ever()` reactions** (used heavily in `ReportController`): trigger side-effects whenever an observable changes, e.g. auto-fetch price summary when packaging or GPS state changes.

### Report Wizard (3-step flow)

`ReportController` manages the entire wizard state:
- **Step 0** — Product selection + packaging chips; GPS starts silently on product select
- **Step 1** — Price entry + optional photo (camera or gallery, 75% quality); GPS starts if not ready
- **Step 2** — Location display + submit; "Send" disabled until `hasLocation.value == true`

On submit: checks `ConnectivityUtil.isOnline()` → if offline, enqueues `PendingReport` to `StorageService`; if online, POSTs JSON or multipart (with photo). On success (201): refreshes gamification points via `AuthController.updatePoints()`, then flushes the offline queue.

`ReportController.preSelect()` allows the PriceCheck module to pre-fill the wizard and jump to step 2 or 3.

### flutter_map / MapController Name Conflict

`flutter_map` exports `MapController`, which conflicts with the app's own `MapController`:
- In `map_view.dart`: `import 'package:flutter_map/flutter_map.dart' hide MapController;`
- In `map_controller.dart`: `import 'package:flutter_map/flutter_map.dart' as flutter_map;`
- Typedef alias: `typedef AppMapController = app_map.MapController;`

### Theme

All colors are in `AppColors` (abstract class, `app_theme.dart`):
- Primary: `#F97316` (orange)
- Secondary: `#1E3A5F` (navy)
- `success` / `abus` / `unknown` for report status coloring
- Font: DM Sans via `google_fonts`
- Material 3 enabled

### Offline Queue

`PendingReport` is serialized to JSON strings in `StorageService.pendingReports`. `ReportController._flushOfflineQueue()` runs on `onInit()` and after every successful submission, retrying each queued report and removing only the ones that succeed (201).

### Gamification

Points update locally after each successful submission without a full re-fetch — `AuthController.updatePoints(points, level)` takes the values returned in the gamification endpoint response called inside `ReportController._refreshUserPoints()`.
