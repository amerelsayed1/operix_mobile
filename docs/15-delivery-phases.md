# 15 — Delivery Phases

## 15.1 Overview

The mobile app is delivered in **three progressive phases**. Each phase is independently shippable.

| Phase | Theme | Target duration | Users unlocked |
|-------|-------|-----------------|----------------|
| Phase 1 | **MVP — Daily Operations** | ~8–10 weeks | Cashier, Manager, Owner (basic) |
| Phase 2 | **Control & Follow-Up** | ~6–8 weeks | Accountant, Storekeeper, Sales |
| Phase 3 | **Deeper Oversight & Offline** | ~8–10 weeks | Owner-level oversight, offline-tolerant retail |

## 15.2 Phase 1 — MVP

### Goal

A phone-first operational app that a cashier or manager can use to run a full business day without touching a web browser for core operations.

### Included

**Auth & session**
- Tenant slug resolution
- Branded login
- Forgot password (web completion)
- Session bootstrap (`/me`, `/me/permissions`, `/config`)
- Secure token storage
- Logout & session expiry

**Home / Dashboard**
- KPI cards (revenue, expenses, profit, balance)
- Period selector
- Sales trend chart
- Top products
- Low stock list
- Recent orders
- Role-based quick actions

**POS**
- Shift open / close with cash reconciliation
- Cash movements (in / out / reverse)
- Product browse + search + barcode scan
- Cart management
- Client attach (walk-in or selected)
- Variant picker
- Payment (cash, card, wallet, credit, split)
- Receipt display + share
- POS orders list + detail
- POS return
- Record later payment on due order

**Clients**
- List + KPIs
- Search (name, phone)
- Client profile (overview, orders, due, payments, activity, statement)
- Create / edit
- Record payment
- Block / unblock
- Adjust credit limit

**Products & Inventory (read-focused)**
- Products list (grid / list)
- Product detail (with stock-by-inventory)
- Barcode scanner
- Inventories list
- Inventory detail (products & min thresholds)
- View-only stock movements

**Expenses**
- List
- Create
- Edit / delete

**Accounts**
- List + balances
- Account detail + history
- Deposit
- Withdraw
- Transfer

**Profile**
- View profile
- Edit profile
- Change password
- Change avatar
- Language toggle

**Billing (read-only)**
- Current plan
- Status
- Renewal date
- Hand-off to web for upgrade / renew

**Settings (read-only)**
- Company
- Currencies
- Taxes
- Payment methods
- Receipt template (read only)

**Cross-cutting**
- RTL / Arabic support
- Light mode
- Error handling taxonomy
- Permission-driven UI
- Crash reporting
- Analytics
- Read caching for products / clients

### Phase 1 Exit Criteria

- All Phase 1 FR (`04-functional-requirements.md`) pass test traces.
- All Phase 1 SCR (`05-screens-specification.md`) implemented.
- Manual QA matrix passes on 6 reference devices.
- Crash-free users ≥ 99.5% over 7 days of closed beta.
- Store listings approved (App Store + Play Store).
- Security scan (MobSF) — no High severity findings.

## 15.3 Phase 2 — Control & Follow-Up

### Goal

Extend the app to back-office follow-up: full sales invoices, supplier management, purchases, stock operations, and notifications.

### Included

**Sales Invoices**
- List with filters
- Create / edit draft
- Post invoice
- Record payment
- Cancel
- Print / share (PDF handoff)

**Sales Returns**
- Create (standalone or from invoice)
- List
- Approve / reject (permission-gated)

**Suppliers**
- List with KPIs
- Supplier profile (invoices, returns, payments, ledger, financial summary)
- Create / edit
- Supplier contacts, addresses, bank accounts (CRUD)
- Documents (upload / view)

**Purchase Invoices**
- List with filters
- Create
- Post / cancel
- Record payment
- Return

**Supplier Payments**
- List
- Record payment
- Edit / delete

**Stock Operations**
- Stock transfer between inventories
- Stock adjustment (with reason + type)
- Min-threshold edit per product per inventory

**Notifications (push)**
- FCM / APNs registration
- Device registration endpoint (new backend endpoint required)
- Low stock / overdue AR / overdue AP / shift variance notifications
- In-app notification center
- Deep links from notifications

**Receipt Printing (Bluetooth thermal)**
- Discover Bluetooth thermal printer
- Pair / save default
- Print receipt after POS sale
- ESC/POS command generation

**Profile improvements**
- Biometric login toggle
- Dark mode toggle

**Additional settings (edit)**
- Receipt template
- Company logo
- Company basic info

### Phase 2 Backend Prerequisites

- `/api/v1/{tenant_slug}/devices/register` endpoint for FCM/APNs tokens
- Push notification payload schema finalized
- Receipt PDF endpoint returns a consistent PDF format

### Phase 2 Exit Criteria

- All Phase 2 FR pass.
- Notification delivery reliability ≥ 98%.
- Bluetooth printing supported for at least 3 popular thermal printers (e.g., Star TSP, Epson TM, Xprinter).
- Beta program includes ≥ 5 active tenants.

## 15.4 Phase 3 — Deeper Oversight & Offline

### Goal

Owner-level visibility, approvals workflows, reporting on mobile, and opt-in offline POS for retail tenants.

### Included

**Reports (mobile subset)**
- Reports hub with categories
- Daily sales
- Monthly sales
- Cash vs credit
- Outstanding invoices
- Product sales / profit
- AR / AP aging
- POS shift variance
- Simple charts for each
- Export via email

