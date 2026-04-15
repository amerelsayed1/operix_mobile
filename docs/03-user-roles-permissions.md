# 03 — User Roles, Personas & Permissions

## 3.1 User Personas

### Persona 1 — Business Owner (Ahmed)

- **Age:** 35–55
- **Tech comfort:** Moderate
- **Primary device:** Personal smartphone
- **Time on app:** 5–15 min/day, multiple sessions
- **Goals:**
  - See today's sales, cash, and profit at a glance
  - Know if any branch has stock or cash issues
  - Approve large discounts or adjustments
  - Spot-check high-value transactions
- **Primary flows:** Dashboard → Low-stock → Accounts → Reports
- **Key permissions:** all `.view`, `reports.view`, `billing.view`, `accounts.*`, `dashboard.view`

### Persona 2 — Branch Manager (Sara)

- **Age:** 28–45
- **Tech comfort:** Moderate-high
- **Primary device:** Branch iPad/tablet + personal phone
- **Time on app:** 30–60 min/day
- **Goals:**
  - Oversee cashiers and shifts at her branch
  - Handle returns, approve exceptions
  - Record supplier payments
  - Close day's accounts
- **Primary flows:** Dashboard → POS Shifts → Sales Invoices → Suppliers → Accounts
- **Key permissions:** Most `.view`/`.create`/`.update`, `sales.approve`, `shifts.update`, `accounts.create`, `expenses.create`

### Persona 3 — Cashier (Omar)

- **Age:** 20–35
- **Tech comfort:** Low-moderate
- **Primary device:** Dedicated shop tablet or phone
- **Time on app:** Full shift (4–8 hours)
- **Goals:**
  - Open shift at start of day
  - Ring up customers quickly (barcode or search)
  - Record payments (cash or credit)
  - Close shift with accurate cash count
- **Primary flows:** Shift open → POS → Shift close
- **Key permissions:** `pos.*` (limited), `shifts.create`, `shifts.update`, `pos.clients`, `sales.collect_payment`

### Persona 4 — Storekeeper (Yasmin)

- **Age:** 22–40
- **Tech comfort:** Low-moderate
- **Primary device:** Warehouse tablet
- **Time on app:** 20–60 min/day
- **Goals:**
  - Check stock levels by location
  - Receive goods from suppliers
  - Perform transfers between warehouses
  - Adjust stock with reason
- **Primary flows:** Products → Inventories → Stock Movements → Transfers
- **Key permissions:** `products.view`, `inventory.view`, `inventory.update`, `products.update` (limited)

### Persona 5 — Accountant (Karim)

- **Age:** 28–55
- **Tech comfort:** Moderate-high
- **Primary device:** Personal phone + office laptop
- **Time on app:** 10–30 min/day (mobile), rest on web
- **Goals:**
  - Record supplier and client payments
  - Track expenses
  - Review account balances and transfers
  - Monitor overdue receivables/payables
- **Primary flows:** Clients → Suppliers → Accounts → Expenses → Reports (Phase 3)
- **Key permissions:** `sales.collect_payment`, `sales.pay_credit`, `expenses.*`, `accounts.*`, `reports.view`

## 3.2 Role System

Operix uses a **dual-layer access control**:

1. **Roles** — named collections of permissions (e.g., "Owner", "Manager", "Cashier")
2. **Permissions** — granular `module.action` strings attached to roles

Roles are tenant-scoped. A user has exactly one `role_id` (many-to-one). The role's permissions determine what the user can do.

### 3.2.1 Default Roles (Seeded per Tenant)

| Role | Scope | Typical Permissions |
|------|-------|---------------------|
| **Admin / Owner** | Full tenant access | ALL permissions (bypass check) |
| **Manager** | Branch oversight | Most `.view`, `.create`, `.update`; `sales.approve` |
| **Cashier** | POS-focused | `pos.*`, `shifts.create`, `shifts.update`, `pos.clients`, `sales.collect_payment`, `dashboard.view` (limited) |
| **Accountant** | Finance | `accounts.*`, `expenses.*`, `sales.pay_credit`, `sales.collect_payment`, `reports.view`, `clients.view`, `suppliers.view` |
| **Storekeeper** | Inventory | `products.view`, `inventory.view`, `inventory.update`, `products.update` |

The mobile app must **not** hard-code role names. It must drive UI from the **permission payload** returned by `GET /me/permissions`.

### 3.2.2 Admin Bypass

