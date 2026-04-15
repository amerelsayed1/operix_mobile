# 10 — Mobile Tech Stack & Project Structure

## 10.1 Recommendation

**Primary recommendation: Flutter.**

Rationale:

- Single codebase for iOS and Android
- Strong performance (no JS bridge) — important for POS responsiveness
- Mature RTL support
- Ecosystem has native-quality widgets (barcode scanning, secure storage, biometrics, local DB)
- Smaller team size can ship faster
- Arabic and RTL tested widely in MENA deployments

**Alternative: React Native** (if team has existing React expertise)

- Use **Expo SDK 50+** for managed workflow or bare RN with CNG (Continuous Native Generation)
- Equivalent ecosystem maturity
- Re-use of logic from Vue web is minimal — not a decision driver

**Not recommended:**

- **Native iOS + Native Android** — doubles cost for no visible UX benefit at current scale
- **Ionic / Capacitor** — web-view performance unacceptable for POS

The remainder of this document assumes **Flutter**. If React Native is chosen, the package choices are equivalent and identified.

## 10.2 Flutter Version & Language

- **Flutter:** stable channel (currently 3.19+)
- **Dart:** 3.x
- **Minimum SDK:** Android 24 (Nougat), iOS 14

## 10.3 Core Packages

### State management

- `flutter_riverpod` ^2.5 — primary state solution (alternative: `flutter_bloc`)

### Navigation

- `go_router` ^14 — declarative routing, deep links, shell routes per tab

### HTTP

- `dio` ^5 — with interceptors for auth, tenant-slug injection, error normalization
- `retrofit` + `json_serializable` — typed API client

### Persistence

- `flutter_secure_storage` ^9 — JWT + tenant slug
- `shared_preferences` ^2 — non-sensitive prefs (locale, last tenant)
- `drift` ^2 (SQLite) — local cache for products, clients lookups
- `hive` ^2 — lightweight KV cache (permissions snapshot, tenant config)

### UI

- `google_fonts` — for Arabic-capable fonts (Cairo / IBM Plex Sans Arabic)
- `flutter_svg` — tenant logos, icons
- `cached_network_image` — product & avatar images
- `shimmer` — skeleton loaders
- `flutter_animate` — micro-interactions

### Charts

- `fl_chart` ^0.68 — dashboard trends, report charts

### Barcode

- `mobile_scanner` ^5 — camera barcode reader (supports QR, EAN, UPC)

### Forms

- `flutter_hooks` + `reactive_forms` — typed form state and validation

### Money / Decimal

- `decimal` ^2 — arbitrary-precision arithmetic
- `intl` ^0.19 — number, currency, date formatting

### Localization

- `flutter_localizations`
- `intl_utils` — generate message classes from ARB files
- Arabic requires bidirectional (`BidiFormatter`) handling for mixed LTR/RTL strings

### Images & Files

- `image_picker` — avatar, receipt photos
- `image` — compression
- `file_picker` — CSV imports (Phase 2)

### Security & Device

- `local_auth` — biometrics
- `device_info_plus` — device metadata for registration
- `package_info_plus` — app version
- `connectivity_plus` — online/offline detection

### Analytics & Crash

- `sentry_flutter` — crash reporting
- `firebase_analytics` — events
- `firebase_crashlytics` — backup crash channel

### Notifications (Phase 2)

- `firebase_messaging` — FCM/APNs
- `flutter_local_notifications` — in-app reminders

### Testing

- `flutter_test` (widget tests)
- `mocktail` (mocking)
- `integration_test` (E2E)
- `patrol` — enhanced E2E for native gestures

## 10.4 Project Structure

