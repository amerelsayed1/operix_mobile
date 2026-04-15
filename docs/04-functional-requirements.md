# 04 — Functional Requirements

This document defines functional requirements (FR) grouped by module. Each requirement has an ID (`FR-XX-NNN`) for traceability to tests and screens.

## FR-00: Session & Bootstrap

### FR-00-001: Tenant Resolution Before Login

- The app MUST allow the user to enter or confirm a tenant slug before login.
- On first launch, show a "Tenant" input field (prefilled from last-used slug if stored).
- Call `GET /api/v1/tenant-config/{slug}` to validate.
- On 404: show error "Business not found. Check the spelling."
- On 200: proceed to branded login with tenant logo and theme.

### FR-00-002: Branded Login

- Render tenant `logo_url` and apply `theme_primary_color` before login.
- Persist the tenant config in cache for offline launch.
- Fall back to default Operix branding only if no tenant has been chosen.

### FR-00-003: Authentication

- Accept email + password.
- POST to `/api/v1/{tenant_slug}/login`.
- On success, store JWT in secure storage.
- On failure (401): show inline form error ("Invalid email or password").
- On network error: show retry banner.

### FR-00-004: Remember Me

- Default to **on**.
- When on, store JWT in secure storage and auto-login on next launch.
- When off, clear JWT on app close.

### FR-00-005: Forgot Password

- Provide "Forgot password?" link.
- POST email to `/api/v1/auth/forgot-password`.
- Show success: "Check your email for a reset link."
- Password reset itself is completed via **web link** (mobile does not host the reset form in Phase 1).

### FR-00-006: Post-Login Bootstrap

Immediately after successful login, the app MUST fetch (in parallel):

1. `GET /me` — user profile, tenant meta, drawer/default accounts
2. `GET /me/permissions` — permission list
3. `GET /config` — tenant settings (currency, taxes, etc.)
4. `GET /inventories/default` — default inventory id

Cache all four responses in memory + disk. Show a splash/skeleton until all complete or 5s timeout elapses.

### FR-00-007: Session Expiry Handling

- Any `401` on a protected endpoint triggers logout flow: clear JWT, permissions, navigate to Login.
- Show non-blocking toast: "Your session expired. Please sign in again."

### FR-00-008: Subscription Blocked

- `402 Payment Required` → show full-screen banner: "Your subscription needs attention."
- If user has `billing.manage`, show button "Renew on Web" → deep link to `renewal_url`.
- Otherwise: "Please contact your administrator."

### FR-00-009: Logout

- Logout button in Profile / More menu.
- Confirmation dialog: "Are you sure?"
- POST `/logout` (fire-and-forget — still proceed locally if it fails).
- Wipe JWT, permissions, tenant slug (optional keep for convenience), caches, user state.
- Navigate to Login screen.

### FR-00-010: Language Selection

- Locale selector in Login (top-right) and Profile.
- Supported: `en`, `ar`.
- Default: device locale if supported, else `en`.
- Arabic triggers RTL layout.

---

## FR-01: Dashboard (Home)

### FR-01-001: Dashboard KPIs

Show cards from `GET /dashboard`:

- Total Revenue (today + period)
- Total Expenses
- Total Purchases
- Net Profit
- Total Balance (sum of account balances)

Each card shows value in tenant currency with a small delta vs previous period.

### FR-01-002: Period Filter

- Period selector at top: Today / Last 7 days / This Month / Custom Range.
- Default: Today.
- Refetch on change: `GET /dashboard/summary?month=YYYY-MM` or `?from=&to=`.

### FR-01-003: Sales Trend Chart

- `GET /dashboard/charts/sales-trend?period=day|week|month&from=&to=`.
- Render a line chart with X = date, Y = sales.
- Tap a data point → show exact amount + order count.

### FR-01-004: Top Products

- `GET /dashboard/charts/top-products?limit=5`.
- List with product name, quantity sold, revenue.

### FR-01-005: Low-Stock Alerts

- `GET /dashboard/lists/low-stock`.
- Max 5 shown on home; "View all" links to Low-Stock screen.
- Each row: product name, current qty, min threshold, "Adjust" icon (if `inventory.update`).

### FR-01-006: Recent Orders

- `GET /dashboard/lists/recent-orders`.
- Show 5 most recent POS / Sales orders.
- Tap → order detail.

