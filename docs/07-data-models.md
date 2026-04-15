# 07 — Data Models

This document lists the domain entities the mobile app must represent, their fields, and relationships. Every mobile entity is a **projection** of a backend Eloquent model — the canonical source of truth is `business_finance_manager_api/app/Models/`.

## Conventions

- `decimal(p,s)` — fixed-point decimal. Mobile MUST use a high-precision numeric type (e.g., `Decimal`, `BigDecimal`) or libraries like `decimal.dart` / `big.js`. **Never** use floating-point for money.
- `datetime` — ISO-8601 string from server (e.g., `2026-04-13T10:30:00+00:00`). Display in tenant timezone.
- `date` — `YYYY-MM-DD` string.
- All IDs are `int64`.
- `tenant_id` is implicit on every tenant-scoped entity — the mobile app does NOT send it.

## Base Response Types

```ts
type ApiEnvelope<T> =
  | T                                  // plain
  | { success: boolean; data: T; message?: string }; // wrapped

type Paginated<T> = {
  data: T[];
  meta: { current_page: number; last_page: number; per_page: number; total: number };
  links?: { first?: string; last?: string; prev?: string | null; next?: string | null };
};
```

---

## User

| Field | Type | Notes |
|-------|------|-------|
| id | int | |
| name | string | |
| email | string | |
| phone | string? | |
| avatar_url | string? | |
| role_id | int | |
| role | Role | |
| tenant_id | int | |
| tenant | Tenant | (on `/me` only) |
| drawer_account | Account? | cashier's register |
| default_account | Account? | |
| inventories | Inventory[] | assigned inventories |
| is_active | bool | |
| last_login_at | datetime? | |

## Role

| Field | Type |
|-------|------|
| id | int |
| name | string |
| slug | string |
| is_admin | bool |
| permissions | string[] | (when expanded) |

## Permission

Just a string `module.action`. No separate entity on mobile.

## Tenant

| Field | Type | Notes |
|-------|------|-------|
| id | int | |
| name | string | |
| slug | string | URL-safe |
| business_name | string? | |
| logo_url | string? | |
| theme_primary_color | string? | hex `#RRGGBB` |
| locale | string | `en` \| `ar` |
| currency_code | string | ISO 4217 |
| timezone | string | IANA |
| status | string | `trial` \| `active` \| `suspended` \| `pending_email_verification` |
| trial_ends_at | datetime? | |
| grace_ends_at | datetime? | |

## TenantConfig

Holds feature flags and settings.

| Field | Type |
|-------|------|
| theme | object |
| sales_invoice_settings | object |
| feature_flags | object | `{allow_negative_stock, pos_enabled, ...}` |
| tax_settings | object | `{default_tax_id, tax_mode: 'inclusive'\|'exclusive'}` |

---

## Account

| Field | Type | Notes |
|-------|------|-------|
| id | int | |
| name | string | |
| type | string | `cash` \| `bank` \| `wallet` \| `credit_card` \| `other` |
| opening_balance | decimal(15,2) | |
| current_balance | decimal(15,2) | |
| is_default | bool | |
| is_drawer | bool | linked to a POS terminal |
| shift_closing_visibility | string | `hidden` \| `global` \| `permission` |
| gl_account_id | int? | |

## AccountTransfer

| Field | Type |
|-------|------|
| id | int |
| from_account | Account |
| to_account | Account |
| amount | decimal(15,2) |
| transfer_date | date |
| reference | string? |
| notes | string? |

## AccountAdjustment

| Field | Type |
|-------|------|
| id | int |
| account_id | int |
| previous_balance | decimal(15,2) |
| adjustment_amount | decimal(15,2) | signed |
| new_balance | decimal(15,2) |
| reason | string |
| notes | string? |
| created_by | User (id+name) |
| created_at | datetime |

---

## Branch

| Field | Type |
|-------|------|
| id | int |
| name | string |
| name_ar | string? |
| address | string? |
| city | string? |
| phone | string? |
| email | string? |
| is_default | bool |
| is_active | bool |

## PosTerminal

| Field | Type |
|-------|------|
| id | int |
| name | string |
| code | string |
| branch_id | int |
| drawer_account_id | int? |
| is_active | bool |
| slot_number | int |

---

## Product

| Field | Type | Notes |
|-------|------|-------|
| id | int | |
| name | string | |
| sku | string | unique per tenant |
| barcode | string? | |
| barcode_type | string? | EAN13, UPC, etc. |
| product_category_id | int? | |
| category | ProductCategory? | |
| unit_id | int? | |
| unit | Unit? | |
| tax_id | int? | |
| tax | Tax? | |
| cost_price | decimal(15,2) | |
| selling_price | decimal(15,2) | |
| minimum_stock_alert | int | |
| image_url | string? | |
| has_variants | bool | |
| is_active | bool | |
| variants | ProductVariant[] | when expanded |
| current_stock | decimal(10,2) | computed across user's inventories |

