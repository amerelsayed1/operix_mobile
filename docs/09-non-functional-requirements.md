# 09 — Non-Functional Requirements

## 9.1 Performance

| NFR-ID | Requirement | Target |
|--------|-------------|--------|
| NFR-P-001 | Cold start to first usable screen | ≤ 3s on 4G, mid-range device (iPhone 11 / Pixel 4a) |
| NFR-P-002 | Warm start to home | ≤ 1.5s |
| NFR-P-003 | POS product search response | ≤ 300ms from keystroke settle |
| NFR-P-004 | POS order POST latency (P95) | ≤ 1s |
| NFR-P-005 | Barcode scan → cart addition | ≤ 500ms from scan |
| NFR-P-006 | Screen navigation transition | ≤ 100ms |
| NFR-P-007 | API request timeout | 30s (configurable) |
| NFR-P-008 | List infinite-scroll next page | ≤ 600ms |
| NFR-P-009 | Image loading | progressive with placeholder |
| NFR-P-010 | App memory footprint | ≤ 250MB typical, ≤ 500MB peak |

## 9.2 Reliability

| NFR-ID | Requirement | Target |
|--------|-------------|--------|
| NFR-R-001 | Crash-free users | ≥ 99.5% |
| NFR-R-002 | Crash-free sessions | ≥ 99.8% |
| NFR-R-003 | API transient failure recovery | Auto-retry safe GETs with backoff |
| NFR-R-004 | Mutation retry | Never auto-retry POST/PUT/PATCH/DELETE |
| NFR-R-005 | Session recovery | Re-login without data loss |
| NFR-R-006 | Uncaught exception handling | Global handler reports to Sentry without showing raw stack |

## 9.3 Security

| NFR-ID | Requirement |
|--------|-------------|
| NFR-S-001 | JWT stored in OS-native secure storage (Keychain / EncryptedSharedPreferences). Never in plain storage. |
| NFR-S-002 | All network traffic over TLS 1.2+. |
| NFR-S-003 | Certificate pinning recommended (Phase 2); must not break on cert rotation. |
| NFR-S-004 | No sensitive logs (PII, tokens) in crash reporter breadcrumbs. |
| NFR-S-005 | Clipboard clears after paste of sensitive fields (passwords, IBAN). |
| NFR-S-006 | Biometric lock (Face ID / Touch ID / Fingerprint) optional, togglable in Profile. |
| NFR-S-007 | App goes into privacy-screen mode when backgrounded (iOS snapshot, Android FLAG_SECURE). |
| NFR-S-008 | No screenshotting of Payment / Receipt screens (FLAG_SECURE on Android). |
| NFR-S-009 | Rooted / jailbroken devices show a warning but are not blocked (config-driven). |
| NFR-S-010 | OWASP Mobile Top 10 risks reviewed before launch. |
| NFR-S-011 | Deep links validated against whitelist. No open-redirect vulns. |

## 9.4 Privacy & Compliance

| NFR-ID | Requirement |
|--------|-------------|
| NFR-PR-001 | No PII (name, email, phone) in non-crash analytics events. |
| NFR-PR-002 | User IDs hashed before sending to 3rd-party analytics. |
| NFR-PR-003 | GDPR-style deletion: on logout, wipe all cached data. |
| NFR-PR-004 | Privacy policy accessible from login and profile. |
| NFR-PR-005 | App Store & Play Store data-usage labels must accurately reflect telemetry. |

## 9.5 Usability

| NFR-ID | Requirement |
|--------|-------------|
| NFR-U-001 | Minimum tap target 44×44 pt (iOS) / 48×48 dp (Android). |
| NFR-U-002 | Text contrast ≥ 4.5:1 (WCAG AA). |
| NFR-U-003 | Dynamic type — respect OS text-size preference. |
| NFR-U-004 | All inputs use the appropriate keyboard (email, number, phone). |
| NFR-U-005 | Errors near the field that caused them, not just a top banner. |
| NFR-U-006 | Loading states never block for > 1s without a spinner/skeleton. |
| NFR-U-007 | Haptic feedback on POS success and errors. |
| NFR-U-008 | Undo available for non-destructive removals (cart item, etc.) for 3s. |
| NFR-U-009 | Arabic (RTL) parity — no swapped icons/arrows, consistent padding. |
| NFR-U-010 | Consistent bottom-nav placement; no hidden top nav. |

## 9.6 Accessibility (WCAG 2.1 AA target)

| NFR-ID | Requirement |
|--------|-------------|
| NFR-A-001 | Every interactive element has an accessible label. |
| NFR-A-002 | Screen reader navigation order matches visual order. |
| NFR-A-003 | Color is never the sole indicator of status — always paired with icon or text. |
| NFR-A-004 | Focus indicators visible in keyboard navigation. |
| NFR-A-005 | Minimum font size 14pt for body text. |
| NFR-A-006 | Touch targets separated by ≥ 8pt. |