### FR-01-007: Quick Actions

Owner/Manager: [New Sale] [Add Expense] [Record Payment] [New Client]
Cashier: [Open POS] [Close Shift]
Storekeeper: [Stock Transfer] [Adjust Stock]
Accountant: [Record Client Payment] [Add Expense]

Buttons only render if permission is held.

### FR-01-008: Pull-to-Refresh

All dashboard sections support pull-to-refresh.

---

## FR-02: POS

### FR-02-001: Shift Prerequisite

- Before accessing POS operations, the app MUST check `GET /pos/shift/current`.
- If no open shift and user has `shifts.create`: show Open Shift modal.
- If no open shift and user lacks `shifts.create`: show blocking message "A shift must be opened by a manager before you can sell."

### FR-02-002: Open Shift

Modal fields:

- Terminal (dropdown, from `GET /pos/terminals` or `GET /pos/shift/available-drawers`)
- Opening cash (decimal, required)
- Notes (optional)

POST `/pos/shift/open` with `{ terminal_id, opening_cash, note? }`.

On success, show "Shift open" banner with timer.

### FR-02-003: POS Product Browser

- `GET /pos/products?search=&branch_id=`.
- Grid or list view (user toggles).
- Show: product image, name, price, current stock.
- Out-of-stock products are dimmed and non-selectable (unless tenant allows negative stock — check `TenantConfig`).
- Tap adds to cart (qty +1) or opens variant picker if `has_variants`.

### FR-02-004: Barcode Scanner

- Scan button in POS top bar.
- Camera opens with barcode overlay.
- On decode, match against `GET /pos/products?search={barcode}` or local cache.
- Auto-add matched product to cart.
- No match → short error tone + toast: "No product found for barcode {code}".

### FR-02-005: Variant Picker

If `product.has_variants`:

- Show sheet with variant options (color, size, etc.).
- User selects combination → resolved `product_variant_id` added to cart.

### FR-02-006: Cart

Each cart line:

- Product name + variant label
- Unit price (editable if `pos.update_price` permission exists — otherwise read-only)
- Quantity (± buttons)
- Line total
- Remove (swipe or trash icon)

Cart totals:

- Subtotal
- Discount (type: percent/amount; input)
- Tax (auto from tenant default tax or selected)
- Shipping (optional, editable)
- Grand Total

### FR-02-007: Attach Client

- "Add Client" button at top of cart.
- Opens Client picker:
  - Search by phone (primary) or name
  - Quick-add button (opens New Client sheet)
- Cleared client goes back to "Walk-in customer".
- Requires `pos.clients` permission.

### FR-02-008: Payment

On "Charge" tap:

- Show Payment sheet.
- Display Grand Total.
- Payment method list (from `GET /pos/payment-methods`).
- If user has `pos.select_account`, show account picker per method.
- Cash: show tendered amount input → computed change.
- Card / Wallet / Other: single-amount input.
- Split payment: allow multiple method rows (each with amount).
- "Pay Later" (credit): sets `payment_status=due` — requires `sales.pay_credit`.

### FR-02-009: POS Order Submission

POST `/pos-orders` with full payload (items, client, discount, payment, inventory_id, shift_id implicit).

On success:

- Receipt sheet shows receipt number, items, total, payment summary.
- Actions: Print (Phase 3), Share (system share sheet), New Sale.

On validation error (422): highlight offending line/field with message.

On server error (5xx): show retry dialog. Do **not** retry automatically for POST.

### FR-02-010: POS Order History

- Tab "Orders" in POS.
- `GET /pos-orders?start_date=&end_date=&status=`.
- List with receipt no., client, grand total, payment status.
- Tap → detail + Reprint / Return actions.

### FR-02-011: POS Return

- From order detail, tap "Return".
- Show items with return-qty inputs (max = original qty − returned_qty).
- Reason field (required for audit).
- POST `/pos-orders/{id}/return`.
- Success shows return confirmation.

Requires `sales.return`.

### FR-02-012: Record Later Payment on POS Order

- For orders with `payment_status=due` or `partial`:
- "Collect Payment" button → opens payment sheet.
- POST `/pos-orders/{id}/payments` with `{amount, payment_method_id, account_id?, notes?}`.
- Requires `sales.pay_credit`.

### FR-02-013: Cash Movements