## ProductVariant

| Field | Type |
|-------|------|
| id | int |
| product_id | int |
| sku | string |
| barcode | string? |
| cost_price | decimal(15,2) |
| selling_price | decimal(15,2) |
| combination_hash | string |
| label | string | human-readable, e.g., "Black / M" |
| total_stock | decimal(10,2) |
| options | VariantOption[] |

## VariantOption

| Field | Type |
|-------|------|
| attribute_name | string |
| value | string |

## ProductCategory

| Field | Type |
|-------|------|
| id | int |
| name | string |
| name_ar | string? |
| tax_id | int? |

## Unit

| Field | Type |
|-------|------|
| id | int |
| name | string |
| name_ar | string? |
| short_code | string |

## Tax

| Field | Type |
|-------|------|
| id | int |
| name | string |
| rate | decimal(5,2) | percentage |
| type | string | `percentage` \| `fixed` |
| status | string |

---

## Inventory

| Field | Type |
|-------|------|
| id | int |
| name | string |
| branch_id | int? |
| location | string? |
| is_default | bool |
| product_count | int |
| total_stock | decimal(12,2) |
| low_stock_count | int |

## InventoryProduct

| Field | Type |
|-------|------|
| id | int |
| inventory_id | int |
| product_id | int |
| quantity | decimal(10,2) |
| min_threshold | decimal(10,2) |
| is_low_stock | bool (computed) |
| stock_status | string | `out_of_stock` \| `low_stock` \| `in_stock` |

## StockMovement

| Field | Type |
|-------|------|
| id | int |
| product_id | int |
| product_variant_id | int? |
| inventory_id | int |
| type | string | `in` \| `out` \| `adjustment` |
| quantity | decimal(10,2) |
| date | date |
| reference_type | string? | `SupplierInvoice` \| `PosOrder` \| `SalesInvoice` \| `SalesReturn` |
| reference_id | int? |
| note | string? |

---

## Client

| Field | Type | Notes |
|-------|------|-------|
| id | int | |
| name | string | |
| phone | string | |
| email | string? | |
| address | string? | |
| balance | decimal(15,2) | outstanding AR |
| credit_limit | decimal(15,2) | |
| status | string | `active` \| `inactive` |
| blocked_at | datetime? | |
| blocked_reason | string? | |
| is_tax_exempt | bool | |
| tax_exempt_reason | string? | |
| overdue_days_threshold | int | |
| inactive_after_days | int | |
| total_orders | int (computed) | |
| total_due | decimal(15,2) (computed) | |
| total_revenue | decimal(15,2) (computed) | |
| last_order_date | date? (computed) | |

## ClientPayment

| Field | Type |
|-------|------|
| id | int |
| reference | string | `PAY-CLI-*` |
| client_id | int |
| amount | decimal(15,2) |
| payment_date | date |
| payment_method | string | `cash` \| `bank_transfer` \| `check` \| `credit_card` \| `other` |
| payment_method_id | int? |
| account_id | int? |
| pos_order_id | int? |
| check_number | string? |
| check_date | date? |
| notes | string? |

---

## Supplier

| Field | Type |
|-------|------|
| id | int |
| supplier_code | string | auto `SUP-*` |
| company_name | string |
| contact_person | string? |
| email | string? |
| phone | string? |
| mobile | string? |
| website | string? |
| tax_id | string? |
| opening_balance | decimal(15,2) |
| payable_balance | decimal(15,2) |
| credit_limit | decimal(15,2) |
| payment_terms | int | days |
| rating | int | 1-5 |
| blacklisted | bool |
| blacklist_reason | string? |
| status | string |
| address | string? |
| city | string? |
| country | string? |
| contacts | SupplierContact[] |
| addresses | SupplierAddress[] |
| bank_accounts | SupplierBankAccount[] |

## SupplierContact

| Field | Type |
|-------|------|
| id | int |
| name | string |
| role | string? |
| phone | string? |
| email | string? |
| whatsapp | string? |
| is_primary | bool |

## SupplierAddress

| Field | Type |
|-------|------|
| id | int |
| type | string |
| country | string? |
| city | string? |
| area | string? |
| street | string? |
| building | string? |
| zip | string? |
| is_default | bool |

## SupplierBankAccount

| Field | Type |
|-------|------|
| id | int |
| bank_name | string |
| account_name | string |
| account_number | string |
| iban | string? |
| swift | string? |
| currency | string? |
| is_default | bool |

## SupplierInvoice

