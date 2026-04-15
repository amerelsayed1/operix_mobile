# 14 — Testing Strategy

## 14.1 Test Pyramid

```
         ┌────────────────┐
         │   Manual QA    │  — every release, per device matrix
         └────────────────┘
        ┌──────────────────┐
        │   E2E (Patrol)   │  — critical user flows
        └──────────────────┘
       ┌────────────────────┐
       │  Widget Tests      │  — every screen
       └────────────────────┘
     ┌──────────────────────────┐
     │       Unit Tests         │  — services, repos, business logic
     └──────────────────────────┘
```

Target split (of total test count):

- Unit: 60%
- Widget: 30%
- E2E: 8%
- Manual / exploratory: 2%

## 14.2 Unit Tests

### What to test

- Money calculations (`subtotal`, `discount`, `tax`, `grand_total`)
- Money precision (decimal)
- POS order state transitions
- Shift state transitions
- Permission guard (`has`, `hasAny`, wildcard `*`)
- API error normalization (every HTTP code → AppError mapping)
- Response envelope unwrapping
- Date/currency formatting for LTR and RTL
- Form validators

### Tooling

- `flutter_test`
- `mocktail` for mocks
- Golden tests for formatters where helpful

### Naming convention

`test/unit/{feature}/{subject}_test.dart`

### Coverage

- ≥ 90% for `core/money`, `core/permissions`, `core/network/error_normalizer`
- ≥ 70% overall

## 14.3 Widget Tests

### What to test

- Each screen renders in empty, loading, error, success states
- Forms show correct errors for invalid input
- Permission-gated buttons appear only when permission is present
- RTL layout works for every screen
- Empty states have a CTA (when permission allows)

### Tooling

- `flutter_test`
- `patrol_finders` for cleaner finders

### Pattern

```dart
testWidgets('POS Cart shows total and enables Charge button', (tester) async {
  await tester.pumpWidget(TestApp(
    initialRoute: '/pos/cart',
    overrides: [
      permissionProvider.overrideWith((_) => PermissionGuard({'pos.view', 'pos.create'})),
      cartProvider.overrideWith((_) => CartState(items: [itemFixture()])),
    ],
  ));

  expect(find.text('Charge'), findsOneWidget);
  await tester.tap(find.text('Charge'));
  await tester.pumpAndSettle();

  expect(find.byType(PaymentSheet), findsOneWidget);
});
```

### Golden Tests

- Each critical screen has a golden image for LTR and RTL.
- Regenerated only after an intentional UI change with reviewer approval.

## 14.4 E2E Tests

### Framework

**Patrol** (preferred) — supports native gestures (permissions dialog, system share).

Fallback: `integration_test` without native gestures.

### Critical Flows to Cover

| ID | Flow |
|----|------|
| E2E-001 | Login → land on home |
| E2E-002 | Login with invalid credentials |
| E2E-003 | Logout → redirect to login |
| E2E-004 | Open shift → complete POS sale (cash) → close shift |
| E2E-005 | POS sale with split payment (cash + card) |
| E2E-006 | POS sale on credit (client attached) |
| E2E-007 | POS sale with discount |
| E2E-008 | Barcode scan adds product to cart |
| E2E-009 | POS return flow |
| E2E-010 | Search client by phone → record payment |
| E2E-011 | Create client → appears in list |
| E2E-012 | Block client → cannot attach to POS |
| E2E-013 | Low stock alert appears on dashboard |
| E2E-014 | Record expense |
| E2E-015 | Account transfer (source → destination) |
| E2E-016 | Permission denied flow — cashier tries to access reports |
| E2E-017 | Session expires → forced logout |
| E2E-018 | Switch language to Arabic → UI is RTL |
| E2E-019 | Subscription suspended → SCR-152 blocks all access |
| E2E-020 | Tenant slug not found → error on first launch |

### Test Data

- Use a dedicated staging tenant with seeded fixtures.
- Reset state between runs via a staging-only endpoint (e.g., `/test-harness/reset` — not exposed in prod).
- Pre-seeded users per role: `admin@test.com`, `manager@test.com`, `cashier@test.com`, `accountant@test.com`, `stock@test.com`.

