# 05 — Screens Specification

This document enumerates every screen the mobile app must render, with exact fields, actions, navigation, and permission gates. Each screen has an identifier `SCR-XXX`.

## Screen Index

| ID | Screen | Phase |
|----|--------|-------|
| SCR-001 | Splash / Bootstrap | 1 |
| SCR-002 | Tenant Slug Entry | 1 |
| SCR-003 | Login | 1 |
| SCR-004 | Forgot Password | 1 |
| SCR-005 | Language Picker | 1 |
| SCR-010 | Home / Dashboard | 1 |
| SCR-011 | KPIs Detail | 1 |
| SCR-012 | Low-Stock List | 1 |
| SCR-013 | Recent Orders List | 1 |
| SCR-020 | POS Main | 1 |
| SCR-021 | POS Cart | 1 |
| SCR-022 | POS Payment Sheet | 1 |
| SCR-023 | POS Variant Picker | 1 |
| SCR-024 | POS Receipt | 1 |
| SCR-025 | POS Orders List | 1 |
| SCR-026 | POS Order Detail | 1 |
| SCR-027 | POS Return | 1 |
| SCR-030 | Open Shift Modal | 1 |
| SCR-031 | Close Shift Modal | 1 |
| SCR-032 | Cash Movement Modal | 1 |
| SCR-033 | Shift History | 1 |
| SCR-034 | Shift Detail | 1 |
| SCR-040 | Clients List | 1 |
| SCR-041 | Client Detail | 1 |
| SCR-042 | Client Form (Create/Edit) | 1 |
| SCR-043 | Record Client Payment | 1 |
| SCR-044 | Client Statement | 1 |
| SCR-050 | Products List | 1 |
| SCR-051 | Product Detail | 1 |
| SCR-052 | Barcode Scanner | 1 |
| SCR-060 | Inventories List | 1 |
| SCR-061 | Inventory Detail | 1 |
| SCR-062 | Stock Transfer | 2 |
| SCR-063 | Stock Adjustment | 2 |
| SCR-070 | Expenses List | 1 |
| SCR-071 | Expense Form | 1 |
| SCR-080 | Accounts List | 1 |
| SCR-081 | Account Detail | 1 |
| SCR-082 | Deposit / Withdraw Form | 1 |
| SCR-083 | Transfer Form | 1 |
| SCR-090 | Sales Invoices List | 2 |
| SCR-091 | Sales Invoice Detail | 2 |
| SCR-092 | Sales Invoice Form | 2 |
| SCR-093 | Record Invoice Payment | 2 |
| SCR-094 | Sales Return Form | 2 |
| SCR-100 | Suppliers List | 2 |
| SCR-101 | Supplier Detail | 2 |
| SCR-102 | Supplier Form | 2 |
| SCR-103 | Record Supplier Payment | 2 |
| SCR-110 | Purchase Invoices List | 2 |
| SCR-111 | Purchase Invoice Detail | 2 |
| SCR-112 | Purchase Invoice Form | 2 |
| SCR-120 | Reports Hub | 3 |
| SCR-121 | Report Detail (generic) | 3 |
| SCR-130 | Profile | 1 |
| SCR-131 | Edit Profile | 1 |
| SCR-132 | Change Password | 1 |
| SCR-133 | Settings (Read) | 1 |
| SCR-140 | Notifications Center | 2 |
| SCR-150 | Billing Status | 1 |
| SCR-151 | Trial Expired | 1 |
| SCR-152 | Subscription Blocked | 1 |
| SCR-200 | Generic Error | 1 |
| SCR-201 | No Connection | 1 |
| SCR-202 | Not Found | 1 |
| SCR-203 | Permission Denied | 1 |

---

## SCR-001 Splash / Bootstrap

**Purpose:** Hide initial async loading while JWT is validated and tenant config is fetched.

**Behavior:**

- Display full-bleed Operix logo (or tenant logo if previously logged in).
- Animated loader.
- After bootstrap:
  - Valid session → SCR-010
  - No session but stored tenant → SCR-003
  - No session, no tenant → SCR-002

