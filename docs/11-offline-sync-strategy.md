# 11 — Offline & Sync Strategy

## 11.1 Strategy Summary

| Phase | Strategy |
|-------|----------|
| Phase 1 (MVP) | **Online-first with read caching.** No offline writes. |
| Phase 2 | Expanded read caches, draft persistence for forms, retry queue for idempotent reads. |
| Phase 3 | **Opt-in offline POS** with conflict resolution (for retail tenants). |

## 11.2 Why Not Offline-First in Phase 1

- Stock, shift cash, AR balances, and receipt numbers are **server-authoritative**.
- Allowing offline POS submissions risks:
  - Stock drift (two devices selling the same last unit)
  - Duplicate receipt numbers
  - AR balance mismatches
  - Shift cash variance disputes
- Backend idempotency keys are not uniformly supported yet; adding them is a backend precondition for offline POS.

## 11.3 Cache Layers

### Layer 1 — In-memory (session lifetime)

- Current user profile
- Permission set
- Tenant config
- Open shift
- Default inventory

Implemented as Riverpod providers; discarded on logout.

### Layer 2 — Hive (fast KV)

- Permission snapshot (for instant nav render on cold start)
- Tenant config snapshot
- Last 5 accessed client summaries
- Recent POS products for offline display

### Layer 3 — Drift (SQLite)

- Products (SKU, name, selling_price, image_url, stock_by_inventory) — up to 10,000 rows
- Clients (id, name, phone, balance) — up to 5,000 rows
- Expense categories, payment methods, taxes — static reference data

### Layer 4 — File (secure storage)

- JWT token
- Tenant slug

## 11.4 Cache Invalidation

| Cache | TTL | Invalidated by |
|-------|-----|----------------|
| Tenant config | 1 hour | manual refresh / login |
| Permissions | session | logout / 401 |
| Products | 1 hour | pull-to-refresh / product mutation success |
| Clients | 10 min | pull-to-refresh / client mutation |
| Dashboard | 5 min | period change / pull-to-refresh |
| Open shift | 30 sec | shift action success |

## 11.5 Stale-While-Revalidate Pattern

```dart
Future<List<Product>> loadProducts() async {
  final cached = await productCache.load();
  if (cached != null) yield cached;         // fast first paint

  final fresh = await api.fetchProducts();
  await productCache.save(fresh);
  yield fresh;                              // refresh UI
}
```

Use for: products list, clients list, dashboard KPIs, shift summary.

## 11.6 Connectivity Detection

`connectivity_plus` provides online/offline stream. On transition:

- **Online → Offline** — show persistent banner "Offline. Viewing cached data." in list screens. Disable mutation buttons (grey with hint "Offline").
- **Offline → Online** — auto-refresh current screen; dismiss banner; show brief toast "Back online".

## 11.7 POS-Specific Offline Rules (Phase 1)

- **Cart mutations** (add/remove/qty change) are always local in-memory; never hit the API.
- **Order submission** requires connectivity. Offline attempt shows modal: "You must be online to complete a sale. Retry?"
- **Product browsing** works from cache; stock figures show "last updated N min ago".
- **Shift open/close** requires connectivity.

## 11.8 Draft Persistence

Even without true offline, the app persists in-progress form state locally to recover after a crash or OS termination:

- POS cart contents
- Expense form draft
- Client form draft
- Sales invoice draft

Stored in Hive keyed by `{user_id}:{form_key}`. Cleared on successful submission.

## 11.9 Conflict Handling (Phase 3 — future)

When offline POS is enabled:

1. Each pending order has a local UUID.
2. On submit, backend accepts an `Idempotency-Key` header and returns the canonical `id` + `receipt_number`.
3. On conflict (same `Idempotency-Key` already processed), server returns the existing order; client reconciles.
4. Stock levels shown are advisory only; backend rejects if actual stock < requested.
5. Rejected orders are marked locally for manual review.

**Backend prerequisites** (Phase 3 gating):

- Add `Idempotency-Key` middleware to `POST /pos-orders`.
- Return a structured `409 Conflict` with `existing_id` when duplicate key.
- Support server-side reconciliation endpoints: `POST /pos-orders/reconcile` (optional).

## 11.10 Sync Queue (Phase 3)

```
┌──────────────────────────────────┐
│  Offline Sync Queue (per user)    │
│  ┌────────────────────────────┐  │
│  │ pending_order {uuid, body} │  │
│  │ pending_payment {...}       │  │
│  │ pending_expense {...}       │  │
│  └────────────────────────────┘  │
└──────────────────┬───────────────┘
                   │ online
                   ▼
        Serial flush with exponential backoff
        On 422 → mark "needs_review"
        On 409 → resolve via idempotency
        On 5xx → retry later
```

## 11.11 Storage Budget

- Disk cap per tenant: 200 MB
- Images cached via `cached_network_image` with LRU 100 MB eviction
- Drift DB size capped by products cap (10K rows ≈ ~5 MB)
- Logs + breadcrumbs purged weekly

## 11.12 Clear-on-Logout

On logout (explicit or forced by 401/402):

- Wipe Drift DB
- Wipe Hive boxes
- Wipe secure storage (JWT, slug)
- Keep: language preference, last-used tenant slug (to speed re-login)

## 11.13 Cross-Tenant Isolation

- Each cache key includes `tenant_id`.
- On tenant switch, all caches for the previous tenant are wiped before the new one loads.
- Tests verify that switching tenants shows ZERO rows from the previous tenant before the first API response.

## 11.14 Performance Targets for Cached Reads

| Operation | Target (cached) |
|-----------|-----------------|
| First products list paint | ≤ 200ms |
| First clients list paint | ≤ 200ms |
| Dashboard KPI paint | ≤ 300ms |
| Permission-aware navigation build | ≤ 50ms |

## 11.15 Background Sync (Phase 3)

- iOS: `BGTaskScheduler` — optional refresh of KPIs every 30 min
- Android: `WorkManager` — same
- Used for: low-stock / overdue alerts precompute, notification badge counts.

## 11.16 Developer Checklist

- [ ] Every repository supports `load(fromCache: true)` and `load(forceRefresh: true)`.
- [ ] Every mutation invalidates affected caches in a single atomic operation.
- [ ] Every list screen supports offline viewing of cached data.
- [ ] Every mutation screen disables its submit button when offline (with hint).
- [ ] Draft forms auto-persist every 2 seconds of edit (debounced).
- [ ] No two tenants ever share a cache namespace.
