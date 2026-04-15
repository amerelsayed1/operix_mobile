# 06 — API Reference

> **Base URL pattern:** `https://{host}/api/v1/{tenant_slug}/...`
> **Auth:** `Authorization: Bearer {jwt}` on every protected endpoint
> **Content:** `Accept: application/json`; `Content-Type: application/json` (or `multipart/form-data` for uploads)

For every endpoint below, unless otherwise noted:

- Successful responses return JSON (see `02-system-overview.md §2.4` for shapes).
- Errors follow the error shapes in the same section.
- `{tenant_slug}` is the URL-encoded tenant slug.

This document groups endpoints by module. Only endpoints used by mobile are documented in full; all others are referenced for completeness.

---

## 6.1 Public Endpoints (no auth)

### Health

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/health` | Server health check `{ status: "ok" }` |

### Tenant Config (used to brand login)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/tenant-config/{slug}` | Resolve tenant existence + public branding |
| GET | `/api/v1/system/config` | System-wide branding |

Example `GET /tenant-config/tech-store`:

```json
{
  "tenant": {
    "id": 12,
    "name": "Tech Store",
    "slug": "tech-store",
    "logo_url": "https://cdn.operix.com/logos/12.png",
    "theme_primary_color": "#4f46e5",
    "locale": "en",
    "currency_code": "EGP",
    "timezone": "Africa/Cairo",
    "status": "active"
  }
}
```

### Auth — tenant-scoped

| Method | Path | Body | Purpose |
|--------|------|------|---------|
| POST | `/api/v1/{tenant_slug}/login` | `{email, password, remember_me?}` | Login |
| POST | `/api/v1/auth/forgot-password` | `{email}` | Send reset email |
| POST | `/api/v1/auth/reset-password` | `{token, password, password_confirmation}` | Complete reset |

**Login response (mobile-relevant fields):**

```json
{
  "token": "eyJ...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": 42,
    "name": "Sara Ahmed",
    "email": "sara@tech-store.com",
    "phone": "+201234567890",
    "avatar_url": "...",
    "role_id": 5,
    "role": { "id": 5, "name": "Manager", "slug": "manager" },
    "drawer_account": { "id": 8, "name": "Register 1", "current_balance": "1500.00" },
    "default_account": { "id": 1, "name": "Main Cash", "current_balance": "50000.00" },
    "tenant": { "id": 12, "slug": "tech-store", ... }
  },
  "tenant": { "id": 12, "slug": "tech-store", "currency_code": "EGP", ... },
  "redirect_to": "/dashboard"
}
```

---

## 6.2 Authenticated Bootstrap

| Method | Path | Permission | Purpose |
|--------|------|-----------|---------|
| POST | `/logout` | — | Invalidate token |
| GET | `/me` | — | Current user + tenant + accounts |
| GET | `/me/permissions` | — | Permission list + role |
| GET | `/config` | — | Tenant settings (currency, taxes, etc.) |
| GET | `/onboarding/progress` | — | Onboarding checklist (optional) |

### GET /me (key fields)

```json
{
  "id": 42,
  "name": "Sara Ahmed",
  "email": "sara@tech-store.com",
  "phone": "+201234567890",
  "avatar_url": "...",
  "role": { "id": 5, "slug": "manager" },
  "tenant": { "id": 12, "slug": "tech-store", "currency_code": "EGP", "locale": "en" },
  "drawer_account": { "id": 8, "name": "Register 1" },
  "default_account": { "id": 1, "name": "Main Cash" },
  "inventories": [{ "id": 3, "name": "Main Warehouse", "is_default": true }]
}
```

### GET /me/permissions

```json
{
  "permissions": ["dashboard.view", "pos.view", "pos.create", "clients.view"],
  "role": { "id": 5, "slug": "manager", "name": "Manager" }
}
```

Or for admin: `{ "permissions": ["*"], "role": {...} }`.

---

## 6.3 Dashboard