**Timeout:** 5s — on timeout, show SCR-201 with retry.

---

## SCR-002 Tenant Slug Entry

**Purpose:** Resolve which tenant the user is signing into.

**Fields:**

- Tenant Slug (text, required, lowercase, 3-50 chars, trimmed)
- "Continue" button

**Actions:**

- On submit: `GET /api/v1/tenant-config/{slug}`
- On 200: store slug + config, navigate to SCR-003.
- On 404: inline error "We couldn't find that business. Check the spelling."
- Link: "Don't have an account? Register on web" (opens browser).

**Top-right:** language toggle (EN/AR).

---

## SCR-003 Login

**Header:** Tenant logo + name (from cached config).

**Fields:**

- Email (text, email keyboard, required)
- Password (text, masked, show/hide toggle, required)
- "Remember me" checkbox (default on)

**Primary Action:** "Sign In" button (disabled until both fields valid).

**Secondary Actions:**

- "Forgot password?" → SCR-004
- "Switch business" → SCR-002 (clears slug)
- Language toggle

**API:** `POST /api/v1/{tenant_slug}/login`

**On success:**

- Store JWT securely.
- Bootstrap session (FR-00-006).
- Navigate to SCR-010 (or cashier home if role is cashier).

**On 401:** inline error "Invalid email or password."

**On 403 (user suspended):** "Your account is suspended. Contact admin."

**On 402:** SCR-152.

---

## SCR-004 Forgot Password

**Fields:**

- Email (required)

**Action:** `POST /api/v1/auth/forgot-password`

**On success:** full-screen confirmation "We emailed a reset link to {email}. Open the link on any device to reset your password."

**Back to Login** link.

---

## SCR-010 Home / Dashboard

**Top App Bar:**

- Avatar (→ SCR-130)
- Tenant name
- Period selector (Today / 7D / Month / Custom)
- Notifications bell (badge count) (Phase 2)

**Sections:**

1. **KPI Row** — 2×2 grid of cards: Revenue, Expenses, Profit, Total Balance. Tap → SCR-011.
2. **Quick Actions** — horizontal scroll of role-appropriate actions.
3. **Sales Trend** — line chart (7D or selected).
4. **Top Products** — list of 5 with revenue.
5. **Low Stock** — list of 5; "View all" → SCR-012.
6. **Recent Orders** — list of 5; "View all" → SCR-013.

**Bottom Nav:** Home / POS / Clients / Products / More (varies per role).

**Pull-to-refresh:** refetches all sections.

**Permission:** `dashboard.view`. If absent, render role-appropriate alternative home (e.g., cashier goes straight to SCR-020).

---

## SCR-020 POS Main

**Top App Bar:**

- Shift status pill (Open / Closed + timer)
- Barcode scan icon → SCR-052
- More menu (Cash In/Out, Close Shift, Orders)

**Body:**

- Search input (product name / SKU / barcode paste)
- Category filter chips
- Product grid: image, name, price, stock badge
  - Stock badge colors: green (>threshold), yellow (≤threshold), red (0)
  - Out-of-stock tap: toast "Out of stock"

**Floating Cart Indicator (mobile):** shows item count + total. Tap → SCR-021.

**Tablet layout:** 2/3 products, 1/3 cart side-by-side.

**Permission gate:** `pos.view`. If no open shift: show prompt to SCR-030.

---

## SCR-021 POS Cart

**List:**

- Each line: product name, variant, qty stepper (+/−), unit price, line total, remove (swipe).
- Empty state: "Add items from the product list."

**Client Row:** "Walk-in customer" / selected client. Tap to change (opens Client picker modal).

**Totals Block:**

- Subtotal
- Discount (tap to edit: type + value)
- Tax (display only, computed server-side hint)
- Shipping (optional editable)
- Grand Total (large, bold)

**Primary Button:** "Charge {grand_total}" → SCR-022.

**Secondary:** "Hold" (save as draft — Phase 3).

---

## SCR-022 POS Payment Sheet

**Header:** "Payment" + grand total.

