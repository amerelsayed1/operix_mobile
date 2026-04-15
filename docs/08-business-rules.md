# 08 — Business Rules, Validation & State Machines

This document captures the business rules and state transitions that the mobile app must enforce on the client side (for immediate UX feedback) and expect from the server (authoritative).

## 8.1 Money & Precision

- All monetary values are stored and transmitted as `decimal(15,2)` strings.
- Mobile MUST use arbitrary-precision arithmetic for display calculations (no `double`).
- Rounding: banker's rounding (`HALF_EVEN`) is used by backend for tax calculations. Client-side previews should match.
- Exchange rates use `decimal(12,6)`.

## 8.2 POS Order Calculations

Server is authoritative. Client-side preview uses:

```
subtotal         = Σ (item.quantity × item.unit_price)
discount_total   =
    discount_type == 'percent' ? subtotal × (discount_value / 100)
                               : discount_value
taxable_base     = subtotal − discount_total
tax_total        = taxable_base × (tax_rate / 100)              [tax_mode = exclusive]
                 = taxable_base × (tax_rate / (100 + tax_rate)) [tax_mode = inclusive]
grand_total      = subtotal − discount_total + tax_total + shipping_cost
change_amount    = max(0, paid_amount − grand_total)
due_amount       = max(0, grand_total − paid_amount)
payment_status   = due_amount == 0       ? 'paid'
                 : paid_amount == 0      ? 'due'
                                         : 'partial'
```

### Client-side rules

- **R-POS-001:** If `client_id` is not set and `paid_amount < grand_total`, block submit unless user has `sales.pay_credit`.
- **R-POS-002:** `discount_value` cannot exceed subtotal.
- **R-POS-003:** Discount that exceeds the user's discount ceiling (future: `pos.max_discount_percent`) triggers approval — Phase 3.
- **R-POS-004:** Items with `current_stock < quantity` show a warning. Submit allowed only if tenant config `allow_negative_stock=true`; otherwise blocked.
- **R-POS-005:** Each order MUST belong to an open shift (`shift_id`). Client enforces by reading `/pos/shift/current` before allowing submit.

## 8.3 Sales Invoice Calculations

```
line_total    = quantity × unit_price × (1 − discount_rate/100) × (1 + tax_rate/100 if exclusive)
subtotal      = Σ line_totals (pre-tax)
discount_total= Σ line discounts  +  invoice-level discount
tax_total     = Σ line taxes      +  invoice-level tax
total_amount  = subtotal − discount_total + tax_total
balance_due   = total_amount − paid_amount
```

### Invoice rules

- **R-SI-001:** `due_date` must be ≥ `date`.
- **R-SI-002:** A draft invoice does **NOT** affect client balance.
- **R-SI-003:** Posting an invoice increments client balance by `total_amount`.
- **R-SI-004:** Posted invoices cannot be edited; they must be cancelled and re-created.
- **R-SI-005:** Recording a payment decrements client balance; overpayment is capped at `balance_due`.
- **R-SI-006:** Cancelling a posted invoice reverses the balance impact for unpaid portion.

## 8.4 Sales Invoice State Machine

```
         ┌────── post ──────► posted ─── record_payment ───►  partially_paid
draft ───┤                     │                                 │
         │                     │ record_payment (full)           │ record_payment (full)
         │                     ▼                                 ▼
         │                   paid ◄─────────────────────────── paid
         │
         └── delete ─► (hard)   │ cancel
                                ▼
                              cancelled
```

Overdue is a **derived** status: `posted` or `partially_paid` with `due_date < today` and `balance_due > 0`.

## 8.5 Supplier Invoice State Machine

```
draft ── post ──► posted ── payment ──► partial ── payment ──► paid
  │                  │          │                      │
  │                  │          └── return ──► cancelled (if fully returned)
  │                  │
  └── delete         └── cancel ──► cancelled
```

### Rules