| Method | Path | Permission | Notes |
|--------|------|-----------|-------|
| GET | `/dashboard` | `dashboard.view` | Top-level summary |
| GET | `/dashboard/summary?month=YYYY-MM` | `dashboard.view` | Monthly summary |
| GET | `/dashboard/kpis?from=&to=` | `dashboard.view` | KPI numbers |
| GET | `/dashboard/charts/sales-trend?period=day\|week\|month&from=&to=` | `dashboard.view` | Time series |
| GET | `/dashboard/charts/purchases-trend?period=&from=&to=` | `dashboard.view` | |
| GET | `/dashboard/charts/top-products?limit=5&from=&to=` | `dashboard.view` | |
| GET | `/dashboard/charts/top-returned-products?limit=5` | `dashboard.view` | |
| GET | `/dashboard/lists/low-stock` | `dashboard.view` | |
| GET | `/dashboard/lists/recent-orders` | `dashboard.view` | |

**Example `GET /dashboard`:**

```json
{
  "total_balance": "52340.50",
  "total_revenue": "12500.00",
  "total_expenses": "3200.00",
  "total_purchases": "6000.00",
  "total_returns": "250.00",
  "returns_count": 3,
  "net_profit": "3050.00",
  "currency": "EGP"
}
```

---

## 6.4 POS

### POS Reference Data

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/pos/products?search=&branch_id=` | `pos.view` |
| GET | `/pos/accounts` | `pos.view` |
| GET | `/pos/payment-methods` | `pos.view` |
| GET | `/pos/taxes` | `pos.view` |

### POS Shift

| Method | Path | Permission | Body / Query |
|--------|------|-----------|-------------|
| POST | `/pos/shift/open` | `shifts.create` | `{terminal_id, opening_cash, note?}` |
| GET | `/pos/shift/current` | `shifts.view\|pos.view` | — |
| POST | `/pos/shift/close` | `shifts.update` | `{actual_cash, variance_notes?}` |
| GET | `/pos/shift/summary` | `shifts.update` | — |
| GET | `/pos/shift/history?page=&per_page=&from_date=&to_date=&user_id=` | `shifts.view` | — |
| GET | `/pos/shifts/{id}` | `shifts.view` | — |
| POST | `/pos/shift/cash-movements` | `shifts.update` | `{type, amount, reason, account_id?, payment_method_id?, notes?}` |
| GET | `/pos/shift/cash-movements` | `shifts.view` | — |
| POST | `/pos/shift/cash-movements/{id}/reverse` | `shifts.update` | `{reason}` |
| GET | `/pos/shift/report-summary?from=&to=` | `shifts.view` | — |
| GET | `/pos/shift/available-drawers` | `shifts.create` | — |

### POS Orders

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/pos-orders?status=&client_id=&from_date=&to_date=&page=&per_page=` | `pos.view` |
| POST | `/pos-orders` | `pos.create` |
| GET | `/pos-orders/{id}` | `pos.view` |
| PUT / PATCH | `/pos-orders/{id}` | `pos.update` |
| DELETE | `/pos-orders/{id}` | `pos.delete` |
| GET | `/pos-orders/{id}/receipt` | `pos.view` |
| POST | `/pos-orders/{id}/return` | `sales.return` |
| POST | `/pos-orders/{id}/payments` | `sales.pay_credit` |

**POST `/pos-orders` body:**

```json
{
  "client_id": 42,
  "inventory_id": 3,
  "date": "2026-04-13",
  "items": [
    { "product_id": 101, "quantity": 2, "unit_price": "50.00" },
    { "product_id": 102, "product_variant_id": 77, "quantity": 1, "unit_price": "200.00" }
  ],
  "discount_type": "percent",
  "discount_value": 5,
  "tax_id": 1,
  "payment_method_id": 2,
  "paid_amount": "285.00",
  "account_id": 8,
  "note": "Counter sale"
}
```

**Response (key fields):**