**Payment Method Tabs:** Cash / Card / Wallet / Credit (or as per tenant methods).

**Per-method inputs:**

- **Cash:** Tendered amount input → auto-computed Change.
- **Card/Wallet/Other:** Amount input (default = grand_total).
- **Credit:** No amount input — entire total becomes due on client account (requires client selected and `sales.pay_credit`).

**Split payment mode:** "+ Add payment method" button below method list.

**Account picker per method:** visible only if `pos.select_account`.

**Notes (optional).**

**Primary Button:** "Complete Sale"

**API:** `POST /pos-orders`.

**On success:** dismiss sheet → SCR-024.

**On validation error:** inline errors per field.

---

## SCR-024 POS Receipt

**Layout:** receipt-styled card.

**Content:**

- Tenant name + logo
- Receipt number (`RCP-YYYYMMDD-XXXX`)
- Date/time
- Cashier name
- Client (if attached)
- Items table (name, qty, price, total)
- Subtotal / Discount / Tax / Shipping / Grand Total
- Payment breakdown (method + amount)
- Change (for cash)
- Footer text (from `GET /settings/receipt`)

**Actions:**

- "Print" (Phase 3 — thermal printer)
- "Share" (system share sheet — PDF or image)
- "Email to customer" (if customer has email)
- "New Sale" (primary) → back to SCR-020
- "View Orders" → SCR-025

---

## SCR-030 Open Shift Modal

**Fields:**

- Terminal (dropdown, required, from `/pos/shift/available-drawers`)
- Opening cash (decimal, required, ≥ 0)
- Notes (optional)

**Primary:** "Open Shift"

**API:** `POST /pos/shift/open`.

**Permission:** `shifts.create`.

---

## SCR-031 Close Shift Modal

**Live Summary (from `/pos/shift/summary`):**

- Opening cash
- Cash sales
- Cash in
- Cash out
- Expected cash = `opening + cash_sales + cash_in − cash_out`

**Input:**

- Actual cash count (decimal, required)
- Variance (auto-computed live; color-coded)
- Variance notes (required if variance ≠ 0)

**Primary:** "Close Shift"

**API:** `POST /pos/shift/close`.

**Permission:** `shifts.update`.

---

## SCR-032 Cash Movement Modal

**Fields:**

- Type (In / Out, segmented)
- Amount (decimal, required)
- Reason (required string)
- Account (dropdown)
- Payment method (dropdown)
- Notes (optional)

**API:** `POST /pos/shift/cash-movements`.

---

## SCR-040 Clients List

**Top App Bar:**

- Search input
- Filter icon → sheet (Has Due, Has Overdue, Status)
- "+" to SCR-042 (if `clients.create`)

**KPI Row (collapsible):**

- Total Clients | With Outstanding | Total AR | Total Overdue

**List:**

- Avatar (initials), name, phone, outstanding (red if overdue), status badge.

**Empty state:** "No clients yet. Tap + to add your first customer."

**Pagination:** infinite scroll.

**Permission:** `clients.view` OR `pos.clients`.

---

## SCR-041 Client Detail

**Header:** avatar, name, phone, status badge, edit button (if permission).

**KPI Row:** Balance | Credit Limit | Total Orders | Overdue.

**Tabs:**

- Overview — contact info, credit info, notes
- Orders — list of all orders (POS + Sales Invoices)
- Due — outstanding invoices
- Payments — payment history
- Statement — date-range ledger
- Activity — audit timeline

**Action Menu (FAB or overflow):**

- Record Payment (`sales.collect_payment`)
- Block / Unblock (`clients.update`)
- Adjust Credit Limit (`clients.update`)
- Delete (`clients.delete`)

---

## SCR-042 Client Form

**Fields (create or edit):**

- Name (required)
- Phone (required, with country-code picker)
- Email (optional, email validation)
- Address (optional, multiline)
- Credit limit (optional, decimal ≥ 0)
- Credit days threshold (optional)
- Tax-exempt (toggle) + reason (shown if on)
- Status (active/inactive)
- Notes (optional, multiline)

**Primary:** "Save"