### CI

- Run E2E on each release candidate.
- Run smoke E2E (login + POS happy path) on every merge to main.

## 14.5 Manual QA Matrix

Devices to test each release:

| Device | OS | Form factor |
|--------|-----|-------------|
| iPhone SE (2nd gen) | iOS 15+ | Small phone |
| iPhone 13 | iOS 16+ | Standard phone |
| iPad Pro 11" | iPadOS 16+ | Tablet |
| Pixel 4a | Android 12+ | Standard phone |
| Samsung Galaxy A52 | Android 12+ | Standard phone |
| Samsung Galaxy Tab S7 | Android 13+ | Tablet |

### Manual scenarios

- Fresh install → tenant entry → login → home
- Kill-and-resume during POS cart (crash recovery)
- Airplane mode during sale submit (proper error)
- Slow 3G network simulation (loading states)
- Log out → log in different user → verify previous user data gone
- Log in tenant A → log out → log in tenant B → verify isolation
- Orientation rotation on tablet (POS screen)
- Dynamic type large → UI doesn't break
- Dark mode / light mode
- RTL (Arabic) exhaustive walkthrough
- Biometric login (if enabled)

## 14.6 Accessibility Testing

- Run iOS Accessibility Inspector on every screen
- Run Android Accessibility Scanner
- Manually test with VoiceOver (iOS) and TalkBack (Android)
- Ensure dynamic type max scales don't break layout

## 14.7 Performance Testing

- Use `flutter run --profile` and Flutter DevTools timeline
- Capture cold start time across reference devices
- Record API latency distribution via Sentry performance
- Memory profiling after 30 min of POS activity
- Frame rendering time — aim for 60fps during scroll

## 14.8 Security Testing

- Run MobSF (Mobile Security Framework) on release APK/IPA
- Static analysis with `dart analyze` + custom lints
- Penetration test before public launch (external firm)
- Verify JWT is encrypted at rest (inspect keychain / keystore via debugger)

## 14.9 Regression Testing

- Keep a "smoke suite" of 10 E2E tests that run on every merge to main.
- Run the **full** E2E suite nightly against staging.
- Run the full suite + manual matrix before each release candidate.

## 14.10 Test Fixtures

Shared fixtures in `test/fixtures/`:

- `fixtures/products.json` — sample products
- `fixtures/clients.json`
- `fixtures/accounts.json`
- `fixtures/pos_order_response.json`
- `fixtures/permissions_admin.json`
- `fixtures/permissions_cashier.json`

Load via:

```dart
final json = await rootBundle.loadString('test/fixtures/products.json');
final products = Product.listFromJson(jsonDecode(json));
```

## 14.11 Mocking API

Use `mocktail`:

```dart
final api = MockApiClient();
when(() => api.fetchProducts(any())).thenAnswer((_) async => productsFixture);
```

For widget tests, override providers:

```dart
ProviderScope(
  overrides: [
    apiClientProvider.overrideWithValue(api),
  ],
  child: ...,
)
```

## 14.12 Acceptance Test Traceability

Each requirement (`FR-XX-NNN`) must map to at least one test:

| Requirement | Test file |
|-------------|-----------|
| FR-00-003 (Auth) | `test/integration/auth_login_test.dart`, `E2E-001` |
| FR-02-009 (POS submit) | `test/widget/pos/cart_screen_test.dart`, `E2E-004` |
| FR-03-005 (Client profile) | `test/widget/clients/client_detail_test.dart` |
| ... | ... |

Maintain a `docs/mobile-app-srs/traceability-matrix.csv` as the SRS evolves (Phase 2).

## 14.13 Bug Bar for Release

- **Blocker:** crash on launch, data loss, security vuln, login broken, POS submit broken → hard gate.
- **Critical:** major feature broken (e.g., can't close shift, can't record payment) → release delay.
- **Major:** secondary flow broken (e.g., RTL glitch on one screen) → can ship with known-issue.
- **Minor:** cosmetic, edge case → backlog.

## 14.14 Test Coverage Report

- CI uploads coverage to Codecov / Sonarqube.
- PR fails if coverage drops > 2% versus main.
- Quarterly review of low-coverage modules.
