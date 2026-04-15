# 16 — Appendices

## Appendix A — Complete Permission List

Below is the complete permission catalogue the backend may return. Mobile must gracefully handle permissions not listed here (treat as unknown, no effect).

```
dashboard.view

pos.view
pos.create
pos.update
pos.delete
pos.clients
pos.select_account

shifts.view
shifts.create
shifts.update

sales.view
sales.create
sales.update
sales.delete
sales.approve
sales.return
sales.collect_payment
sales.pay_credit

clients.view
clients.create
clients.update
clients.edit         (alias of clients.update)
clients.delete

products.view
products.create
products.update
products.edit        (alias of products.update)
products.delete
products.import
products.print_barcodes

inventory.view
inventory.create
inventory.update
inventory.edit       (alias of inventory.update)
inventory.delete

suppliers.view
suppliers.create
suppliers.update
suppliers.delete

purchases.view
purchases.create
purchases.update
purchases.delete

expenses.view
expenses.create
expenses.update
expenses.delete

accounts.view
accounts.create
accounts.update
accounts.edit        (alias)
accounts.delete
accounts.adjust

employees.view
employees.create
employees.update
employees.edit       (alias)
employees.delete

roles.view
roles.create
roles.update
roles.delete

reports.view

settings.view
settings.edit
settings.update      (alias)

company.view
company.update

billing.view
billing.manage

branches.view
branches.create
branches.update
branches.delete

profile.edit

audit_logs.view
```

Wildcard: `*` (admin).

## Appendix B — Analytics Event Catalogue

| Event name | Properties |
|------------|-----------|
| `app_opened` | `session_id`, `is_cold_start` |
| `login_attempt` | `tenant_slug` |
| `login_success` | `role_slug`, `tenant_id` (hashed) |
| `login_failed` | `reason` |
| `logout` | `reason` (manual / expired / forced) |
| `tenant_not_found` | `slug` |
| `subscription_blocked` | `status` |
| `permission_denied` | `required_permission`, `screen` |
| `screen_view` | `screen_name`, `duration_ms_prev_screen` |
| `pos_shift_opened` | `terminal_id`, `opening_cash` |
| `pos_shift_closed` | `shift_id`, `variance`, `duration_min` |
| `pos_cash_movement` | `type`, `amount` |
| `pos_order_created` | `item_count`, `grand_total`, `payment_method`, `has_client`, `has_discount` |
| `pos_order_returned` | `order_id`, `return_amount` |
| `barcode_scan_success` | — |
| `barcode_scan_miss` | `code` (hashed) |
| `client_created` | — |
| `client_payment_recorded` | `amount` |
| `expense_created` | `amount`, `category_id` |
| `account_transfer` | `amount` |
| `api_error_4xx` | `status`, `endpoint`, `code` |
| `api_error_5xx` | `status`, `endpoint` |
| `network_error` | `endpoint`, `type` |
| `language_changed` | `from`, `to` |
| `theme_changed` | `to` |

**PII rules:**
- Never send `name`, `email`, `phone`, `address` in event properties
- Hash `user_id` with a per-tenant salt before sending
- `tenant_id` acceptable as raw integer (needed for segmentation)

## Appendix C — Deep Link Schema

Scheme: `operix://` (and universal link `https://app.operix.com/deeplink/...`)

| Path | Opens |
|------|-------|
| `operix://` | Home |
| `operix://login` | Login |
| `operix://pos` | POS main |
| `operix://pos/orders/{id}` | POS order detail |
| `operix://pos/orders/{id}/receipt` | Receipt |
| `operix://clients` | Clients list |
| `operix://clients/{id}` | Client detail |
| `operix://clients/{id}/record-payment` | Record payment modal |
| `operix://products` | Products list |
| `operix://products/{id}` | Product detail |
| `operix://sales-invoices/{id}` | Sales invoice detail |
| `operix://suppliers/{id}` | Supplier detail |
| `operix://expenses/new` | New expense |
| `operix://accounts/{id}` | Account detail |
| `operix://shift/close` | Close shift modal |
| `operix://billing` | Billing status |

Deep links from notifications carry `?source=notification&notif_id={uuid}` so tap-through can be measured.

## Appendix D — Feature Flag Catalogue