**Approvals Workflow**
- Approval inbox
- Approval types: discount over threshold, stock adjustment, refund, invoice cancellation
- Approve / reject with reason
- Push notifications for pending approvals

**Multi-Branch Switcher**
- Top-bar branch selector for owners / managers with multi-branch access
- All subsequent screens filter by selected branch

**Offline POS (opt-in)**
- Per-tenant feature flag
- Idempotency-key based submission
- Local pending queue with visibility
- Conflict resolution UI
- Stock advisory mode
- Draft sales persistence across app kills

**Audit Log Viewer**
- Filter by actor, action, entity, date
- Detail view with diff

**Super Features**
- In-app support chat handoff
- Update prompt (remote config `min_supported_version`)
- Crash-free trend in Profile → About
- Beta program toggle

### Phase 3 Backend Prerequisites

- Idempotency-key middleware on `POST /pos-orders`
- Reconciliation endpoint for offline conflicts
- Approvals API (new module) — design TBD

### Phase 3 Exit Criteria

- Offline POS stable in 3 retail tenant pilots for 4 weeks.
- Approvals workflow live with < 5% rejection friction feedback.
- Reports hub used by ≥ 50% of owner-role users weekly.

## 15.5 Out of Scope (permanently or long-term)

- Super admin tenant management
- Plan CRUD
- Registration (self-signup)
- Full chart-of-accounts editing
- Journal entry creation
- Shopify integration configuration
- Role / permission management
- Tax / unit / attribute CRUD
- White-label branding customization
- Multi-currency mid-sale conversion

These remain on web.

## 15.6 Rollout Strategy

### Phase 1 launch

1. **Internal alpha** (2 weeks) — Operix staff only
2. **Closed beta** (4 weeks) — 10 hand-picked tenants
3. **Public beta** (2 weeks) — TestFlight + Firebase App Distribution
4. **General availability** — staged Play Store rollout (10% → 50% → 100%)
5. iOS: phased rollout where supported

### Feature flags

All Phase 2 and Phase 3 features are behind Remote Config flags so they can be enabled per tenant (e.g., "offline_pos_enabled").

### Minimum supported version

On cold start, compare app version to `min_supported_version` from Remote Config. If below, force-update prompt with link to store.

## 15.7 Release Cadence

- Phase 1: bi-weekly beta releases during development
- Post-GA: monthly feature releases, weekly bug-fix releases as needed
- Hotfix channel: within 48 hours for blockers

## 15.8 Success Metrics Per Phase

### Phase 1

- Daily active cashiers / total cashiers: ≥ 60%
- POS orders submitted on mobile / total POS orders: ≥ 30%
- Avg sale completion time: ≤ 20s
- Crash-free users: ≥ 99.5%
- App Store / Play Store rating: ≥ 4.3

### Phase 2

- Push notification tap-through rate: ≥ 15%
- Bluetooth printer adoption: ≥ 25% of POS users
- Mobile sales-invoice creations: ≥ 15% of total invoices

### Phase 3

- Offline POS tenants active: ≥ 3
- Approvals processed on mobile: ≥ 50% of total
- Report views per owner per week: ≥ 5

## 15.9 Backend Coordination Checklist

Before each phase starts, align with backend team on:

### Phase 1

- [ ] Confirm `/me` and `/me/permissions` response shape (consistent wrapping)
- [ ] Confirm pagination envelope consistency across list endpoints
- [ ] Confirm 402 response shape (with `renewal_url`)
- [ ] Confirm `tenant-config/{slug}` returns all required branding fields
- [ ] Rate limit review (mobile vs web share same limits?)

### Phase 2

- [ ] Device registration endpoint design
- [ ] Push notification event catalogue and payload schema
- [ ] Receipt PDF endpoint consistency
- [ ] Upload size limit confirmation (receipts, documents)

### Phase 3

- [ ] Idempotency-Key middleware for POS submissions
- [ ] Conflict response shape
- [ ] Approvals module API

## 15.10 Team & Roles (suggestion)

Minimum team composition for Phase 1:

- 2 mobile engineers (Flutter)
- 1 backend engineer part-time (API alignment)
- 1 QA engineer
- 1 product manager
- 1 UX designer
- 1 Arabic translator (part-time)

For Phase 2 / 3, add:

- 1 additional mobile engineer (iOS-specific or Android-specific deep dive as needed)
- 1 DevOps for release automation

## 15.11 Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Backend response inconsistency breaks mobile parsers | Medium | High | Central normalizer, strict JSON tests, contract tests |
| App Store review rejection | Medium | Medium | Early-and-often submissions; follow guidelines; privacy labels |
| Bluetooth printer fragmentation | High | Medium | Support top 3 models only; clear support list |
| Offline POS conflicts cause accounting disputes | High | High | Phase 3 gating; per-tenant opt-in; clear UX for conflicts |
| Arabic RTL regressions | Medium | Medium | Golden tests in both directions; dedicated QA pass |
| JWT refresh mid-transaction causes duplicate submits | Low | High | Idempotency key (Phase 3); always await response before retry |
| Over-caching causes stale data in stock-critical moments | Medium | High | Short TTL; pull-to-refresh prominent; stock advisory labels |
| Permission payload shape changes silently | Low | High | Defensive parsing; permissions unit-tested against fixtures |
