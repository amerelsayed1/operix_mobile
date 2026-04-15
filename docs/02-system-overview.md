# 02 — System Overview

## 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       Mobile Client (iOS / Android)             │
│  ┌─────────────┐ ┌────────────┐ ┌──────────┐ ┌──────────────┐   │
│  │ UI Layer    │ │ State Mgmt │ │ API SDK  │ │ Secure Store │   │
│  │ (Screens,   │ │ (Auth,     │ │ (Axios / │ │ (JWT, tenant │   │
│  │  Components)│ │  Session,  │ │  Dio +   │ │  slug, prefs)│   │
│  │             │ │  Cache)    │ │  Intercep)│ │              │   │
│  └─────────────┘ └────────────┘ └──────────┘ └──────────────┘   │
└───────────────────────────────┬─────────────────────────────────┘
                                │ HTTPS + JWT Bearer
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│              Operix Backend API (Laravel 12)                    │
│                                                                 │
│  Middleware: auth:api → user.active → tenant.exists →           │
│              role.tenant_user → subscription.check →            │
│              permission:{module.action}                         │
│                                                                 │
│  Routes: /api/v1/{tenant_slug}/...                              │
│  Controllers: app/Http/Controllers/Tenant/                      │
│  Services: app/Services/                                        │
│  Models: app/Models/ (HasTenantScope trait)                     │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                ┌───────────────┼────────────────┐
                ▼               ▼                ▼
          ┌──────────┐   ┌────────────┐   ┌─────────────┐
          │  MySQL   │   │   Storage  │   │   Redis     │
          │ (primary │   │  (S3-like: │   │ (cache,     │
          │   DB)    │   │  logos,    │   │  sessions,  │
          │          │   │  receipts) │   │  queues)    │
          └──────────┘   └────────────┘   └─────────────┘
```

## 2.2 Backend Integration Points

### 2.2.1 Base URL

- **Production:** `https://api.operix.com/api/v1/{tenant_slug}/...`
- **Staging:** `https://staging.operix.com/api/v1/{tenant_slug}/...`
- **Local dev:** `http://127.0.0.1:8000/api/v1/{tenant_slug}/...`

The mobile app MUST make the base URL configurable via build-time env for dev/staging/prod switching.

### 2.2.2 Authentication Model

- **Guard name:** `api` (tenant user JWT guard)
- **Token lifetime:** 60 minutes
- **Refresh window:** 14 days
- **Token transport:** `Authorization: Bearer {jwt}` header on every protected request
- **Token storage:** platform-native secure storage (Keychain on iOS, EncryptedSharedPreferences / Keystore on Android). **Never** store in plain files.
- **Revocation:** `POST /logout` blacklists the token server-side.

### 2.2.3 Tenant Isolation

- The mobile app keeps exactly **one** active tenant context per session.
- Every protected API call goes through `/api/v1/{tenant_slug}/...`.
- The `tenant_slug` is chosen during login and persisted in secure storage alongside the JWT.
- Switching tenants requires explicit logout + re-login.
- The `ResolveTenantFromPath` middleware on backend validates the slug and blocks cross-tenant access.

### 2.2.4 Subscription Gate

- All protected tenant endpoints pass through `subscription.check` middleware.
- A suspended tenant returns `402 Payment Required` with structured error.
- Mobile UI surfaces this as a **billing banner** and redirects users with `billing.manage` permission to a "Renew on Web" handoff (Phase 1 does not implement in-app checkout).

## 2.3 Platform Architecture Decisions

### 2.3.1 Cross-Platform vs Native

**Recommendation:** **Flutter** as primary, with React Native as fallback.

- Both iOS and Android must be supported.
- A single codebase reduces maintenance for a small team.
- See `10-mobile-tech-stack.md` for full stack rationale.

### 2.3.2 Offline Strategy

**Phase 1:** Online-first with **read caching** only.

- Read caches (products, clients, permissions, tenant config) use stale-while-revalidate.
- **Writes are online-only.** No offline POS in Phase 1.
- Reason: POS stock, shift cash, and AR balance mutations require real-time backend consistency. Offline mutation queues risk stock drift, double-sale, and AR misalignment.

**Phase 3+:** Opt-in offline POS for retail scenarios with conflict resolution.

See `11-offline-sync-strategy.md`.

### 2.3.3 Multi-Branch Context

- A user's API responses are already scoped to their assigned inventories (via `user.inventories` pivot).
- In Phase 1, the active inventory/branch is auto-selected (default inventory).
- In Phase 3, an owner/manager can switch branches from a top-bar selector.

## 2.4 API Response Shape

### 2.4.1 Success — plain resource

```json
{
  "id": 123,
  "name": "Product A",
  "price": "10.50"
}
```

### 2.4.2 Success — wrapped

```json
{
  "success": true,
  "data": { "id": 123, "name": "Product A" },
  "message": "Created successfully"
}
```

### 2.4.3 Success — paginated

```json
{
  "data": [ { ... }, { ... } ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 73
  },
  "links": { "first": "...", "last": "...", "prev": null, "next": "..." }
}
```