| Field | Type |
|-------|------|
| id | int |
| supplier_id | int |
| invoice_number | string |
| date | date |
| due_date | date? |
| status | string | `draft` \| `posted` \| `partial` \| `paid` \| `cancelled` |
| amount | decimal(15,2) |
| tax_amount | decimal(15,2) |
| paid_amount | decimal(15,2) |
| due_amount | decimal(15,2) (computed) |
| supplier_memo | string? |
| items | SupplierInvoiceItem[] |

## SupplierInvoiceItem

| Field | Type |
|-------|------|
| id | int |
| product_id | int? |
| product_variant_id | int? |
| description | string? |
| quantity | decimal(10,2) |
| purchase_price | decimal(15,2) |
| selling_price | decimal(15,2) |
| tax_percentage | decimal(5,2) |
| tax_amount | decimal(15,2) |
| total_amount | decimal(15,2) |

## SupplierPayment

| Field | Type |
|-------|------|
| id | int |
| reference | string | `PAY-SUP-*` |
| supplier_id | int |
| supplier_invoice_id | int? |
| amount | decimal(15,2) |
| payment_date | date |
| payment_method | string |
| account_id | int? |
| attachment_url | string? |
| notes | string? |

## SupplierReturn

| Field | Type |
|-------|------|
| id | int |
| reference_number | string |
| supplier_id | int |
| supplier_invoice_id | int |
| date | date |
| status | string |
| amount | decimal(15,2) |
| tax_amount | decimal(15,2) |
| reason | string? |
| items | SupplierReturnItem[] |

## SupplierReturnItem

| Field | Type |
|-------|------|
| id | int |
| product_id | int |
| description | string? |
| quantity | decimal(10,2) |
| price | decimal(15,2) |
| tax_amount | decimal(15,2) |
| total | decimal(15,2) |

---

## SalesInvoice

| Field | Type |
|-------|------|
| id | int |
| invoice_number | string |
| client_id | int |
| user_id | int |
| inventory_id | int? |
| tax_id | int? |
| date | date |
| due_date | date |
| status | string | `draft` \| `posted` \| `partially_paid` \| `paid` \| `overdue` \| `cancelled` |
| subtotal | decimal(15,2) |
| discount_total | decimal(15,2) |
| tax_total | decimal(15,2) |
| total_amount | decimal(15,2) |
| paid_amount | decimal(15,2) |
| balance_due | decimal(15,2) (computed) |
| posted_at | datetime? |
| items | SalesInvoiceItem[] |
| payments | SalesInvoicePayment[] |

## SalesInvoiceItem

| Field | Type |
|-------|------|
| id | int |
| product_id | int |
| product_variant_id | int? |
| description | string? |
| quantity | decimal(10,2) |
| unit_price | decimal(15,2) |
| unit_cost | decimal(15,2) |
| tax_rate | decimal(5,2) |
| discount_rate | decimal(5,2) |
| line_total | decimal(15,2) |
| returned_quantity | decimal(10,2) |

## SalesInvoicePayment

| Field | Type |
|-------|------|
| id | int |
| reference | string | `PAY-*` |
| sales_invoice_id | int |
| payment_method_id | int? |
| account_id | int? |
| amount | decimal(15,2) |
| payment_date | date |
| currency_code | string |
| exchange_rate | decimal(12,6) |
| notes | string? |

## SalesReturn

| Field | Type |
|-------|------|
| id | int |
| pos_order_id | int? |
| sales_invoice_id | int? |
| client_id | int? |
| inventory_id | int? |
| account_id | int? |
| user_id | int |
| return_date | date |
| total_amount | decimal(15,2) |
| refund_amount | decimal(15,2) |
| cash_refund | decimal(15,2) |
| credit_refund | decimal(15,2) |
| reason | string? |
| status | string | `pending` \| `approved` \| `rejected` |
| approved_by | int? |
| approved_at | datetime? |
| rejected_by | int? |
| rejected_at | datetime? |
| approval_notes | string? |
| items | SalesReturnItem[] |

## SalesReturnItem

| Field | Type |
|-------|------|
| id | int |
| product_id | int |
| product_name | string (appended) |
| product_sku | string (appended) |
| quantity | decimal(10,2) |
| unit_price | decimal(15,2) |
| cost_price | decimal(15,2) |
| total_line_amount | decimal(15,2) |

---

## PosOrder