```json
{
  "message": "Order created",
  "pos_order": {
    "id": 9981,
    "receipt_number": "RCP-20260413-0012",
    "subtotal": "300.00",
    "discount_total": "15.00",
    "tax_total": "39.90",
    "grand_total": "324.90",
    "paid_amount": "285.00",
    "due_amount": "39.90",
    "payment_status": "partial",
    "status": "partial",
    "items": [ ... ]
  }
}
```

### POS Terminals

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/pos/terminals?branch_id=&is_active=&page=&per_page=` | `pos.view` |
| POST | `/pos/terminals` | `pos.create` |
| GET | `/pos/terminals/{id}` | `pos.view` |
| PUT | `/pos/terminals/{id}` | `pos.update` |
| POST | `/pos/terminals/{id}/toggle-active` | `pos.update` |
| DELETE | `/pos/terminals/{id}` | `pos.delete` |

---

## 6.5 Sales Invoices (Phase 2)

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/sales-invoices?status=&client_id=&from_date=&to_date=&page=&per_page=` | `sales.view` |
| POST | `/sales-invoices` | `sales.create` |
| GET | `/sales-invoices/{id}` | `sales.view` |
| PUT | `/sales-invoices/{id}` | `sales.update` |
| DELETE | `/sales-invoices/{id}` | `sales.delete` |
| POST | `/sales-invoices/{id}/post` | `sales.approve` |
| POST | `/sales-invoices/{id}/record-payment` | `sales.pay_credit` |
| POST | `/sales-invoices/{id}/cancel` | `sales.delete` |
| GET | `/sales-invoices/{id}/print` | `sales.view` |

**POST `/sales-invoices` body:**

```json
{
  "client_id": 42,
  "date": "2026-04-13",
  "due_date": "2026-05-13",
  "items": [
    { "product_id": 101, "quantity": 10, "unit_price": "50.00", "tax_id": 1 }
  ],
  "discount_type": "amount",
  "discount_value": "25.00",
  "tax_id": 1,
  "notes": "Net 30"
}
```

---

## 6.6 Sales Returns (Phase 2)

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/sales-returns` | `sales.view` |
| POST | `/sales-returns` | `sales.return` |
| GET | `/sales-returns/{id}` | `sales.view` |
| POST | `/sales-returns/{id}/approve` | `sales.approve` |
| POST | `/sales-returns/{id}/reject` | `sales.approve` |
| DELETE | `/sales-returns/{id}` | `sales.return` |

---

## 6.7 Clients

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/clients?search=&status=&page=&per_page=` | `clients.view\|pos.clients` |
| POST | `/clients` | `clients.create\|pos.clients` |
| GET | `/clients/{id}` | `clients.view\|pos.clients` |
| PUT / PATCH | `/clients/{id}` | `clients.update\|pos.clients` |
| DELETE | `/clients/{id}` | `clients.delete` |
| GET | `/clients/by-phone?phone=...` | `clients.view\|pos.clients` |
| GET | `/clients/summary` | `clients.view\|pos.clients` |
| GET | `/clients/{id}/orders?page=` | `clients.view\|pos.clients` |
| GET | `/clients/{id}/due-orders` | `clients.view\|pos.clients` |
| GET | `/clients/{id}/payments` | `clients.view` |
| GET | `/clients/{id}/activity` | `clients.view` |
| GET | `/clients/{id}/statement?from=&to=` | `clients.view` |
| POST | `/clients/{id}/record-payment` | `sales.collect_payment\|clients.update` |
| POST | `/clients/{id}/block` | `clients.update` |
| POST | `/clients/{id}/unblock` | `clients.update` |
| PATCH | `/clients/{id}/credit` | `clients.update` |
| GET | `/clients/{id}/payment-history` | `clients.view` |

**POST `/clients` body:**

```json
{
  "name": "Khaled Hassan",
  "phone": "+201234567890",
  "email": "khaled@example.com",
  "address": "Cairo, Egypt",
  "credit_limit": "5000.00",
  "status": "active",
  "notes": null
}
```