```
operix_mobile/
├── android/
├── ios/
├── lib/
│   ├── main.dart                      # bootstrap entry
│   ├── app/
│   │   ├── app.dart                   # root widget, theming
│   │   ├── router.dart                # go_router config
│   │   ├── theme/
│   │   │   ├── theme.dart             # light/dark theme
│   │   │   └── tenant_theme.dart      # dynamic primary color
│   │   └── providers/                 # app-wide riverpod providers
│   ├── core/
│   │   ├── network/
│   │   │   ├── dio_client.dart        # Dio setup + interceptors
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── tenant_interceptor.dart
│   │   │   ├── error_normalizer.dart
│   │   │   └── api_result.dart
│   │   ├── storage/
│   │   │   ├── secure_storage.dart
│   │   │   └── preferences.dart
│   │   ├── errors/
│   │   │   ├── api_error.dart
│   │   │   └── error_mapper.dart
│   │   ├── i18n/
│   │   │   └── gen/                   # generated
│   │   ├── permissions/
│   │   │   ├── permission_set.dart
│   │   │   └── permission_guard.dart
│   │   ├── money/
│   │   │   └── money.dart
│   │   └── widgets/                   # shared atoms
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       ├── app_skeleton.dart
│   │       ├── empty_state.dart
│   │       └── error_state.dart
│   └── features/                      # feature-sliced modules
│       ├── auth/
│       │   ├── data/                  # API, repositories
│       │   ├── domain/                # entities, use-cases
│       │   └── presentation/          # screens, widgets, providers
│       ├── tenant_config/
│       ├── dashboard/
│       ├── pos/
│       ├── shifts/
│       ├── clients/
│       ├── products/
│       ├── inventory/
│       ├── expenses/
│       ├── accounts/
│       ├── suppliers/                 # Phase 2
│       ├── purchases/                 # Phase 2
│       ├── sales_invoices/            # Phase 2
│       ├── reports/                   # Phase 3
│       └── profile/
├── assets/
│   ├── images/
│   ├── icons/
│   └── i18n/
│       ├── en.arb
│       └── ar.arb
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
└── pubspec.yaml
```

### Feature-sliced layout (per feature)

```
features/clients/
├── data/
│   ├── client_api.dart               # Retrofit-generated
│   ├── client_repository.dart
│   └── client_dto.dart               # JSON mapping
├── domain/
│   ├── client.dart                   # entity (immutable)
│   ├── usecases/
│   │   ├── fetch_clients.dart
│   │   ├── record_client_payment.dart
│   │   └── block_client.dart
│   └── providers.dart                # riverpod providers
└── presentation/
    ├── screens/
    │   ├── clients_list_screen.dart
    │   ├── client_detail_screen.dart
    │   ├── client_form_screen.dart
    │   └── record_payment_screen.dart
    ├── widgets/
    │   ├── client_card.dart
    │   └── client_kpi_row.dart
    └── controllers/
        └── clients_controller.dart   # riverpod notifiers
```

## 10.5 Dio Configuration Blueprint

```dart
Dio buildDio(Ref ref) {
  final baseUrl = ref.read(envProvider).apiBaseUrl;

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'X-Client': 'operix-mobile-${kAppVersion}',
    },
  ));

  dio.interceptors.addAll([
    TenantInterceptor(ref),     // injects /api/v1/{tenant_slug}/
    AuthInterceptor(ref),       // injects Bearer {jwt}
    LocaleInterceptor(ref),     // Accept-Language: en|ar
    ErrorInterceptor(ref),      // normalizes 4xx/5xx and triggers logout/billing flows
    if (kDebugMode) LogInterceptor(),
  ]);

  return dio;
}
```

## 10.6 Tenant Interceptor

```dart
class TenantInterceptor extends Interceptor {
  TenantInterceptor(this.ref);
  final Ref ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = ref.read(sessionProvider);
    final slug = session.tenantSlug;

    // Only inject when the path is relative and not a public auth endpoint
    final needsTenantPrefix = !options.path.startsWith('/api/v1/')
        && !options.path.startsWith('http');

    if (needsTenantPrefix && slug != null) {
      options.path = '/api/v1/$slug/${options.path.replaceFirst(RegExp(r"^/"), "")}';
    }
    handler.next(options);
  }
}
```

## 10.7 Auth Interceptor

```dart
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.ref);
  final Ref ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ref.read(sessionProvider).token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      ref.read(sessionProvider.notifier).logout(reason: SessionEndReason.expired);
    }
    handler.next(err);
  }
}
```

## 10.8 Permission Guard

```dart
class PermissionGuard {
  PermissionGuard(this.permissions);
  final Set<String> permissions;

  bool has(String perm) =>
      permissions.contains('*') || permissions.contains(perm);

  bool hasAny(Iterable<String> perms) =>
      permissions.contains('*') || perms.any(permissions.contains);
}

// Usage in widgets
final can = ref.watch(permissionGuardProvider);
if (can.has('pos.create')) { ... }
if (can.hasAny(['clients.view', 'pos.clients'])) { ... }
```