| Field | Type |
|-------|------|
| id | int |
| receipt_number | string | `RCP-YYYYMMDD-XXXX` |
| user_id | int |
| shift_id | int? |
| account_id | int? |
| client_id | int? |
| inventory_id | int |
| client_name | string? |
| client_phone | string? |
| date | date |
| subtotal | decimal(15,2) |
| discount_value | decimal(15,2) |
| discount_type | string | `percent` \| `amount` |
| discount_total | decimal(15,2) |
| tax_rate | decimal(5,2) |
| tax_total | decimal(15,2) |
| shipping_cost | decimal(15,2) |
| grand_total | decimal(15,2) |
| paid_amount | decimal(15,2) |
| change_amount | decimal(15,2) |
| due_amount | decimal(15,2) |
| payment_method | string? |
| payment_status | string | `paid` \| `partial` \| `due` |
| status | string |
| channel | string | `pos` \| `shopify` \| ... |
| note | string? |
| items | PosOrderItem[] |

## PosOrderItem

| Field | Type |
|-------|------|
| id | int |
| product_id | int |
| product_variant_id | int? |
| product_name | string (snapshot) |
| product_sku | string (snapshot) |
| variant_label | string? (snapshot) |
| quantity | decimal(10,2) |
| returned_quantity | decimal(10,2) |
| unit_price | decimal(15,2) |
| cost_price | decimal(15,2) |
| discount | decimal(15,2) |
| tax | decimal(15,2) |
| line_total | decimal(15,2) |

---

## Shift

| Field | Type |
|-------|------|
| id | int |
| terminal_id | int |
| terminal | PosTerminal |
| drawer_account_id | int |
| drawer | Account |
| opened_by | User |
| closed_by | User? |
| opened_at | datetime |
| closed_at | datetime? |
| status | string | `open` \| `closed` |
| opening_cash | decimal(15,2) |
| expected_cash | decimal(15,2) |
| counted_cash | decimal(15,2)? |
| variance | decimal(15,2)? |
| notes | string? |

## ShiftCashMovement

| Field | Type |
|-------|------|
| id | int |
| shift_id | int |
| type | string | `in` \| `out` |
| amount | decimal(15,2) |
| reason | string |
| account_id | int? |
| payment_method_id | int? |
| created_by | User |
| created_at | datetime |
| reversed_at | datetime? |
| reversed_by | User? |
| reversal_of_movement_id | int? |

---

## Expense

| Field | Type |
|-------|------|
| id | int |
| account_id | int? |
| category_id | int |
| category | ExpenseCategory |
| shift_id | int? |
| user_id | int |
| amount | decimal(15,2) |
| date | date |
| description | string? |
| note | string? (alias of description) |
| is_ads | bool |

## ExpenseCategory

| Field | Type |
|-------|------|
| id | int |
| name | string |
| name_ar | string? |
| is_default | bool |

---

## Subscription & Plan (display-only on mobile)

| Field | Type |
|-------|------|
| id | int |
| plan_id | int |
| plan_name | string |
| status | string | `trial` \| `active` \| `past_due` \| `grace_period` \| `suspended` \| `cancelled` \| `expired` |
| starts_at | datetime |
| ends_at | datetime? |
| trial_ends_at | datetime? |
| grace_ends_at | datetime? |
| cancel_at_period_end | bool |
| gateway | string | `stripe` \| `paymob` \| `lemonsqueezy` \| `manual` |
| days_left | int (computed) |

---

## PaymentMethod

| Field | Type |
|-------|------|
| id | int |
| name_en | string |
| name_ar | string? |
| slug | string |
| type | string | `cash` \| `bank` \| `card` \| `wallet` \| `other` |
| is_active | bool |
| accounts | Account[] | many-to-many with default flag |

## Currency

| Field | Type |
|-------|------|
| id | int |
| code | string | ISO 4217 |
| name | string |
| symbol | string |
| exchange_rate | decimal(12,6) |
| is_default | bool |

---

## AuditLog (Phase 3)

| Field | Type |
|-------|------|
| id | int |
| action | string |
| status | string |
| message | string? |
| actor_type | string |
| actor_id | int |
| target_type | string? |
| target_id | int? |
| entity_type | string? |
| entity_id | int? |
| ip_address | string? |
| user_agent | string? |
| meta | object |
| created_at | datetime |

---

## Enums Reference

```ts
enum AccountType { Cash, Bank, Wallet, CreditCard, Other }
enum PaymentStatus { Paid, Partial, Due }
enum PosOrderStatus { Paid, Partial, Due }
enum SalesInvoiceStatus { Draft, Posted, PartiallyPaid, Paid, Overdue, Cancelled }
enum SupplierInvoiceStatus { Draft, Posted, Partial, Paid, Cancelled }
enum SalesReturnStatus { Pending, Approved, Rejected }
enum ShiftStatus { Open, Closed }
enum SubscriptionStatus { Trial, Active, PastDue, GracePeriod, Suspended, Cancelled, Expired }
enum BillingGateway { Stripe, Paymob, LemonSqueezy, Manual }
enum TransactionStatus { Success, Failed, Refunded }
```