Remote Config keys:

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `min_supported_version` | string | `"1.0.0"` | Force-update prompt threshold |
| `offline_pos_enabled` | bool per tenant | false | Phase 3 toggle |
| `bluetooth_print_enabled` | bool | false | Phase 2 |
| `push_notifications_enabled` | bool | false | Phase 2 |
| `biometric_login_enabled` | bool | false | Phase 2 |
| `dark_mode_enabled` | bool | false | Phase 2 |
| `reports_hub_enabled` | bool | false | Phase 3 |
| `approvals_enabled` | bool | false | Phase 3 |
| `multi_branch_switcher_enabled` | bool | false | Phase 3 |
| `arabic_numerals_enabled` | bool | false | Tenant display pref |
| `api_timeout_seconds` | int | 30 | Override default |
| `max_products_cached` | int | 10000 | Drift cap |

## Appendix E — Sample Payloads

### E.1 Login response

```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": 42,
    "name": "Sara Ahmed",
    "email": "sara@tech-store.com",
    "phone": "+201234567890",
    "avatar_url": "https://cdn.operix.com/avatars/42.jpg",
    "role_id": 5,
    "role": { "id": 5, "slug": "manager", "name": "Manager" },
    "tenant_id": 12,
    "tenant": {
      "id": 12,
      "slug": "tech-store",
      "name": "Tech Store",
      "currency_code": "EGP",
      "locale": "en",
      "timezone": "Africa/Cairo",
      "theme_primary_color": "#4f46e5",
      "logo_url": "https://cdn.operix.com/logos/12.png",
      "status": "active"
    },
    "drawer_account": { "id": 8, "name": "Register 1", "current_balance": "1500.00" },
    "default_account": { "id": 1, "name": "Main Cash", "current_balance": "50000.00" },
    "is_active": true
  },
  "tenant": { "id": 12, "slug": "tech-store" },
  "redirect_to": "/dashboard"
}
```

### E.2 Permissions response (manager)

```json
{
  "role": { "id": 5, "slug": "manager", "name": "Manager" },
  "permissions": [
    "dashboard.view",
    "pos.view", "pos.create", "pos.update", "pos.clients", "pos.select_account",
    "shifts.view", "shifts.create", "shifts.update",
    "sales.view", "sales.create", "sales.update", "sales.approve", "sales.return",
    "sales.collect_payment", "sales.pay_credit",
    "clients.view", "clients.create", "clients.update",
    "products.view", "products.update",
    "inventory.view", "inventory.update",
    "suppliers.view", "suppliers.create", "suppliers.update",
    "purchases.view", "purchases.create", "purchases.update",
    "expenses.view", "expenses.create", "expenses.update",
    "accounts.view", "accounts.create", "accounts.update",
    "employees.view",
    "reports.view",
    "settings.view",
    "billing.view"
  ]
}
```

### E.3 POS order submission request

```json
{
  "client_id": 42,
  "inventory_id": 3,
  "date": "2026-04-13",
  "items": [
    {
      "product_id": 101,
      "quantity": 2,
      "unit_price": "50.00"
    },
    {
      "product_id": 102,
      "product_variant_id": 77,
      "quantity": 1,
      "unit_price": "200.00"
    }
  ],
  "discount_type": "percent",
  "discount_value": 5,
  "tax_id": 1,
  "payment_method_id": 2,
  "account_id": 8,
  "paid_amount": "300.00",
  "note": "Counter sale"
}
```

### E.4 POS order submission success response

```json
{
  "message": "Order created successfully",
  "pos_order": {
    "id": 9981,
    "receipt_number": "RCP-20260413-0012",
    "user_id": 42,
    "shift_id": 55,
    "client_id": 42,
    "inventory_id": 3,
    "date": "2026-04-13",
    "subtotal": "300.00",
    "discount_value": "5",
    "discount_type": "percent",
    "discount_total": "15.00",
    "tax_rate": "14.00",
    "tax_total": "39.90",
    "shipping_cost": "0.00",
    "grand_total": "324.90",
    "paid_amount": "300.00",
    "change_amount": "0.00",
    "due_amount": "24.90",
    "payment_method": "cash",
    "payment_status": "partial",
    "status": "partial",
    "channel": "pos",
    "items": [
      {
        "id": 17211,
        "product_id": 101,
        "product_name": "Water Bottle 500ml",
        "product_sku": "WB500",
        "quantity": "2.00",
        "unit_price": "50.00",
        "line_total": "100.00"
      },
      {
        "id": 17212,
        "product_id": 102,
        "product_variant_id": 77,
        "product_name": "T-Shirt",
        "variant_label": "Black / M",
        "quantity": "1.00",
        "unit_price": "200.00",
        "line_total": "200.00"
      }
    ]
  }
}
```