**API:** `POST /clients` / `PATCH /clients/{id}`.

---

## SCR-043 Record Client Payment

**Fields:**

- Amount (required, decimal > 0; max = total outstanding)
- Payment method (required)
- Account (auto-filled from method)
- Reference (optional)
- Payment date (default today)
- Notes (optional)

**Primary:** "Record Payment"

**API:** `POST /clients/{id}/record-payment`.

---

## SCR-050 Products List

**Top App Bar:**

- Search
- Barcode scan
- Filter (category, active only, has variants)
- Layout toggle (grid / list)

**Grid cell:** image, name, price, stock (`qty / min`), low-stock badge.

**Permission:** `products.view`.

---

## SCR-051 Product Detail

**Header:** image carousel, name, SKU, barcode (with copy button).

**Summary Chips:** Category | Unit | Default Tax.

**Price Block:** Cost | Selling | Margin %.

**Stock Block:** list per inventory (name, qty, min threshold, "low" badge).

**Variants (if any):** list with SKU, label, stock.

**Tabs:**

- Transactions (`GET /products/{id}/transactions`)
- Financial Info (`GET /products/{id}/financial-info`)

**Actions:**

- Edit (`products.update`)
- Adjust Stock (`inventory.update`) — Phase 2
- Delete (`products.delete`)

---

## SCR-052 Barcode Scanner

**Full-screen camera** with overlay rectangle.

**On decode:**

- Flash success animation.
- Haptic feedback.
- Return decoded string to caller (POS, Product search).

**Controls:**

- Close (X)
- Torch toggle
- Manual entry fallback (text input)

**Permission:** Camera permission request handled per OS.

---

## SCR-060 Inventories List

**List:** name, branch, products count, total stock value, low-stock count badge.

**Default inventory** pinned to top with star icon.

---

## SCR-061 Inventory Detail

**Header:** name, branch, location.

**KPIs:** Products | Total Units | Low Stock | Out of Stock.

**Product List:** name, qty, min threshold, action menu (adjust, transfer).

**Actions:**

- New Transfer (Phase 2)
- Edit

---

## SCR-070 Expenses List

**Top App Bar:**

- Search / date filter / category filter
- "+" to SCR-071

**Row:** date, category, amount, payment method, created_by.

**Totals footer:** total for selected range.

---

## SCR-071 Expense Form

**Fields:**

- Category (required, from `/expense-categories`)
- Amount (required, decimal > 0)
- Date (required, default today)
- Payment method (optional)
- Account (auto from method)
- Description (optional, short)
- Notes (optional, long)
- Mark as Ads (toggle, affects reporting)
- Receipt photo (optional, Phase 2)

**Primary:** "Save"

---

## SCR-080 Accounts List

**Row:** name, type icon, balance (large), default star.

**Summary at top:** total across all accounts by currency.

---

## SCR-081 Account Detail

**Header:** name, type, current balance.

**Actions row:** Deposit | Withdraw | Transfer | Edit.

**History list:** date, description, debit, credit, running balance.

**Filter:** date range, type (deposit/withdrawal/transfer/adjustment).

---

## SCR-082 Deposit / Withdraw Form

**Fields:**

- Account (pre-filled)
- Amount (required)
- Reference (optional)
- Notes (optional)

**API:** `POST /accounts/deposit` or `/accounts/withdraw`.

---

## SCR-083 Transfer Form

**Fields:**

- From account
- To account (must differ)
- Amount
- Reference
- Notes

**API:** `POST /accounts/transfer`.

---

## SCR-130 Profile

**Header:** avatar, name, email, role badge, "Edit" button.

**Sections:**

- My info (phone, assigned inventories)
- Security → Change Password (SCR-132)
- Language
- Notifications (Phase 2 toggles)
- About (app version, backend URL masked)
- Sign Out (red)

---

## SCR-131 Edit Profile

**Fields:** name, email, phone.

**API:** `PUT /profile`.

---

## SCR-132 Change Password

**Fields:** current, new, confirm new.

**API:** `PUT /profile/password`.