### Client Payments (collection-level)

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/client-payments?client_id=&from_date=&to_date=&page=` | `sales.view` |
| POST | `/client-payments` | `sales.collect_payment` |
| GET | `/client-payments/{id}` | `sales.view` |
| DELETE | `/client-payments/{id}` | `sales.collect_payment` |

---

## 6.8 Products & Inventory

### Products

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/products?is_active=&category=&search=&has_variants=&page=&per_page=` | `products.view\|pos.view` |
| POST | `/products` | `products.create` |
| GET | `/products/{id}` | `products.view` |
| PUT / PATCH | `/products/{id}` | `products.update` |
| DELETE | `/products/{id}` | `products.delete` |
| DELETE | `/products/bulk-delete` | `products.delete` |
| GET | `/products/next-barcode` | `products.create` |
| GET | `/products/next-sku` | `products.create` |
| GET | `/products/next-codes` | `products.create` |
| GET | `/product-variant-filters` | `products.view` |
| PATCH | `/products/{product}/inventories/{inventory}/min-threshold` | `products.update` |
| GET | `/products/{id}/transactions` | `products.view` |
| GET | `/products/{id}/financial-info` | `products.view` |

### Products Import

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/products/import/template` | `products.import` |
| POST | `/products/import/preview` (multipart) | `products.import` |
| POST | `/products/import` (multipart) | `products.import` |
| GET | `/products/import/{importJobId}` | `products.import` |
| GET | `/products/import/{importJobId}/errors` | `products.import` |

### Product Categories

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/product-categories` | `products.view` |
| POST | `/product-categories` | `products.create` |
| PUT / PATCH | `/product-categories/{id}` | `products.update` |
| DELETE | `/product-categories/{id}` | `products.delete` |

### Inventories

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/inventories` | `inventory.view\|pos.view` |
| POST | `/inventories` | `inventory.create` |
| GET | `/inventories/{id}` | `inventory.view` |
| GET | `/inventories/default` | `inventory.view\|pos.view` |
| PUT / PATCH | `/inventories/{id}` | `inventory.update` |
| DELETE | `/inventories/{id}` | `inventory.delete` |
| GET | `/inventories/{inventory}/products` | `inventory.view` |
| POST | `/inventories/{inventory}/products` | `inventory.update` |
| PATCH | `/inventories/{inventory}/products/{product}` | `inventory.update` |
| POST | `/inventories/transfer` | `inventory.update` |

### Stock Movements

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/stock-movements?product_id=&from_date=&to_date=&type=&page=&per_page=` | `products.view` |
| POST | `/stock-movements` | `products.update` |
| POST | `/stock-movements/{product_id}/adjust` | `products.update` |

---

## 6.9 Suppliers & Purchases (Phase 2)