## 10.9 Theme & Tenant Branding

- Derive `ColorScheme` from `theme_primary_color` using `ColorScheme.fromSeed(seedColor: tenantColor)`.
- Apply `TextDirection.rtl` when `locale == 'ar'`.
- Font families:
  - Latin: `Inter` or `SF Pro`
  - Arabic: `Cairo`

## 10.10 Environment Configuration

Use `--dart-define` build flags:

```
flutter build apk --dart-define=API_BASE=https://api.operix.com --dart-define=ENV=prod
```

Env keys:

- `API_BASE` — base URL
- `ENV` — `dev` | `staging` | `prod`
- `SENTRY_DSN` — if enabled
- `FCM_PROJECT_ID`

Separate flavor per env:

- `android/app/src/dev/`, `staging/`, `prod/` AndroidManifest overrides for app id suffix
- iOS: `.xcconfig` per scheme

App IDs:

- `com.operix.app.dev`
- `com.operix.app.staging`
- `com.operix.app`

## 10.11 CI / CD

Recommended: **GitHub Actions + Codemagic** (or Bitrise).

Stages per PR:

1. Checkout + cache
2. `flutter pub get`
3. `flutter analyze`
4. `flutter test`
5. Build preview APK (for Android reviewers)

Stages on tag:

1. All of the above
2. Build signed APK + AAB for Play
3. Build IPA for App Store Connect via Fastlane
4. Upload to Firebase App Distribution (beta) and the respective stores

## 10.12 Versioning

- App version follows SemVer `major.minor.patch`.
- Build number auto-incremented per CI run.
- `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

## 10.13 Package Checklist (pubspec.yaml skeleton)

```yaml
name: operix_mobile
description: Operix tenant mobile app
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.0.0
  dio: ^5.4.0
  retrofit: ^4.1.0
  json_annotation: ^4.8.1
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.18
  hive: ^2.2.3
  cached_network_image: ^3.3.1
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0
  fl_chart: ^0.68.0
  mobile_scanner: ^5.0.0
  reactive_forms: ^17.0.0
  flutter_hooks: ^0.20.5
  decimal: ^2.3.3
  intl: ^0.19.0
  google_fonts: ^6.2.1
  local_auth: ^2.1.8
  device_info_plus: ^10.0.0
  package_info_plus: ^5.0.1
  connectivity_plus: ^6.0.0
  image_picker: ^1.0.7
  image: ^4.1.7
  sentry_flutter: ^8.0.0
  firebase_core: ^2.27.0
  firebase_analytics: ^10.10.0
  firebase_crashlytics: ^3.5.0
  firebase_messaging: ^14.7.20
  flutter_local_notifications: ^17.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.3
  build_runner: ^2.4.8
  retrofit_generator: ^8.0.2
  json_serializable: ^6.7.1
  drift_dev: ^2.14.1
  intl_utils: ^2.8.7
  flutter_lints: ^3.0.1
  patrol: ^3.6.0

flutter:
  uses-material-design: true
  generate: true   # for ARB
  assets:
    - assets/images/
    - assets/icons/
```

## 10.14 React Native Mirror (if chosen)

| Flutter package | RN equivalent |
|-----------------|---------------|
| dio | axios |
| riverpod | zustand / redux-toolkit |
| go_router | react-navigation |
| drift | watermelonDB / realm |
| flutter_secure_storage | react-native-keychain |
| mobile_scanner | react-native-vision-camera + vision-camera-code-scanner |
| fl_chart | victory-native |
| intl | i18next / react-intl |
| local_auth | react-native-biometrics |
| firebase_messaging | @react-native-firebase/messaging |
| sentry_flutter | @sentry/react-native |

## 10.15 Suggested First-Week Setup Checklist

- [ ] Create Flutter project with flavors (dev/staging/prod)
- [ ] Wire Dio + interceptors
- [ ] Build tenant slug screen + login screen
- [ ] Implement session provider + secure storage
- [ ] Bootstrap flow (`/me`, `/me/permissions`, `/config`) in parallel
- [ ] Set up Riverpod + go_router skeleton
- [ ] Integrate Sentry + Firebase
- [ ] Set up CI pipeline on GitHub Actions
- [ ] Create theme with tenant color seeding
- [ ] Add en/ar ARB files + hot-swap
- [ ] Stub every screen (empty + title) as route for walkable navigation QA