---

## SCR-150 Billing Status

**Header:** plan name, status chip (Trial / Active / Past Due / Suspended).

**Content:**

- Trial: days remaining, "Upgrade on Web" button.
- Active: renewal date, amount, "Manage on Web".
- Past Due: red warning + "Pay Now on Web".
- Suspended: SCR-152.

**Permission:** `billing.view`.

---

## SCR-152 Subscription Blocked

**Full-screen modal** that cannot be dismissed.

**Content:**

- Icon + headline "Subscription inactive"
- Message from server (`message` field in 402 response)
- CTA (if `billing.manage`): "Renew on Web" → external link
- Secondary: "Sign out"

---

## SCR-200 Generic Error

Used for unhandled 5xx errors.

**Content:** friendly illustration, "Something went wrong", retry button, "Report issue" (opens email).

---

## SCR-201 No Connection

**Content:** offline illustration, "Check your internet connection", "Retry" button.

**Trigger:** no network + failed request.

---

## SCR-202 Not Found

Used when a deep-linked resource returns 404.

---

## SCR-203 Permission Denied

**Content:** lock icon, "You don't have permission to access this.", "Go home" button.

**Trigger:** when UI routing lands on a screen without the required permission (should be rare if gating is correct).

---

## Navigation Architecture

```
RootStack
├── SplashScreen (SCR-001)
├── AuthStack
│   ├── TenantSlugScreen (SCR-002)
│   ├── LoginScreen (SCR-003)
│   └── ForgotPasswordScreen (SCR-004)
└── AppShell (bottom tabs, role-aware)
    ├── HomeTab
    │   ├── DashboardScreen (SCR-010)
    │   ├── LowStockListScreen (SCR-012)
    │   └── RecentOrdersListScreen (SCR-013)
    ├── POSTab
    │   ├── POSMainScreen (SCR-020)
    │   ├── POSCartScreen (SCR-021) [modal]
    │   ├── POSOrdersListScreen (SCR-025)
    │   ├── POSOrderDetailScreen (SCR-026)
    │   ├── POSReturnScreen (SCR-027)
    │   ├── ShiftHistoryScreen (SCR-033)
    │   └── ShiftDetailScreen (SCR-034)
    ├── ClientsTab
    │   ├── ClientsListScreen (SCR-040)
    │   ├── ClientDetailScreen (SCR-041)
    │   └── ClientFormScreen (SCR-042)
    ├── ProductsTab
    │   ├── ProductsListScreen (SCR-050)
    │   ├── ProductDetailScreen (SCR-051)
    │   ├── InventoriesListScreen (SCR-060)
    │   └── InventoryDetailScreen (SCR-061)
    └── MoreTab
        ├── MoreMenuScreen
        ├── ExpensesListScreen (SCR-070)
        ├── ExpenseFormScreen (SCR-071)
        ├── AccountsListScreen (SCR-080)
        ├── AccountDetailScreen (SCR-081)
        ├── SuppliersListScreen (SCR-100) [Phase 2]
        ├── PurchaseInvoicesListScreen (SCR-110) [Phase 2]
        ├── ReportsHubScreen (SCR-120) [Phase 3]
        ├── ProfileScreen (SCR-130)
        ├── EditProfileScreen (SCR-131)
        ├── ChangePasswordScreen (SCR-132)
        └── BillingStatusScreen (SCR-150)
```

## Role-Specific Tab Bars

| Role | Tabs |
|------|------|
| Owner / Admin | Home, POS, Clients, Products, More |
| Manager | Home, POS, Sales, Clients, More |
| Cashier | POS, Clients, Products, Shift, More |
| Storekeeper | Products, Inventories, Stock, More |
| Accountant | Home, Clients, Suppliers, Accounts, More |

Tab set is computed at login from role + permissions.

## Modal vs Push vs Replace

- **Modal** (`.sheet()`): Payment, Cart, Shift Open/Close, Cash Movement, Client Picker, Variant Picker
- **Push** (stack nav): Details, Forms, Settings
- **Replace**: after successful auth → home; after logout → login