### E.5 Validation error (422)

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "items.0.quantity": ["Quantity exceeds available stock (available: 1)."],
    "client_id": ["Client is blocked."]
  }
}
```

### E.6 402 Subscription blocked

```json
{
  "message": "Your subscription is suspended. Please renew to continue.",
  "subscription_status": "suspended",
  "renewal_url": "https://operix.com/billing/tech-store/renew"
}
```

### E.7 Shift open request / response

Request:

```json
{
  "terminal_id": 3,
  "opening_cash": "500.00",
  "note": "Morning shift"
}
```

Response:

```json
{
  "message": "Shift opened",
  "shift": {
    "id": 55,
    "terminal_id": 3,
    "terminal": { "id": 3, "name": "Register 1" },
    "drawer_account_id": 8,
    "opened_by": { "id": 42, "name": "Sara Ahmed" },
    "opened_at": "2026-04-13T09:00:00+02:00",
    "opening_cash": "500.00",
    "status": "open"
  }
}
```

### E.8 Close shift request

```json
{
  "actual_cash": "3250.00",
  "variance_notes": "Short by 10 EGP — possible miscount."
}
```

## Appendix F — State Machine Diagrams (textual)

### POS Order Payment

```
[new] → submit with paid == total → paid
[new] → submit with 0 < paid < total → partial
[new] → submit with paid == 0 → due