### 2.4.4 Error — validation (422)

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email has already been taken."],
    "password": ["The password must be at least 8 characters."]
  }
}
```

### 2.4.5 Error — auth (401)

```json
{ "message": "Unauthenticated." }
```

### 2.4.6 Error — forbidden (403)

```json
{
  "message": "You do not have permission to perform this action.",
  "required_permission": "pos.create"
}
```

### 2.4.7 Error — payment required (402)

```json
{
  "message": "Subscription inactive.",
  "subscription_status": "suspended",
  "renewal_url": "https://operix.com/billing"
}
```

### 2.4.8 Normalization Requirement

The mobile app MUST have a **single response normalizer** that:

- Unwraps `{ success, data }` envelopes when present
- Extracts `meta` pagination separately
- Maps `errors` field-by-field to mobile form error state
- Routes `401 → logout flow`, `402 → billing banner`, `403 → toast + block`, `404 → not-found screen`, `422 → field errors`, `429 → backoff`, `5xx → retry/snackbar`

## 2.5 Data Consistency Model

| Scenario | Model |
|----------|-------|
| Stock during POS sale | Server is authoritative. Client shows last-known stock but backend validates at submit. |
| AR / AP balances | Server-calculated. Client never recomputes totals for display beyond presentation. |
| Receipt number | Server-generated (format `RCP-YYYYMMDD-XXXX`). Client displays after POST response. |
| Invoice number | Server-generated from tenant invoice config. |
| Shift cash | Server-authoritative. Client displays `expected_cash` from server summary. |
| Tax calculations | Server recomputes `tax_total` and `grand_total`. Client preview is hint-only. |
| Exchange rates | Read from `GET /settings/currencies`. Client never caches longer than 1 hour for in-session display. |

## 2.6 Integration Touchpoints Summary

| Touchpoint | Mobile in Phase 1? | Notes |
|------------|-------------------|-------|
| Authentication (`/login`, `/me`, `/logout`) | ✅ | Required |
| Tenant config (`/tenant-config/{slug}`, `/config`) | ✅ | Used for branding pre-login |
| Permissions (`/me/permissions`) | ✅ | Fetched at bootstrap |
| Dashboard (`/dashboard`, `/dashboard/kpis`, lists) | ✅ | Home screen |
| POS (`/pos/*`, `/pos-orders`, `/pos/shift/*`) | ✅ | Cashier flow |
| Clients (`/clients`, `/clients/by-phone`, `/clients/{id}/record-payment`) | ✅ | Customer flow |
| Products (`/products`, `/pos/products`) | ✅ | Catalog |
| Inventories (`/inventories`) | ✅ | Stock visibility |
| Expenses (`/expenses`) | ✅ | Quick entry |
| Accounts (`/accounts/*`, deposits, withdrawals, transfers) | ✅ | Cash ops |
| Profile (`/profile/*`) | ✅ | Self service |
| Sales Invoices (`/sales-invoices/*`) | ⏸️ Phase 2 | |
| Suppliers (`/suppliers/*`) | ⏸️ Phase 2 | |
| Purchase Invoices (`/purchase-invoices/*`) | ⏸️ Phase 2 | |
| Stock Movements & Transfers | ⏸️ Phase 2 | |
| Reports | ⏸️ Phase 3 | |
| Approvals | ⏸️ Phase 3 | |
| Receipt Bluetooth printing | ⏸️ Phase 3 | |
| Billing checkout | ❌ | Hand off to web |
| Super admin | ❌ | Not in scope |
| Shopify integration config | ❌ | Web-only |

## 2.7 Environment Matrix

| Env | API Base URL | Push Notifications | Crash Reporter | Feature Flags |
|-----|-------------|--------------------|----------------|----------------|
| Dev | `http://127.0.0.1:8000` or local IP | Disabled | Disabled | All on |
| Staging | `https://staging.operix.com` | Enabled (dev keys) | Sentry staging DSN | Feature preview |
| Production | `https://api.operix.com` | Enabled (prod keys) | Sentry prod DSN | GA flags only |

## 2.8 Deployment Distribution

- **iOS:** Apple App Store + TestFlight for beta
- **Android:** Google Play + Firebase App Distribution for beta
- **Internal QA builds:** Firebase App Distribution / TestFlight internal testing
- **Enterprise sideload:** NOT supported — all tenants use public stores.

## 2.9 Observability & Telemetry

Required integrations:

1. **Crash reporting** — Sentry or Firebase Crashlytics
2. **Analytics** — Mixpanel / Amplitude / Firebase Analytics (events: screen views, POS transaction completed, shift opened, payment recorded)
3. **Performance** — cold start, API latency, screen render time
4. **Tenant tagging** — all events tagged with `tenant_id` (not slug, to support renames)
5. **User tagging** — user `id` (hashed for PII compliance) and `role_id`

Events that MUST be tracked:

- `app_opened`
- `login_success` / `login_failed`
- `permission_denied` (with `required_permission`)
- `pos_order_created` (with `item_count`, `grand_total`, `payment_method`)
- `shift_opened` / `shift_closed` (with `variance`)
- `api_error_4xx` / `api_error_5xx` (with endpoint)
- `screen_view` (with screen name)

## 2.10 Compliance & Privacy

- **Data minimization:** cache only what the screen needs
- **No PII in logs:** user names, phones, emails must never be logged
- **At-rest encryption:** JWT and tenant slug in OS secure storage only
- **In-transit encryption:** TLS 1.2+, certificate pinning recommended (Phase 2)
- **Right-to-be-forgotten:** on logout, all cached data is wiped (see `11-offline-sync-strategy.md`)