- **R-SUP-001:** Posting increases supplier `payable_balance` by `amount`.
- **R-SUP-002:** Posting also creates inbound stock movements for each item (only if `posted_at` unset).
- **R-SUP-003:** Payment decreases `payable_balance` by `amount`.
- **R-SUP-004:** Return decreases stock and `payable_balance`; if fully returned, invoice becomes cancelled.

## 8.6 Shift State Machine

```
(none) ── open_shift ──► open ── close_shift ──► closed
                           │
                           ├── cash_movement_in  ──┐
                           ├── cash_movement_out ─┤
                           └── reverse_movement  ─┘   (self-loop)
```

### Rules

- **R-SHIFT-001:** Only one `open` shift per terminal at a time.
- **R-SHIFT-002:** `expected_cash = opening_cash + cash_in − cash_out + cash_sales`.
- **R-SHIFT-003:** `variance = counted_cash − expected_cash` (signed).
- **R-SHIFT-004:** If `|variance| > 0`, `variance_notes` is required.
- **R-SHIFT-005:** Once closed, a shift cannot be reopened. POS orders referencing that shift cannot be created (must open new shift).
- **R-SHIFT-006:** Cash movements must be non-zero positive amounts. Reversal records a signed counter-entry and marks the original `reversed_at`.

## 8.7 POS Return Rules

- **R-RET-001:** `quantity_returned ≤ quantity − returned_quantity` per line.
- **R-RET-002:** Returns create reverse stock movements.
- **R-RET-003:** Refund method choice:
  - `cash_refund` immediate from the shift drawer
  - `credit_refund` onto client's account (increases their credit, decreases their balance)
- **R-RET-004:** If the original PosOrder had no client, `credit_refund` is not allowed.

## 8.8 Sales Return Approval

- **R-SR-001:** Status transitions: `pending` → `approved` (by `sales.approve`) or `rejected` (by `sales.approve`).
- **R-SR-002:** Rejected returns do not affect stock or balances.
- **R-SR-003:** Approved returns trigger stock reversal and AR balance adjustment.

## 8.9 Client Credit Rules

- **R-CLI-001:** `balance` tracks outstanding AR. Positive = client owes the tenant.
- **R-CLI-002:** Credit sale allowed only if `balance + new_due ≤ credit_limit` (or if `credit_limit == 0` meaning unlimited).
- **R-CLI-003:** Blocked clients (`blocked_at` set) cannot be attached to new POS orders or sales invoices.
- **R-CLI-004:** Deleting a client with outstanding balance > 0 is disallowed by backend. Mobile must prevent the attempt.

## 8.10 Stock Rules

- **R-STK-001:** Stock is per `InventoryProduct` row (product × inventory). Variants use `InventoryProductVariant`.
- **R-STK-002:** Selling reduces stock at the order's `inventory_id`.
- **R-STK-003:** Purchasing increases stock at the invoice's `inventory_id`.
- **R-STK-004:** Transfers are a pair of atomic movements — one `out` at source, one `in` at destination.
- **R-STK-005:** Adjustments require a `reason` and `adjustment_type` (`in` / `out` / `damage` / `loss`).
- **R-STK-006:** Negative stock is controlled by feature flag `allow_negative_stock`. Default **false**.

## 8.11 Account Rules

- **R-ACC-001:** `current_balance` changes only via deposit, withdrawal, transfer, adjustment, POS payment in/out, expense, supplier payment, client payment.
- **R-ACC-002:** Transfer atomically decrements source and increments destination.
- **R-ACC-003:** `opening_balance` updates create a compensating adjustment entry.
- **R-ACC-004:** Drawer accounts (`is_drawer=true`) can only be modified via shift cash movements, not direct deposits/withdrawals.

## 8.12 Tax Modes

Tenant-level setting (`tax_mode`):

- **Exclusive** — displayed prices exclude tax; tax is added at checkout.
- **Inclusive** — displayed prices include tax; tax is extracted at checkout.

Applies to POS and Sales Invoice total calculations.

## 8.13 Discount Rules

- **R-DIS-001:** Discount is never negative.
- **R-DIS-002:** Line-level discount is applied before line tax.
- **R-DIS-003:** Invoice-level discount is applied to the sum of line subtotals before invoice-level tax.