A user with role slug `admin` or role marked `is_admin=true` bypasses ALL permission checks on the backend. The mobile app must still call `/me/permissions` — the backend returns `{"*": true}` or equivalent for admin users, and the client must treat `*` as a wildcard match.

## 3.3 Permission Catalogue

The following `module.action` permissions are recognized by the backend and MUST be respected by mobile:

### 3.3.1 Dashboard

| Permission | Enables |
|-----------|---------|
| `dashboard.view` | Dashboard home, KPIs, charts, low-stock list, recent orders |

### 3.3.2 POS

| Permission | Enables |
|-----------|---------|
| `pos.view` | View POS screen, open POS, browse POS products, view POS orders |
| `pos.create` | Submit new POS order |
| `pos.update` | Edit existing POS order |
| `pos.delete` | Void / delete POS order |
| `pos.clients` | Attach client to POS order, search clients from POS |
| `pos.select_account` | Choose which account receives payment at POS |

### 3.3.3 Shifts

| Permission | Enables |
|-----------|---------|
| `shifts.create` | Open shift |
| `shifts.update` | Close shift, record cash movements |
| `shifts.view` | View shift history, shift details |

### 3.3.4 Sales

| Permission | Enables |
|-----------|---------|
| `sales.view` | View sales invoices & returns |
| `sales.create` | Create sales invoice |
| `sales.update` | Edit unposted sales invoice |
| `sales.delete` | Cancel sales invoice |
| `sales.approve` | Post invoice, approve/reject returns |
| `sales.return` | Create sales return |
| `sales.collect_payment` | Record payment from client |
| `sales.pay_credit` | Record payment against a sales invoice / POS order on credit |

### 3.3.5 Clients

| Permission | Enables |
|-----------|---------|
| `clients.view` | List, search, view client details |
| `clients.create` | Create new client |
| `clients.update` (alias `clients.edit`) | Edit client, block/unblock, adjust credit |
| `clients.delete` | Delete client |

### 3.3.6 Products

| Permission | Enables |
|-----------|---------|
| `products.view` | List, search, view products |
| `products.create` | Create product |
| `products.update` (alias `products.edit`) | Edit product, update min-threshold |
| `products.delete` | Delete product |
| `products.import` | Bulk import via CSV |
| `products.print_barcodes` | Print product barcodes |

### 3.3.7 Inventory

| Permission | Enables |
|-----------|---------|
| `inventory.view` | View inventories and stock levels |
| `inventory.create` | Create inventory (warehouse) |
| `inventory.update` (alias `inventory.edit`) | Transfer stock, adjust stock |
| `inventory.delete` | Delete inventory |

### 3.3.8 Suppliers

| Permission | Enables |
|-----------|---------|
| `suppliers.view` | View suppliers |
| `suppliers.create` | Add supplier |
| `suppliers.update` | Edit supplier |
| `suppliers.delete` | Delete supplier |

### 3.3.9 Purchases

| Permission | Enables |
|-----------|---------|
| `purchases.view` | View purchase invoices |
| `purchases.create` | Create purchase invoice |
| `purchases.update` | Edit/post/cancel purchase invoice, record payment, return |
| `purchases.delete` | Delete purchase invoice |

### 3.3.10 Expenses

| Permission | Enables |
|-----------|---------|
| `expenses.view` | View expenses |
| `expenses.create` | Create expense |
| `expenses.update` | Edit expense |
| `expenses.delete` | Delete expense |

### 3.3.11 Accounts

| Permission | Enables |
|-----------|---------|
| `accounts.view` | View accounts, balances, history |
| `accounts.create` | Create account, deposit, withdraw, transfer |
| `accounts.update` (alias `accounts.edit`) | Edit account, update opening balance |
| `accounts.delete` | Delete account |
| `accounts.adjust` | Create account adjustments |

### 3.3.12 Employees

| Permission | Enables |
|-----------|---------|
| `employees.view` | View employee list |
| `employees.create` | Create employee (web only in Phase 1) |
| `employees.update` (alias `employees.edit`) | Edit employee, suspend/activate, assign inventories |
| `employees.delete` | Delete employee |

### 3.3.13 Reports

| Permission | Enables |
|-----------|---------|
| `reports.view` | View all reports |

### 3.3.14 Settings

| Permission | Enables |
|-----------|---------|
| `settings.view` | View settings (mobile read-only in Phase 1) |
| `settings.edit` (alias `settings.update`) | Edit settings (web only in Phase 1) |
| `company.view` / `company.update` | Company profile |
| `roles.view` / `roles.create` / `roles.update` / `roles.delete` | Role management (web only) |