### Suppliers

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/suppliers?search=&blacklisted=&rating=&sort_by=&sort_order=&page=&per_page=` | `suppliers.view` |
| POST | `/suppliers` | `suppliers.create` |
| GET | `/suppliers/{id}` | `suppliers.view` |
| PUT / PATCH | `/suppliers/{id}` | `suppliers.update` |
| DELETE | `/suppliers/{id}` | `suppliers.delete` |
| GET | `/suppliers-search?q=...` | `suppliers.view` |
| POST | `/suppliers/import` (multipart) | `suppliers.create` |
| GET | `/suppliers/export` | `suppliers.view` |
| GET | `/suppliers/{id}/invoices` | `suppliers.view` |
| GET | `/suppliers/{id}/returns` | `suppliers.view` |
| GET | `/suppliers/{id}/financial-summary` | `suppliers.view` |
| GET | `/suppliers/{id}/payments` | `suppliers.view` |
| GET | `/suppliers/{id}/ledger?from=&to=` | `suppliers.view` |

### Supplier sub-resources

| Collection | Base path |
|-----------|-----------|
| Contacts | `/suppliers/{supplier}/contacts` (GET/POST/PUT/DELETE) |
| Addresses | `/suppliers/{supplier}/addresses` |
| Bank accounts | `/suppliers/{supplier}/bank-accounts` |
| Documents | `/suppliers/{supplier}/documents` (multipart upload) |

### Purchase Invoices

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/purchase-invoices?supplier_id=&status=&from_date=&to_date=&page=&per_page=` | `purchases.view` |
| POST | `/purchase-invoices` | `purchases.create` |
| GET | `/purchase-invoices/{id}` | `purchases.view` |
| PUT / PATCH | `/purchase-invoices/{id}` | `purchases.update` |
| DELETE | `/purchase-invoices/{id}` | `purchases.delete` |
| POST | `/purchase-invoices/{id}/post` | `purchases.update` |
| POST | `/purchase-invoices/{id}/cancel` | `purchases.update` |
| POST | `/purchase-invoices/{id}/payment` | `purchases.update` |
| POST | `/purchase-invoices/{id}/return` | `purchases.update` |
| POST | `/purchase-invoices/{id}/repost-inventory` | `purchases.update` |

### Supplier Payments

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/supplier-payments?supplier_id=&from_date=&page=` | `expenses.view` |
| POST | `/supplier-payments` | `expenses.create` |
| GET | `/supplier-payments/{id}` | `expenses.view` |
| PUT / PATCH | `/supplier-payments/{id}` | `expenses.update` |
| DELETE | `/supplier-payments/{id}` | `expenses.delete` |

### Bills

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/bills` | `expenses.view` |
| GET | `/bills/pending` | `expenses.view` |
| GET | `/bills/summary/status` | `expenses.view` |
| PUT | `/bills/{id}/status` | `expenses.update` |

---

## 6.10 Expenses

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/expenses?category_id=&from_date=&to_date=&paid_via=&page=&per_page=` | `expenses.view` |
| POST | `/expenses` | `expenses.create` |
| GET | `/expenses/{id}` | `expenses.view` |
| PUT / PATCH | `/expenses/{id}` | `expenses.update` |
| DELETE | `/expenses/{id}` | `expenses.delete` |

### Expense Categories

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/expense-categories` | `expenses.view` |
| POST | `/expense-categories` | `expenses.create` |
| PUT / PATCH | `/expense-categories/{id}` | `expenses.update` |
| DELETE | `/expense-categories/{id}` | `expenses.delete` |

---

## 6.11 Accounts

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/accounts` | `accounts.view\|pos.view` |
| POST | `/accounts` | `accounts.create` |
| GET | `/accounts/{id}` | `accounts.view\|pos.view` |
| PUT / PATCH | `/accounts/{id}` | `accounts.update` |
| DELETE | `/accounts/{id}` | `accounts.delete` |
| GET | `/accounts/{id}/balance` | `accounts.view\|pos.view` |
| GET | `/accounts/{id}/history?from=&to=&type=&page=` | `accounts.view\|pos.view` |
| POST | `/accounts/deposit` | `accounts.create` |
| POST | `/accounts/withdraw` | `accounts.create` |
| POST | `/accounts/transfer` | `accounts.create` |
| POST | `/accounts/{id}/update-opening-balance` | `accounts.update` |

### Transfers (records)

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/accounts/transfers?from_account_id=&to_account_id=&from_date=&page=` | `accounts.view` |
| POST | `/accounts/transfers` | `accounts.create` |
| GET | `/accounts/transfers/{id}` | `accounts.view` |
| PUT / PATCH | `/accounts/transfers/{id}` | `accounts.update` |
| DELETE | `/accounts/transfers/{id}` | `accounts.delete` |