## 8.14 Numbering Rules

Numbering formats (from `InvoiceConfig` / tenant settings):

- Receipt: `RCP-YYYYMMDD-####` (generated by POS)
- Sales invoice: `{prefix}{counter}` (e.g., `INV-000123`)
- Purchase invoice: tenant-supplied or `PUR-{counter}`
- Client payment: `PAY-CLI-{counter}`
- Supplier payment: `PAY-SUP-{counter}`
- Sales return: `SR-{counter}`

Mobile displays whatever the server returns. Never generate numbers client-side.

## 8.15 Validation Rules (form-level)

### Client form

| Field | Rule |
|-------|------|
| name | required, 1-200 chars |
| phone | required, valid phone |
| email | optional, email format |
| credit_limit | optional, ≥ 0 |

### Product form

| Field | Rule |
|-------|------|
| name | required |
| sku | required, unique (server-side) |
| selling_price | required, > 0 |
| cost_price | required, ≥ 0 |
| minimum_stock_alert | ≥ 0 |

### Expense form

| Field | Rule |
|-------|------|
| category_id | required |
| amount | required, > 0 |
| date | required, ≤ today |

### Account operation

| Field | Rule |
|-------|------|
| amount | required, > 0 |
| from_account / to_account | must differ (transfer) |

### POS order

| Field | Rule |
|-------|------|
| items | min 1 |
| items[].quantity | required, > 0 |
| items[].unit_price | required, ≥ 0 |
| discount_value | optional, ≥ 0; percent ≤ 100 |
| paid_amount | required, ≥ 0 |

## 8.16 Permission Edge Cases

- **R-PRM-001:** `pos.view` implies read access to `/pos/products`, `/pos/taxes`, `/pos/payment-methods`, `/pos/accounts`. Do not block these in UI if `pos.view` is present.
- **R-PRM-002:** `pos.clients` is a **delegated** permission — it grants client CRUD **only in the POS context**. Standalone client management still needs `clients.view` etc.
- **R-PRM-003:** Some routes accept a pipe list (`clients.view|pos.clients`). Mobile MUST treat these as OR.
- **R-PRM-004:** Admin roles bypass — mobile receives `["*"]` and MUST treat every `has()` as true.

## 8.17 Multi-Tenancy Invariants

- **R-TEN-001:** JWT bound to one tenant. Cross-tenant calls return 404 or 403.
- **R-TEN-002:** App never stores more than one active tenant session.
- **R-TEN-003:** On tenant switch, all cached data is wiped.

## 8.18 Receipt Display Rules

- Show tenant logo and business name.
- Show receipt_number prominently.
- Show cashier name and timestamp in tenant timezone.
- Show line items with qty × unit_price = line_total.
- Show subtotal, discount_total (negative), tax_total, shipping, grand_total.
- Show payment method(s) and amount(s).
- Show change (for cash).
- Footer text comes from `GET /settings/receipt.footer_text`.

## 8.19 Offline Behavior Rules

- **R-OFF-001 (Phase 1):** No offline writes. Show connection error, preserve draft form data locally.
- **R-OFF-002:** Read-cached lists (products, clients) display with a "Last updated: XX ago" banner when offline.
- **R-OFF-003:** On reconnect, list screens auto-refresh.

## 8.20 Localization Rules

- **R-I18N-001:** Every user-visible string must be in the i18n file (no hardcoded English/Arabic).
- **R-I18N-002:** Currency amounts always follow the tenant's `currency_code`.
- **R-I18N-003:** RTL layout MUST mirror chevrons, padding, and scroll direction.
- **R-I18N-004:** Dates use intl formatting (not string concatenation).

## 8.21 Audit Trail Requirements

The following actions MUST emit an audit log entry server-side (mobile just invokes the API):

- Login / Logout
- POS order create / delete
- Shift open / close
- Invoice post / cancel
- Payment record
- Client block / unblock
- Credit limit change
- Account adjustment
- Stock adjustment

Mobile does not write audit logs directly — it consumes `GET /audit-logs` (Phase 3) for display.