### 3.3.15 Billing

| Permission | Enables |
|-----------|---------|
| `billing.view` | View current subscription |
| `billing.manage` | Upgrade/renew (hand-off to web) |

### 3.3.16 Profile (self)

No permission required — always available to the authenticated user.

## 3.4 Permission-Driven UI Rules

**Rule 1 — Tab visibility**

Bottom navigation tabs must only show if at least one of the tab's primary permissions is held.

| Tab | Primary permissions |
|-----|---------------------|
| Home | `dashboard.view` |
| POS | `pos.view` |
| Sales | `sales.view` |
| Clients | `clients.view` or `pos.clients` |
| Products | `products.view` |
| More | always shown |

**Rule 2 — Action button gating**

Every mutating action button (Create, Edit, Delete, Approve, Post) MUST be hidden when the required permission is absent. Example:

```dart
if (permissions.has('pos.create')) {
  // show 'Complete Sale' button
}
```

**Rule 3 — Backend still enforces**

Even if UI gates are perfect, the mobile app MUST gracefully handle `403 Forbidden` from the server. A 403 with `required_permission` triggers a toast: "You don't have permission to `{action}`."

**Rule 4 — `*` wildcard**

If the permission payload contains `*` (admin), treat all `.has()` checks as true.

**Rule 5 — Pipe OR**

Some backend routes declare permission like `products.view|pos.view`. The client MUST support OR matching:

```dart
if (permissions.hasAny(['products.view', 'pos.view'])) { ... }
```

## 3.5 Permission Fetch & Caching

1. Fetch immediately after login: `GET /me/permissions`
2. Store in secure storage (not KeyChain — regular app prefs, but tenant-scoped).
3. Refresh on:
   - Every app cold start (if online)
   - Every `401` recovery
   - Manual pull-to-refresh on profile screen
4. On logout, **wipe** permissions.

### Expected response shape

```json
{
  "permissions": [
    "dashboard.view",
    "pos.view",
    "pos.create",
    "clients.view",
    "clients.create",
    "products.view"
  ],
  "role": {
    "id": 5,
    "name": "Cashier",
    "slug": "cashier"
  }
}
```

Or for admin:

```json
{
  "permissions": ["*"],
  "role": { "id": 1, "name": "Admin", "slug": "admin" }
}
```

> **Backend contract note:** Verify the actual response shape against `business_finance_manager_api/app/Http/Controllers/Tenant/AuthController.php` (method returning permissions). Normalize in the mobile API client.

## 3.6 Role-to-Screen Access Matrix

The table below summarizes which screens each default role can access (✅ = full access, 🔒 = view-only, — = hidden/blocked).

| Screen | Owner | Manager | Cashier | Storekeeper | Accountant |
|--------|-------|---------|---------|-------------|------------|
| Dashboard | ✅ | ✅ | 🔒 | — | 🔒 |
| POS | ✅ | ✅ | ✅ | — | — |
| Shift Open/Close | ✅ | ✅ | ✅ | — | — |
| Sales Invoices | ✅ | ✅ | 🔒 | — | 🔒 |
| Sales Returns | ✅ | ✅ | ✅ (create) | — | 🔒 |
| Clients | ✅ | ✅ | 🔒 (pos.clients) | — | ✅ |
| Client Payments | ✅ | ✅ | ✅ | — | ✅ |
| Products | ✅ | ✅ | 🔒 | ✅ | 🔒 |
| Inventories / Stock | ✅ | ✅ | — | ✅ | 🔒 |
| Suppliers | ✅ | ✅ | — | 🔒 | ✅ |
| Purchase Invoices | ✅ | ✅ | — | 🔒 | ✅ |
| Expenses | ✅ | ✅ | — | — | ✅ |
| Accounts | ✅ | ✅ | 🔒 | — | ✅ |
| Reports | ✅ | ✅ | — | — | ✅ |
| Profile | ✅ | ✅ | ✅ | ✅ | ✅ |
| Billing | ✅ | 🔒 | — | — | — |

## 3.7 Multi-Inventory Assignment

Users may be restricted to specific inventories via the `user_inventory` pivot table. This affects:

- POS product browsing — `GET /pos/products` scopes to the user's inventories
- Sales invoice creation — default `inventory_id` picks from user's list
- Stock visibility — only assigned inventories appear in stock views

The mobile app MUST fetch the user's allowed inventories from `GET /me` or `GET /inventories` and use the `is_default` one as the current context.