[partial] → record payment (brings paid up to total) → paid
[due] → record payment (brings paid to total) → paid
[due] → record payment (partial) → partial
```

### Sales Invoice

```
draft ─ edit / add items ─► draft
draft ─ post ─► posted
posted ─ record partial payment ─► partially_paid
posted ─ record full payment ─► paid
partially_paid ─ record payment (full balance) ─► paid
posted / partially_paid ─ cancel ─► cancelled
(derived) posted / partially_paid ∧ due_date < today ⇒ overdue
```

### Shift

```
(none) ─ open ─► open
open ─ cash_in / cash_out / reverse ─► open
open ─ close ─► closed
```

## Appendix G — Color & Status Conventions

| Status | Color | Icon |
|--------|-------|------|
| Draft | grey-500 | pencil |
| Posted | blue-500 | paper-plane |
| Partially paid | amber-500 | half-circle |
| Paid | green-600 | check |
| Overdue | red-600 | alert |
| Cancelled | grey-400 (strikethrough) | x-circle |
| Pending | amber-400 | clock |
| Approved | green-600 | check-circle |
| Rejected | red-600 | x-circle |
| Active | green-600 | — |
| Inactive | grey-400 | — |
| Blocked | red-600 | lock |
| Open shift | green-600 | play |
| Closed shift | grey-500 | stop |
| Low stock | amber-500 | triangle |
| Out of stock | red-600 | x |
| In stock | green-600 | — |

## Appendix H — Sample Mobile-Specific i18n Keys

```json
{
  "mobile.offline.banner": "You're offline. Showing cached data.",
  "mobile.offline.last_updated": "Last updated {time} ago",
  "mobile.offline.cannot_submit": "This action requires an internet connection.",
  "mobile.pull_to_refresh": "Pull down to refresh",
  "mobile.tap_to_retry": "Tap to retry",
  "mobile.scan.hint": "Point camera at the barcode",
  "mobile.scan.torch": "Flashlight",
  "mobile.scan.manual_entry": "Enter manually",
  "mobile.scan.not_found": "No product found for barcode {code}",
  "mobile.biometric.enable": "Enable {method} unlock",
  "mobile.biometric.prompt": "Unlock Operix",
  "mobile.update_required.title": "Update required",
  "mobile.update_required.message": "Please update to the latest version to continue.",
  "mobile.update_required.cta": "Update now",
  "mobile.connection_restored": "Back online",
  "mobile.cart.empty": "Cart is empty. Add items to start a sale.",
  "mobile.cart.walkin": "Walk-in customer",
  "mobile.shift.required": "A shift must be opened before you can sell.",
  "mobile.shift.variance_note_required": "Please explain the variance.",
  "mobile.permission.denied": "You don't have permission to {action}."
}
```

## Appendix I — Reference Device Benchmarks (targets)

| Device | Cold start | Home render | POS screen | POS submit P95 |
|--------|-----------|-------------|-----------|----------------|
| iPhone SE (2020) | ≤ 3.0s | ≤ 1.0s | ≤ 1.2s | ≤ 1.2s |
| iPhone 13 | ≤ 2.0s | ≤ 0.7s | ≤ 0.8s | ≤ 1.0s |
| iPad Pro 11" | ≤ 2.0s | ≤ 0.6s | ≤ 0.7s | ≤ 1.0s |
| Pixel 4a | ≤ 3.0s | ≤ 1.0s | ≤ 1.2s | ≤ 1.2s |
| Samsung A52 | ≤ 3.5s | ≤ 1.2s | ≤ 1.5s | ≤ 1.3s |

## Appendix J — Traceability Matrix Template

Maintain `traceability-matrix.csv` with columns:

| SRS Section | Requirement ID | Screen IDs | Test IDs | Status |
|-------------|---------------|-----------|----------|--------|
| 04 | FR-00-003 | SCR-003 | UT-auth-001, E2E-001 | — |
| 04 | FR-02-009 | SCR-021, SCR-022, SCR-024 | WT-pos-cart-01, E2E-004 | — |
| ... | ... | ... | ... | ... |

## Appendix K — References

**Internal:**

- `.ai/architecture.md` — platform architecture
- `.ai/database.md` — database schema
- `.ai/coding_rules.md` — coding standards
- `docs/TENANT_MOBILE_APP_BUSINESS_BRIEF.md` — business context (kept as source of truth for "why")
- `docs/TENANT_MOBILE_APP_API_GUIDE.md` — superseded by section `06-api-reference.md`
- `docs/TENANT_MOBILE_APP_IMPLEMENTATION_GUIDE.md` — superseded by sections `10`, `11`
- `business_finance_manager_api/routes/tenant_api.php` — canonical route list
- `business_finance_manager_api/app/Http/Controllers/Tenant/` — controllers
- `business_finance_manager_api/app/Models/` — 68 Eloquent models
- `business_finance_manager_api/app/Services/` — 17 service classes
- `business-finance-manager-frontend/apps/tenant-app/src/locales/*.json` — i18n source of truth
- `business-finance-manager-frontend/e2e/tests/` — 31 E2E flows (user journey reference)

**External:**

- [Flutter docs](https://docs.flutter.dev/)
- [Material Design 3](https://m3.material.io/)
- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [Android Material Guidelines](https://m3.material.io/)
- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)

## Appendix L — Acronyms

| Acronym | Meaning |
|---------|---------|
| API | Application Programming Interface |
| APNs | Apple Push Notification service |
| AR | Accounts Receivable |
| AP | Accounts Payable |
| ARB | Application Resource Bundle (Flutter i18n) |
| CI/CD | Continuous Integration / Continuous Delivery |
| CRUD | Create, Read, Update, Delete |
| CTA | Call to Action |
| E2E | End to End |
| FCM | Firebase Cloud Messaging |
| GA | General Availability |
| GL | General Ledger |
| HIG | Human Interface Guidelines |
| ICU | International Components for Unicode |
| i18n | Internationalization |
| JWT | JSON Web Token |
| KPI | Key Performance Indicator |
| LTR | Left to Right |
| MVP | Minimum Viable Product |
| NFR | Non-Functional Requirement |
| OTP | One-Time Password |
| PII | Personally Identifiable Information |
| POS | Point of Sale |
| RBAC | Role-Based Access Control |
| RTL | Right to Left |
| SDK | Software Development Kit |
| SKU | Stock Keeping Unit |
| SOT | Single Source of Truth |
| SRS | Software Requirements Specification |
| SSL/TLS | Secure Sockets Layer / Transport Layer Security |
| UAT | User Acceptance Testing |
| UI/UX | User Interface / User Experience |
| WCAG | Web Content Accessibility Guidelines |

## Appendix M — Change Log

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-04-13 | SRS initial draft | Full specification across 17 files |