- Button "Cash In / Out" in POS tab.
- Modal: type (in/out), amount, reason, account, payment_method.
- POST `/pos/shift/cash-movements`.
- List of current-shift movements shown below the form.
- Allow reversal (POST `/pos/shift/cash-movements/{id}/reverse`) if `shifts.update`.

### FR-02-014: Close Shift

- Button "Close Shift" in POS or Profile menu.
- Show summary from `GET /pos/shift/summary`:
  - Total sales
  - Total cash collected
  - Expected cash = opening_cash + cash_in − cash_out + cash_sales
- User inputs actual cash count.
- Variance displayed in real time (green if matched, red if off).
- Variance notes field if variance ≠ 0.
- POST `/pos/shift/close` with `{ actual_cash, variance_notes? }`.

Requires `shifts.update`.

---

## FR-03: Clients

### FR-03-001: Clients List

- `GET /clients?page=&per_page=&search=&status=`.
- Search box (debounced 300ms).
- Filters: Has Due, Has Overdue, Status (Active/Blocked).
- List row: name, phone, outstanding balance, status badge.

### FR-03-002: Client Summary KPIs

Top cards (from `GET /clients/summary`):

- Total clients
- Clients with outstanding
- Total AR
- Total overdue

### FR-03-003: Quick Phone Search

- `GET /clients/by-phone?phone=...` — exact-match lookup used by POS.

### FR-03-004: Create Client

Fields:

- Name (required)
- Phone (required)
- Email (optional)
- Address (optional)
- Credit limit (optional, decimal)
- Status (default active)
- Notes (optional)

POST `/clients`.

Requires `clients.create` or `pos.clients`.

### FR-03-005: Client Profile

Shows tabs:

- **Overview** — contact info, balance, credit limit, status
- **Orders** (`GET /clients/{id}/orders`)
- **Due** (`GET /clients/{id}/due-orders`)
- **Payments** (`GET /clients/{id}/payments`)
- **Activity** (`GET /clients/{id}/activity`)
- **Statement** (`GET /clients/{id}/statement?from=&to=`)

Actions:

- Edit (PATCH `/clients/{id}`)
- Record Payment (POST `/clients/{id}/record-payment`)
- Block / Unblock (POST `/clients/{id}/block` / `/unblock`)
- Adjust Credit Limit (PATCH `/clients/{id}/credit`)

Action visibility gated by permissions.

### FR-03-006: Record Client Payment

Modal fields:

- Amount (required, decimal)
- Payment method (required)
- Account (optional, auto from method)
- Reference (optional)
- Notes (optional)

POST `/clients/{id}/record-payment` or `/client-payments`.

Requires `sales.collect_payment` OR `clients.update`.

---

## FR-04: Products & Inventory

### FR-04-001: Products List