## 9.7 Internationalization (i18n) & RTL

| NFR-ID | Requirement |
|--------|-------------|
| NFR-I-001 | All user-facing strings externalized to i18n JSON (en, ar). |
| NFR-I-002 | Every new key added in both `en` and `ar`. |
| NFR-I-003 | RTL mirroring applies to layout, scroll, and icon direction where appropriate. |
| NFR-I-004 | Numbers, dates, and currencies formatted per locale + tenant currency. |
| NFR-I-005 | Language switch is hot — no app restart required. |
| NFR-I-006 | The mobile app pulls the master i18n file from the web frontend (`business-finance-manager-frontend/apps/tenant-app/src/locales/*.json`) as source of truth for feature strings. |

## 9.8 Compatibility

| NFR-ID | Requirement |
|--------|-------------|
| NFR-C-001 | iOS: support iOS 14+. |
| NFR-C-002 | Android: support API 24 (Android 7.0)+. |
| NFR-C-003 | Device types: phone + tablet (iPad supported; responsive layouts). |
| NFR-C-004 | Orientation: portrait default; landscape optional on tablet. |
| NFR-C-005 | Test on at least 5 reference devices: iPhone SE, iPhone 13, iPad Pro 11", Pixel 6, Samsung A52. |

## 9.9 Scalability

| NFR-ID | Requirement |
|--------|-------------|
| NFR-SC-001 | Handle product catalogues up to 10,000 items with smooth scroll (virtualized lists). |
| NFR-SC-002 | Handle 1,000+ clients in list without pagination lag. |
| NFR-SC-003 | Handle POS orders history with infinite scroll, 50 per page. |
| NFR-SC-004 | Cache invalidation scales to > 1 tenant (user may switch). |

## 9.10 Maintainability

| NFR-ID | Requirement |
|--------|-------------|
| NFR-M-001 | Code organized by feature module (not by technical layer). |
| NFR-M-002 | Every screen has a widget test. |
| NFR-M-003 | Every service has a unit test. |
| NFR-M-004 | Critical user flows (login, POS, payment) have E2E tests. |
| NFR-M-005 | Code coverage ≥ 70% for core business logic. |
| NFR-M-006 | Linter + formatter enforced in CI. |
| NFR-M-007 | All PRs require at least one review. |
| NFR-M-008 | Documentation updated with each feature delivery. |

## 9.11 Observability

| NFR-ID | Requirement |
|--------|-------------|
| NFR-O-001 | Crash reporting via Sentry / Crashlytics. |
| NFR-O-002 | Structured analytics events (see `02-system-overview.md §2.9`). |
| NFR-O-003 | API request logging (method, path, status, duration) — DEV/STAGING only. |
| NFR-O-004 | Feature flag framework (e.g., Firebase Remote Config) to disable problematic features without a release. |
| NFR-O-005 | Version and build number visible on Profile → About. |

## 9.12 Deployment & Release

| NFR-ID | Requirement |
|--------|-------------|
| NFR-D-001 | CI/CD pipeline (GitHub Actions / Codemagic / Bitrise). |
| NFR-D-002 | Automated test run on every PR. |
| NFR-D-003 | Versioning follows SemVer for app version; build number auto-incremented. |
| NFR-D-004 | Staged rollout on Play Store (10% → 50% → 100%). |
| NFR-D-005 | Phased rollout on App Store where supported. |
| NFR-D-006 | Rollback plan: keep last 2 production builds signed and ready to re-upload. |
| NFR-D-007 | Force-update channel (Remote Config flag `min_supported_version`) triggers in-app update prompt. |

## 9.13 Legal

| NFR-ID | Requirement |
|--------|-------------|
| NFR-L-001 | Terms of Service link in Login and Profile. |
| NFR-L-002 | Privacy Policy link in Login and Profile. |
| NFR-L-003 | Third-party license disclosures (OSS libraries) accessible from Profile → About. |

## 9.14 Data Retention

| NFR-ID | Requirement |
|--------|-------------|
| NFR-DR-001 | On logout: secure-storage wiped, in-memory state cleared, disk caches cleared. |
| NFR-DR-002 | Local cache TTL: products 1 hour, clients 10 minutes, config 1 hour, permissions until logout. |
| NFR-DR-003 | Crashlog retention max 30 days. |

## 9.15 Acceptance Criteria Summary

The mobile app is considered **release-ready** when:

1. All Phase 1 functional requirements (`04-functional-requirements.md`) pass their test traces.
2. All Screen IDs flagged Phase 1 (`05-screens-specification.md`) are implemented and tested.
3. NFR-P-001..NFR-P-010 pass on reference devices.
4. NFR-R-001 (crash-free users ≥ 99.5%) held for 7 days in beta.
5. Security scan (MobSF or Checkmarx) shows no High severity findings.
6. RTL / Arabic parity verified against LTR by QA.
7. Multi-tenant isolation test (switch tenants, check no data bleed) passes.
8. Store metadata & listings approved.