### Adjustments

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/account-adjustments?account_id=&from_date=&reason=&page=` | `accounts.view` |
| POST | `/account-adjustments` | `accounts.adjust` |
| GET | `/account-adjustments/{id}` | `accounts.view` |
| DELETE | `/account-adjustments/{id}` | `accounts.adjust` |

---

## 6.12 Employees & Profile

### Self profile

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/profile` | — |
| PUT | `/profile` | `profile.edit` (implicit) |
| POST | `/profile/avatar` (multipart) | — |
| PUT | `/profile/password` | `profile.edit` |

### Employees

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/employees?status=&role_id=&search=&page=&per_page=` | `employees.view` |
| POST | `/employees` | `employees.create` |
| GET | `/employees/{id}` | `employees.view` |
| PUT / PATCH | `/employees/{id}` | `employees.update` |
| PATCH | `/employees/{id}/status` | `employees.update` |
| DELETE | `/employees/{id}` | `employees.delete` |
| GET | `/employees/roles` | `employees.view` |
| POST | `/users/{id}/suspend` | `employees.update` |
| POST | `/users/{id}/activate` | `employees.update` |
| PUT | `/users/{id}/inventories` | `employees.update` |

---

## 6.13 Reports (Phase 3)

### Operational

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/monthly-report?month=YYYY-MM` | `reports.view` |
| GET | `/roi/current` | `reports.view` |
| GET | `/roi?from_month=&to_month=` | `reports.view` |
| GET | `/reports/product-insights?from=&to=&limit=` | `reports.view` |
| GET | `/reports/product-sales?from=&to=&category_id=` | `reports.view` |
| GET | `/reports/product-profit?from=&to=` | `reports.view` |
| GET | `/reports/daily-sales?from=&to=` | `reports.view` |
| GET | `/reports/monthly-sales?year=YYYY` | `reports.view` |
| GET | `/reports/cash-credit?from=&to=` | `reports.view` |
| GET | `/reports/net-sales?from=&to=` | `reports.view` |
| GET | `/reports/outstanding-invoices?page=&per_page=` | `reports.view` |
| GET | `/reports/product-return-ratio?from=&to=` | `reports.view` |
| GET | `/reports/sales-returns?from=&to=&page=` | `reports.view` |
| GET | `/reports/ar-aging` | `reports.view` |
| GET | `/reports/ap-aging` | `reports.view` |
| GET | `/reports/invoice-reconciliation?from=&to=` | `reports.view` |
| GET | `/reports/inventory-reconciliation` | `reports.view` |
| GET | `/reports/pos-shift-variance?from=&to=` | `reports.view` |
| GET | `/reports/accountant-export?format=csv\|json&from=&to=` | `reports.view` |

### Accounting

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/reports/trial-balance?as_of=YYYY-MM-DD` | `reports.view` |
| GET | `/reports/trial-balance-verification?as_of=` | `reports.view` |
| GET | `/reports/income-statement?from=&to=` | `reports.view` |
| GET | `/reports/balance-sheet?as_of=` | `reports.view` |
| GET | `/reports/general-ledger?account_id=&from=&to=` | `reports.view` |

---

## 6.14 Settings

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/settings/company` | `company.view` |
| PUT | `/settings/company` | `company.update` |
| POST | `/settings/company/logo` (multipart) | `company.update` |
| GET | `/settings/theme` | `company.view` |
| PUT | `/settings/theme` | `company.update` |
| GET | `/settings/currencies` | `settings.view` |
| POST / PUT / DELETE | `/settings/currencies[/{id}]` | `settings.edit` |
| GET | `/settings/attributes` | `settings.view` |
| GET | `/settings/units` | `settings.view` |
| GET | `/settings/taxes` | `settings.view` |
| GET | `/settings/payment-methods` | `settings.view` |
| GET | `/payment-methods/active` | — |
| GET | `/settings/roles` | `roles.view` |
| GET | `/settings/languages` | `settings.view` |
| PUT | `/settings/languages` | `settings.edit` |
| GET | `/settings/receipt` | `settings.view` |
| PUT | `/settings/receipt` | `settings.edit` |
| GET | `/settings/tax-config` | `settings.view` |
| PUT | `/settings/tax-config` | `settings.edit` |