- `GET /products?page=&per_page=&search=&category=&is_active=&has_variants=`.
- Grid/list toggle.
- Each item: image, name, SKU, selling price, current stock (across all user's inventories).

### FR-04-002: Product Detail

Shows:

- Image, name, SKU, barcode
- Cost price, selling price (visible per `products.view_cost` if applicable)
- Category, unit, tax
- Stock by inventory (list)
- Variants (if any)
- Transactions (`GET /products/{id}/transactions`)
- Financial info (`GET /products/{id}/financial-info`) — margin, total sold, total revenue

Actions:

- Edit (PATCH) — Phase 2
- Adjust Stock (POST `/stock-movements/{product_id}/adjust`) — Phase 2 for full version; Phase 1 allowed for storekeeper role

### FR-04-003: Inventories List

- `GET /inventories?search=&branch_id=`.
- Each row: name, branch, product count, total stock, low-stock count.

### FR-04-004: Inventory Detail

- Products in this inventory (`GET /inventories/{inventory}/products`).
- Transfer button (Phase 2).
- Adjust min-threshold per product (PATCH `/products/{product}/inventories/{inventory}/min-threshold`).

### FR-04-005: Stock Transfer (Phase 2)

- Source inventory, target inventory, items list (each with product + qty).
- POST `/inventories/transfer`.

Requires `inventory.update`.

### FR-04-006: Stock Adjustment (Phase 2)

- Product, qty change (+/−), reason, adjustment_type (in/out/damage/loss).
- POST `/stock-movements/{product_id}/adjust`.

---

## FR-05: Sales Invoices (Phase 2)

### FR-05-001: Sales Invoice List

`GET /sales-invoices?status=&client_id=&from_date=&to_date=&page=&per_page=`.

Filters: status (draft/posted/partially_paid/paid/overdue/cancelled), client, date range.

### FR-05-002: Create Sales Invoice

Fields:

- Client (required, searchable)
- Date (default today)
- Due date (default +30 days)
- Items (product, qty, unit_price, tax, discount)
- Discount type (percent/amount), value
- Overall tax
- Notes

POST `/sales-invoices`.

Requires `sales.create`.

### FR-05-003: Post Invoice

- Action on draft invoice.
- POST `/sales-invoices/{id}/post`.
- Requires `sales.approve`.
- Sets status → `posted` and affects client balance.

### FR-05-004: Record Payment on Invoice

- For posted/partially_paid invoices.
- POST `/sales-invoices/{id}/record-payment` with `{amount, payment_method_id, reference?, notes?}`.
- Requires `sales.pay_credit`.

### FR-05-005: Cancel Invoice

- POST `/sales-invoices/{id}/cancel` with `{reason}`.
- Requires `sales.delete`.

### FR-05-006: Print / Share

- GET `/sales-invoices/{id}/print` returns HTML/PDF.
- Open in in-app WebView; "Share as PDF" via system share.

---

## FR-06: Suppliers & Purchases (Phase 2)

### FR-06-001: Suppliers List

`GET /suppliers?search=&blacklisted=&rating=&page=&per_page=&sort_by=&sort_order=`.

### FR-06-002: Supplier Profile

Tabs:

- Overview
- Invoices (`GET /suppliers/{id}/invoices`)
- Returns (`GET /suppliers/{id}/returns`)
- Payments (`GET /suppliers/{id}/payments`)
- Ledger (`GET /suppliers/{id}/ledger?from=&to=`)
- Financial summary (`GET /suppliers/{id}/financial-summary`)

Actions:

- Create supplier (POST `/suppliers`)
- Edit (PATCH)
- Record Payment (POST `/supplier-payments`)

### FR-06-003: Purchase Invoices

- List (`GET /purchase-invoices`).
- Create (`POST /purchase-invoices`).
- Post / Cancel.
- Record Payment (`POST /purchase-invoices/{id}/payment`).
- Return (`POST /purchase-invoices/{id}/return`).

---

## FR-07: Expenses

### FR-07-001: Expenses List

`GET /expenses?category_id=&from_date=&to_date=&paid_via=&page=&per_page=`.

### FR-07-002: Add Expense

Fields:

- Category (required, from `GET /expense-categories`)
- Amount (required, decimal)
- Date (default today)
- Payment method (optional)
- Account (optional, auto from method)
- Description (optional)
- Notes (optional)
- Receipt image (optional, Phase 2)

POST `/expenses`.

Requires `expenses.create`.

### FR-07-003: Edit / Delete

- PATCH `/expenses/{id}` — `expenses.update`
- DELETE `/expenses/{id}` — `expenses.delete`

---

## FR-08: Accounts & Cash

### FR-08-001: Accounts List

`GET /accounts`.

Each row: name, type (cash/bank/wallet/credit_card/other), current_balance, default flag.

### FR-08-002: Account Detail

- Balance (`GET /accounts/{id}/balance`)
- History (`GET /accounts/{id}/history?from=&to=&type=`)
- Actions: Deposit, Withdraw, Transfer, Edit (if `accounts.update`)

### FR-08-003: Deposit / Withdraw

Fields: account, amount, reference, notes.

POST `/accounts/deposit` or `/accounts/withdraw`.

Requires `accounts.create`.

### FR-08-004: Transfer

Fields: from_account, to_account, amount, reference, notes.

POST `/accounts/transfer`.

Requires `accounts.create`.

### FR-08-005: Account Adjustments

Fields: account, adjustment_amount (signed), reason, notes.

POST `/account-adjustments`.

Requires `accounts.adjust`.

---

## FR-09: Profile & Self-Service

### FR-09-001: View Profile

`GET /profile` or `/me`.

Show: avatar, name, email, phone, role, assigned inventories.

### FR-09-002: Edit Profile

PATCH `/profile` with `{name, email, phone}`.

### FR-09-003: Change Avatar

POST `/profile/avatar` (multipart).

### FR-09-004: Change Password

Form: current_password, new_password, new_password_confirmation.

PUT `/profile/password`.

### FR-09-005: Language Toggle

Local preference (stored in prefs) + optional persist via `PUT /settings/languages` if admin.

---

## FR-10: Reports (Phase 3)

### FR-10-001: Reports Hub

Mobile-optimized subset:

- Daily Sales (`GET /reports/daily-sales`)
- Monthly Sales (`GET /reports/monthly-sales`)
- Cash vs Credit (`GET /reports/cash-credit`)
- Outstanding Invoices (`GET /reports/outstanding-invoices`)
- Product Sales (`GET /reports/product-sales`)
- Product Profit (`GET /reports/product-profit`)
- AR Aging (`GET /reports/ar-aging`)
- AP Aging (`GET /reports/ap-aging`)
- POS Shift Variance (`GET /reports/pos-shift-variance`)

Each report supports:

- Date-range filter
- Table view
- Simple chart view (line or bar)
- Export hand-off to email (Phase 3+)

Requires `reports.view`.

---

## FR-11: Notifications (Phase 2)

### FR-11-001: Device Registration

On first login, request notification permission and register FCM/APNs token.

POST to (endpoint to be added backend-side, see `15-delivery-phases.md`):

`/api/v1/{tenant_slug}/devices/register` with `{token, platform, device_name, app_version}`.

### FR-11-002: Notification Types

- **Low stock** (product dropped below min)
- **Overdue AR** (new invoice became overdue)
- **Overdue AP** (supplier payment due today)
- **Shift variance** (cashier closed with variance > threshold)
- **Approval requested** (Phase 3)
- **Subscription warning** (trial ending, payment failed)

### FR-11-003: Notification Tap Deep Linking

Each notification carries a deep-link path (e.g., `operix://clients/42/due-orders`). Tapping navigates directly to that screen.

### FR-11-004: In-App Notification Center

Screen listing recent notifications (pulled from a future `/notifications` endpoint or local cache).

---

## FR-12: Settings (Read-Only in Phase 1)

Mobile surfaces the following settings (read-only unless noted):

- Company (`GET /settings/company`) — read only
- Currencies (`GET /settings/currencies`)
- Taxes (`GET /settings/taxes`)
- Payment methods (`GET /settings/payment-methods`)
- Units (`GET /settings/units`)
- Receipt (`GET /settings/receipt`) — Phase 3: edit

Full settings edit remains web-only until Phase 3.

---

## Cross-Cutting Functional Requirements

### FR-XC-001: Pull-to-Refresh

Every list screen MUST support pull-to-refresh.

### FR-XC-002: Infinite Scroll

Every paginated list MUST load the next page when the user scrolls near the bottom. Threshold: 200px from end.

### FR-XC-003: Empty States

Every list with 0 results MUST show an illustrated empty state with a primary call-to-action (if permission allows).

### FR-XC-004: Loading Skeletons

Every screen with async data MUST show a skeleton placeholder during initial load — never a blank screen.

### FR-XC-005: Optimistic UI (limited)

For cart modifications in POS, use optimistic updates. For all other mutations (orders, payments, clients), wait for server response.

### FR-XC-006: Confirmation for Destructive Actions

Delete, Void, Cancel, Block — all require explicit confirmation dialog.

### FR-XC-007: Haptic Feedback

- Successful POS submit → success haptic
- Barcode scan hit → light haptic
- Error → error haptic

### FR-XC-008: Back Navigation

Unsaved changes in a form → confirm dialog "Discard changes?" before navigating back.

### FR-XC-009: Deep Links

Support the scheme `operix://` and universal links for:

- `operix://clients/{id}`
- `operix://products/{id}`
- `operix://pos-orders/{id}`
- `operix://sales-invoices/{id}`

### FR-XC-010: Search Debouncing

All search inputs debounce 300ms before firing API call.

### FR-XC-011: Currency & Date Formatting

- Use tenant `currency_code` and `locale` for all monetary/date display.
- Arabic locale uses Arabic numerals (`٠١٢٣...`) when tenant config requests it (check `TenantConfig.feature_flags_json.arabic_numerals`).
- Date format per locale: `en` → `MMM d, yyyy`; `ar` → `d MMM yyyy` (or tenant override).
