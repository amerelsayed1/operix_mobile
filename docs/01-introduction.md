# 01 — Introduction

## 1.1 Purpose

This Software Requirements Specification (SRS) defines the complete requirements for the **Operix Tenant Mobile App** — a native mobile application that delivers the core Operix business operations (POS, inventory, clients, suppliers, expenses, accounts, reporting) on iOS and Android.

This document is written so that a complete engineering team (product, mobile engineers, backend integrators, QA) can implement the mobile app end-to-end using only this SRS and the referenced backend codebase. **No implicit knowledge is assumed.**

## 1.2 Product Context

**Operix** is a multi-tenant SaaS platform for small and mid-sized businesses (SMBs) in the MENA region, providing finance management, POS, and inventory control. The platform is currently composed of:

- A Laravel 12 REST API backend (`business_finance_manager_api/`)
- A Vue 3 web frontend with three apps: tenant-app, super-admin, landing (`business-finance-manager-frontend/`)

Each **tenant** is an independent business with its own users, data, branches, POS terminals, inventories, accounts, and financial records. Data isolation is enforced at the ORM level via a `HasTenantScope` trait and at the routing level via path-based tenancy (`/api/v1/{tenant_slug}/...`).

The mobile app **integrates with the same backend API** used by the web app. It does **not** require backend changes in Phase 1 (MVP), though some optional backend enhancements are identified in `15-delivery-phases.md`.

## 1.3 Business Goals

The mobile app must enable tenants to:

1. **Sell faster** — POS transactions completed in under 15 seconds from barcode scan to receipt
2. **Track cash clearly** — shift-based cash handling with open/close reconciliation
3. **Reduce stock mistakes** — real-time stock visibility with barcode-driven operations
4. **Monitor team activity** — branch and user-level activity visibility
5. **Serve customers better** — phone-based customer lookup, balance, history
6. **Stay aware of business health** — dashboard KPIs on the move
7. **Maintain role-based control** — permission-driven UI with backend enforcement

## 1.4 Scope

### In Scope (Phase 1 MVP)

- Tenant-aware branded login
- Session bootstrap (user profile, permissions, tenant config)
- Role-aware home screen
- Dashboard KPIs and low-stock alerts
- POS: product browse, barcode scan, cart, checkout, receipt
- POS Shifts: open, close, cash movements, current shift
- Clients: search by phone/name, profile, balance, payment collection, creation
- Products: search, detail, stock-by-inventory
- Inventories: list, default inventory, product stock
- Expenses: list, create
- Accounts: list, balances, deposit, withdraw, transfer
- Profile: view, edit, change password, avatar upload
- Offline-safe read caching for reference data (products, clients)

### In Scope (Phase 2)

- Sales Invoices (create, list, post, record payment)
- Sales Returns (create, approve)
- Suppliers: directory, financial summary, payments, ledger
- Purchase Invoices: create, post, record payment, return
- Stock Movements & adjustments
- Inventory transfers
- Notifications (push) for low stock, overdue balances, shift events

### In Scope (Phase 3)

- Reports: daily/monthly sales, product insights, AR/AP aging, cash/credit split
- Approval workflows for discounts, adjustments, refunds
- Multi-branch switcher for owners
- Receipt printing (thermal Bluetooth printers)
- Advanced audit log views

### Out of Scope

- Super Admin functions (tenant management, platform billing, plan CRUD)
- Full chart-of-accounts editing
- GL journal entry creation
- Shopify integration configuration
- Tenant registration / self-signup (remains web-only)
- Plan upgrade / checkout (handoff to web for billing)
- Complex settings (units, attributes, taxes, roles, payment methods CRUD — remain web-only)

## 1.5 Definitions, Acronyms & Glossary