---

## 6.15 Branches

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/branches` | (implicit) |
| POST | `/branches` | (implicit) |
| GET | `/branches/{id}` | — |
| PUT / PATCH | `/branches/{id}` | — |
| DELETE | `/branches/{id}` | — |
| GET | `/branches/{id}/active-shifts` | — |
| GET | `/branches/{id}/sales-summary?from=&to=` | — |
| GET | `/branches/{branch}/terminals` | — |
| POST | `/branches/{branch}/terminals` | — |
| GET | `/branches/{branch}/terminals/{id}` | — |
| PUT | `/branches/{branch}/terminals/{id}` | — |
| DELETE | `/branches/{branch}/terminals/{id}` | — |
| GET | `/branches/{branch}/terminals/available-to-assign` | — |
| POST | `/branches/{branch}/terminals/assign` | — |

---

## 6.16 Billing (read-only on mobile)

| Method | Path | Permission |
|--------|------|-----------|
| GET | `/billing/subscription` | `billing.view` |
| GET | `/billing/providers` | `billing.view` |
| POST | `/billing/checkout` | `billing.manage` (web handoff) |
| GET | `/billing/transactions?status=&from_date=&page=` | `billing.view` |
| GET | `/billing/transactions/{reference}` | `billing.view` |

---

## 6.17 Headers & Query Conventions

### Common headers

```
Accept: application/json
Authorization: Bearer {jwt}
Content-Type: application/json   (or multipart/form-data for uploads)
Accept-Language: en|ar           (controls server-side error messages)
X-Client: mobile-ios-1.0.0       (recommended telemetry header)
```

### Common query params

- `page` (int, default 1)
- `per_page` (int, default 15, max 100)
- `search` (free-text)
- `sort_by` / `sort_order` (`asc` | `desc`)
- `from_date` / `to_date` (`YYYY-MM-DD`)
- `status` (resource-specific enum)

### Pagination response

```json
{
  "data": [...],
  "meta": {
    "current_page": 2,
    "last_page": 10,
    "per_page": 15,
    "total": 143
  },
  "links": {
    "first": "...?page=1",
    "last":  "...?page=10",
    "prev":  "...?page=1",
    "next":  "...?page=3"
  }
}
```

---

## 6.18 Rate Limits

| Endpoint group | Limit |
|----------------|-------|
| Login | 10 req/min |
| Registration | 5 req/hour |
| POS mutations | 30 req/min |
| Checkout (billing) | 30 req/min |
| Default | 60 req/min (prod) / 600 (local & test) |

On `429 Too Many Requests`, the response includes `Retry-After` header (seconds). Mobile MUST honor it.

---

## 6.19 File Upload Conventions

Multipart endpoints:

- `/profile/avatar` — field `avatar`
- `/settings/company/logo` — field `logo`
- `/products/import` — field `file` (CSV)
- `/products/import/preview` — field `file`
- `/suppliers/import` — field `file`
- `/suppliers/{supplier}/documents` — field `document`

**Size limit:** 10 MB per file unless backend config says otherwise.
**Allowed types:** images (`jpg`, `jpeg`, `png`, `webp`), docs (`pdf`, `csv`, `xlsx`).
**Mobile hint:** compress images client-side to 1024px max dimension, 80% JPEG quality before upload.

---

## 6.20 Canonical Error Codes (App-side mapping)

| HTTP | App handling |
|------|-------------|
| 200/201/204 | Success |
| 400 | Show toast with `message` |
| 401 | Logout flow |
| 402 | Billing banner (SCR-152) |
| 403 | Permission denied toast; SCR-203 if full-screen |
| 404 | SCR-202 or inline "Not found" |
| 422 | Map `errors` to form fields |
| 429 | Backoff using `Retry-After`; show snackbar "Too many requests, retrying…" |
| 500/502/503/504 | Snackbar + retry; log to crash reporter |