| Term | Definition |
|------|------------|
| **Tenant** | A single business (customer) subscribed to Operix. Has unique slug, data, users. |
| **Tenant Slug** | URL-safe identifier for a tenant (e.g., `tech-store`). Used in all API paths. |
| **Super Admin** | Platform operator. Separate auth guard. **Not** used by mobile app. |
| **Branch** | A physical/logical location within a tenant (e.g., "Downtown Store"). |
| **Inventory** | A stock location (warehouse). Tenants may have multiple. One is `is_default`. |
| **POS** | Point of Sale — the checkout interface for in-person sales. |
| **Shift** | A cashier session bounded by an open and close with cash reconciliation. |
| **Terminal** | A POS device/register. Each branch can have multiple terminals. |
| **Drawer Account** | A cash account linked to a POS terminal, tracked per shift. |
| **PosOrder** | A completed POS transaction (receipt). |
| **Sales Invoice** | A full invoice with due date, line items, tax — separate from POS receipts. |
| **Client** | A customer of the tenant. May have outstanding AR balance. |
| **Supplier** | A vendor. May have outstanding AP (payable) balance. |
| **AR** | Accounts Receivable — money clients owe the tenant. |
| **AP** | Accounts Payable — money the tenant owes suppliers. |
| **GL Account** | General Ledger chart-of-accounts entry. |
| **Journal Entry** | A posting to the general ledger (double-entry). |
| **JWT** | JSON Web Token — bearer token for API auth. |
| **RBAC** | Role-Based Access Control. |
| **Permission** | A `module.action` string (e.g., `pos.create`). Users have permissions via roles. |
| **HasTenantScope** | Laravel trait auto-filtering queries by `tenant_id`. |
| **RTL** | Right-to-Left text direction (Arabic). |
| **i18n** | Internationalization. |
| **SKU** | Stock Keeping Unit — product identifier. |
| **Receipt Number** | POS receipt ID, format `RCP-YYYYMMDD-XXXX`. |
| **Invoice Number** | Sales invoice ID, tenant-unique. |

## 1.6 References

### Inside this repository

- `.ai/architecture.md` — platform architecture
- `.ai/database.md` — complete DB schema
- `.ai/coding_rules.md` — backend and frontend coding standards
- `business_finance_manager_api/routes/tenant_api.php` — canonical route list
- `business_finance_manager_api/app/Http/Controllers/Tenant/` — controller implementations
- `business_finance_manager_api/app/Models/` — Eloquent models
- `business-finance-manager-frontend/apps/tenant-app/src/locales/en.json` — full i18n dictionary (3,558+ keys) — **use as feature inventory reference**
- `business-finance-manager-frontend/e2e/tests/` — Playwright E2E tests (user flow reference)

### External standards referenced

- IEEE Std 830-1998 (SRS structure)
- OWASP Mobile Top 10 (security baseline)
- WCAG 2.1 Level AA (accessibility target)

## 1.7 Assumptions and Dependencies

### Assumptions

- Backend API remains at parity with documented endpoints in `06-api-reference.md`.
- Tenants accessing mobile are **active subscribers** (trial or paid). Suspended tenants are blocked by `subscription.check` middleware.
- Users have already been created on web by a tenant admin. Mobile does **not** handle user invitation/creation in Phase 1.
- Each user has a `role_id` with pre-configured permissions.
- Network is primarily available — offline-only flows are **out of scope** for Phase 1 mutations.

### Dependencies

- **Backend API** running `/api/v1/{tenant_slug}/*` at a reachable HTTPS URL.
- **JWT auth** with `tymon/jwt-auth`, 60-min TTL, 14-day refresh.
- **Storage CDN** for tenant logos, product images, avatars, receipt assets.
- **Billing gateway webhooks** (Stripe/Paymob/LemonSqueezy) — not invoked from mobile but affect tenant access.
- **Push notification service** (FCM for Android, APNs for iOS) — Phase 2+.

## 1.8 Document Conventions

- Endpoint shorthand: `METHOD /path` always implies `/api/v1/{tenant_slug}/` prefix unless stated.
- Permission shorthand: `module.action` (e.g., `pos.create`). Pipe `|` means OR.
- Field types use JSON-schema-like notation: `string`, `number`, `boolean`, `date`, `datetime`, `decimal(p,s)`.
- `REQ-XX-NNN` identifiers are used for requirements that need test traceability.
- Screens use identifiers `SCR-XXX` matching `05-screens-specification.md`.

## 1.9 Success Criteria

The mobile app is successful when:

- **≥ 80%** of daily POS operations (per active tenant) can be completed on mobile without web fallback
- **Login + first usable screen in < 3 seconds** on a cold start with 4G connection
- **POS order submission latency < 1 second** P95 after checkout tap
- **Zero cross-tenant data leaks** in security audit
- **Permission denial is never silent** — users see a clear message if blocked
- **RTL (Arabic) layout parity** with LTR — no clipping, no swapped chevrons
- **Crash-free users ≥ 99.5%** in production (measured via crash reporter)
