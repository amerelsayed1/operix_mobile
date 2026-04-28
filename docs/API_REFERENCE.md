# Operix API Reference

> **Base URL:** `https://operixhq.com`  
> **API Prefix:** `/api/v1/{tenant_slug}/` for tenant endpoints  
> **Auth:** All tenant endpoints require `Authorization: Bearer <jwt_token>`  
> **Content-Type:** `application/json`

---

## Response Envelope

Every response follows one of two shapes:

### Success
```json
{
  "success": true,
  "message": "Done",
  "data": { }
}
```

### Error
```json
{
  "success": false,
  "message": "Human-readable error",
  "errors": {
    "field_name": ["Validation message"]
  }
}
```

### HTTP Status Codes
| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 204 | No Content (delete success) |
| 401 | Unauthenticated |
| 403 | Forbidden (suspended / wrong role) |
| 404 | Not Found |
| 422 | Validation Error |
| 500 | Server Error |

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [Dashboard](#2-dashboard)
3. [Products](#3-products)
4. [Product Categories](#4-product-categories)
5. [Units](#5-units)
6. [Clients (Customers)](#6-clients-customers)
7. [Suppliers](#7-suppliers)
8. [Sales Invoices](#8-sales-invoices)
9. [Purchase Invoices](#9-purchase-invoices)
10. [POS — Shifts](#10-pos--shifts)
11. [POS — Orders](#11-pos--orders)
12. [Expenses](#12-expenses)
13. [Expense Categories](#13-expense-categories)
14. [Accounts](#14-accounts)
15. [Inventory / Warehouses](#15-inventory--warehouses)
16. [Reports](#16-reports)
17. [Settings — Taxes](#17-settings--taxes)
18. [Settings — Payment Methods](#18-settings--payment-methods)
19. [Settings — Currencies](#19-settings--currencies)
20. [Employees (Users)](#20-employees-users)

---

## 1. Authentication

### 1.1 Login

```
POST /api/v1/login
```

**Request Body**
```json
{
  "email": "admin@myshop.com",
  "password": "Secret123!",
  "remember_me": false
}
```

**Success 200**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "remember_me": false,
  "user": {
    "id": 12,
    "name": "Ahmed Hesham",
    "email": "admin@myshop.com",
    "avatar_url": null,
    "business_name": "My Shop",
    "business_logo": null,
    "default_currency": "EGP",
    "theme_mode": "light",
    "theme_primary_color": "#6366f1",
    "tenant_id": 5,
    "tenant": {
      "id": 5,
      "name": "My Shop",
      "slug": "myshop",
      "status": "active",
      "plan": {
        "id": 2,
        "name": "Business",
        "slug": "business"
      }
    },
    "role": {
      "id": 1,
      "name": "Admin"
    },
    "permissions": ["dashboard.view", "products.view", "sales.view", "pos.view"]
  }
}
```

**Error 401 — Invalid credentials**
```json
{
  "error": "Invalid credentials"
}
```

**Error 403 — Suspended account**
```json
{
  "error": "Your account has been suspended. Please contact support for assistance."
}
```

**Error 422 — Validation**
```json
{
  "message": "The email field is required.",
  "errors": {
    "email": ["The email field is required."],
    "password": ["The password field is required."]
  }
}
```

---

### 1.2 Logout

```
POST /api/v1/{slug}/logout
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "message": "Successfully logged out"
}
```

---

### 1.3 Get Current User

```
GET /api/v1/{slug}/me
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "id": 12,
  "name": "Ahmed Hesham",
  "email": "admin@myshop.com",
  "avatar_url": "https://operixhq.com/storage/avatars/12.jpg",
  "business_name": "My Shop",
  "default_currency": "EGP",
  "tenant_id": 5,
  "role": {
    "id": 1,
    "name": "Admin"
  }
}
```

**Error 401**
```json
{
  "message": "Unauthenticated."
}
```

---

### 1.4 Get My Permissions

```
GET /api/v1/{slug}/me/permissions
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "permissions": [
    "dashboard.view",
    "products.view",
    "products.create",
    "products.edit",
    "products.delete",
    "sales.view",
    "sales.create",
    "pos.view",
    "pos.create",
    "reports.view"
  ]
}
```

---

## 2. Dashboard

### 2.1 Dashboard Summary

```
GET /api/v1/{slug}/dashboard
Authorization: Bearer <token>
```

**Query Parameters**
| Param | Type | Description |
|-------|------|-------------|
| `period` | string | `daily` \| `weekly` \| `monthly` (default: monthly) |

**Success 200**
```json
{
  "total_balance": 45230.50,
  "total_revenue": 12800.00,
  "total_expenses": 3200.00,
  "total_purchases": 0,
  "total_returns": 450.00,
  "returns_count": 3,
  "net_profit": 9600.00,
  "currency": "EGP",
  "period": {
    "start": "2026-04-01",
    "end": "2026-04-28"
  }
}
```

**Error 403**
```json
{
  "success": false,
  "message": "You do not have permission to access the dashboard."
}
```

---

### 2.2 Dashboard KPIs

```
GET /api/v1/{slug}/dashboard/kpis
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "total_orders": 142,
    "total_clients": 58,
    "total_products": 320,
    "low_stock_count": 7,
    "outstanding_invoices": 5,
    "overdue_invoices": 2,
    "pending_payments_amount": 8500.00,
    "total_inventory_value": 92000.00
  }
}
```

---

### 2.3 Sales Trend Chart

```
GET /api/v1/{slug}/dashboard/charts/sales-trend
Authorization: Bearer <token>
```

**Query Parameters**
| Param | Type | Description |
|-------|------|-------------|
| `from` | date | Start date `YYYY-MM-DD` |
| `to` | date | End date `YYYY-MM-DD` |
| `groupBy` | string | `day` \| `week` \| `month` |

**Success 200**
```json
{
  "success": true,
  "data": [
    { "label": "Apr 1", "date": "2026-04-01", "revenue": 1200.00, "orders": 8 },
    { "label": "Apr 2", "date": "2026-04-02", "revenue": 980.50, "orders": 5 },
    { "label": "Apr 3", "date": "2026-04-03", "revenue": 1540.00, "orders": 11 }
  ]
}
```

---

### 2.4 Top Products Chart

```
GET /api/v1/{slug}/dashboard/charts/top-products
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": [
    { "product_id": 1, "name": "Laptop Pro 15", "units_sold": 34, "revenue": 51000.00 },
    { "product_id": 7, "name": "Wireless Mouse", "units_sold": 88, "revenue": 8800.00 },
    { "product_id": 3, "name": "USB-C Hub", "units_sold": 55, "revenue": 5500.00 }
  ]
}
```

---

### 2.5 Low Stock List

```
GET /api/v1/{slug}/dashboard/lists/low-stock
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 14,
      "name": "Office Chair",
      "sku": "SKU-0014",
      "current_stock": 2,
      "minimum_stock_alert": 5,
      "unit": { "id": 1, "name": "Piece" }
    }
  ]
}
```

---

## 3. Products

### 3.1 List Products

```
GET /api/v1/{slug}/products
Authorization: Bearer <token>
```

**Query Parameters**
| Param | Type | Description |
|-------|------|-------------|
| `search` | string | Search by name, SKU, or barcode |
| `is_active` | boolean | Filter active/inactive |
| `product_category_id` | integer | Filter by category |
| `has_variants` | boolean | Filter variant vs simple products |

**Success 200**
```json
[
  {
    "id": 1,
    "name": "Laptop Pro 15",
    "sku": "LP-001",
    "barcode": "6901234567890",
    "cost_price": "1200.00",
    "selling_price": "1500.00",
    "is_active": true,
    "has_variants": false,
    "current_stock": 25,
    "image_url": "https://operixhq.com/storage/products/1.jpg",
    "category": {
      "id": 2,
      "name": "Electronics"
    },
    "unit": {
      "id": 1,
      "name": "Piece",
      "name_ar": "قطعة"
    },
    "tax": {
      "id": 1,
      "name": "VAT 14%",
      "rate": 14.00
    },
    "product_units": [
      {
        "id": 1,
        "unit_id": 1,
        "barcode": "6901234567890",
        "is_default": true,
        "unit": { "id": 1, "name": "Piece", "name_ar": "قطعة" }
      }
    ]
  }
]
```

---

### 3.2 Get Product

```
GET /api/v1/{slug}/products/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "id": 1,
  "name": "Laptop Pro 15",
  "sku": "LP-001",
  "barcode": "6901234567890",
  "cost_price": "1200.00",
  "selling_price": "1500.00",
  "is_active": true,
  "has_variants": false,
  "minimum_stock_alert": 5,
  "image_url": null,
  "category": { "id": 2, "name": "Electronics" },
  "unit": { "id": 1, "name": "Piece", "name_ar": "قطعة" },
  "tax": { "id": 1, "name": "VAT 14%", "rate": 14.00 },
  "product_units": [
    {
      "id": 1,
      "unit_id": 1,
      "barcode": "6901234567890",
      "is_default": true,
      "unit": { "id": 1, "name": "Piece", "name_ar": "قطعة" }
    }
  ],
  "inventories": [
    { "id": 1, "name": "Main Warehouse", "pivot": { "quantity": 25 } }
  ]
}
```

**Error 404**
```json
{
  "success": false,
  "message": "Product not found."
}
```

---

### 3.3 Create Product

```
POST /api/v1/{slug}/products
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "name": "Wireless Keyboard",
  "sku": "WK-001",
  "barcode": "6901234500001",
  "product_category_id": 2,
  "unit_id": 1,
  "cost_price": 150.00,
  "selling_price": 220.00,
  "minimum_stock_alert": 10,
  "is_active": true,
  "has_variants": false
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Product created successfully.",
  "data": {
    "id": 42,
    "name": "Wireless Keyboard",
    "sku": "WK-001",
    "barcode": "6901234500001",
    "cost_price": "150.00",
    "selling_price": "220.00",
    "is_active": true,
    "has_variants": false,
    "unit": { "id": 1, "name": "Piece" },
    "category": { "id": 2, "name": "Electronics" }
  }
}
```

**Error 422**
```json
{
  "message": "The sku has already been taken.",
  "errors": {
    "sku": ["The sku has already been taken."],
    "selling_price": ["The selling price field is required."]
  }
}
```

---

### 3.4 Update Product

```
PUT /api/v1/{slug}/products/{id}
Authorization: Bearer <token>
```

**Request Body** *(same fields as Create, all optional for PUT)*
```json
{
  "name": "Wireless Keyboard V2",
  "selling_price": 240.00,
  "is_active": true
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Product updated successfully.",
  "data": {
    "id": 42,
    "name": "Wireless Keyboard V2",
    "selling_price": "240.00",
    "is_active": true
  }
}
```

---

### 3.5 Delete Product

```
DELETE /api/v1/{slug}/products/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "message": "Product deleted successfully."
}
```

**Error 409 — Product in use**
```json
{
  "success": false,
  "message": "Cannot delete product. It is referenced in existing invoices or orders."
}
```

---

### 3.6 Get Next Barcode + SKU

```
GET /api/v1/{slug}/products/next-codes
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "barcode": "6901234500042",
  "sku": "SKU-0043"
}
```

---

## 4. Product Categories

### 4.1 List Categories

```
GET /api/v1/{slug}/product-categories
Authorization: Bearer <token>
```

**Success 200**
```json
[
  { "id": 1, "name": "Food & Beverages", "name_ar": "طعام ومشروبات", "products_count": 15 },
  { "id": 2, "name": "Electronics", "name_ar": "إلكترونيات", "products_count": 42 }
]
```

---

### 4.2 Create Category

```
POST /api/v1/{slug}/product-categories
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "name": "Stationery",
  "name_ar": "قرطاسية"
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Category created successfully.",
  "data": { "id": 5, "name": "Stationery", "name_ar": "قرطاسية" }
}
```

**Error 422**
```json
{
  "message": "The name field is required.",
  "errors": {
    "name": ["The name field is required."]
  }
}
```

---

## 5. Units

### 5.1 List Units

```
GET /api/v1/{slug}/settings/units
Authorization: Bearer <token>
```

**Success 200**
```json
[
  { "id": 1, "name_en": "Piece", "name_ar": "قطعة" },
  { "id": 2, "name_en": "Kilogram", "name_ar": "كيلوجرام" },
  { "id": 3, "name_en": "Liter", "name_ar": "لتر" },
  { "id": 4, "name_en": "Carton", "name_ar": "كرتون" }
]
```

---

### 5.2 Create Unit

```
POST /api/v1/{slug}/settings/units
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "name_en": "Dozen",
  "name_ar": "دزينة"
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Unit created successfully.",
  "data": { "id": 5, "name_en": "Dozen", "name_ar": "دزينة" }
}
```

---

### 5.3 Update Unit

```
PUT /api/v1/{slug}/settings/units/{id}
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "name_en": "Box",
  "name_ar": "صندوق"
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Unit updated successfully.",
  "data": { "id": 5, "name_en": "Box", "name_ar": "صندوق" }
}
```

---

### 5.4 Delete Unit

```
DELETE /api/v1/{slug}/settings/units/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{ "success": true, "message": "Unit deleted successfully." }
```

---

## 6. Clients (Customers)

### 6.1 List Clients

```
GET /api/v1/{slug}/clients
Authorization: Bearer <token>
```

**Query Parameters**
| Param | Type | Description |
|-------|------|-------------|
| `search` | string | Search by name or phone |
| `status` | string | `active` \| `inactive` |

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Mohamed Ali",
      "phone": "01012345678",
      "email": "m.ali@gmail.com",
      "address": "Cairo, Egypt",
      "balance": "1200.00",
      "credit_limit": "5000.00",
      "status": "active",
      "is_tax_exempt": false,
      "created_at": "2026-01-15T10:00:00Z"
    }
  ]
}
```

---

### 6.2 Get Client

```
GET /api/v1/{slug}/clients/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Mohamed Ali",
    "phone": "01012345678",
    "email": "m.ali@gmail.com",
    "address": "Cairo, Egypt",
    "balance": "1200.00",
    "credit_limit": "5000.00",
    "overdue_days_threshold": 30,
    "status": "active",
    "is_tax_exempt": false,
    "notes": "Preferred client",
    "blocked_at": null,
    "blocked_reason": null
  }
}
```

---

### 6.3 Create Client

```
POST /api/v1/{slug}/clients
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "name": "Sara Hassan",
  "phone": "01098765432",
  "email": "sara@example.com",
  "address": "Alexandria, Egypt",
  "credit_limit": 3000.00,
  "is_tax_exempt": false,
  "notes": ""
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Client created successfully.",
  "data": {
    "id": 55,
    "name": "Sara Hassan",
    "phone": "01098765432",
    "email": "sara@example.com",
    "balance": "0.00",
    "credit_limit": "3000.00",
    "status": "active"
  }
}
```

**Error 422**
```json
{
  "message": "The name field is required.",
  "errors": {
    "name": ["The name field is required."]
  }
}
```

---

### 6.4 Update Client

```
PUT /api/v1/{slug}/clients/{id}
Authorization: Bearer <token>
```

**Request Body** *(any subset of Create fields)*
```json
{
  "phone": "01011112222",
  "credit_limit": 5000.00
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Client updated successfully.",
  "data": { "id": 55, "phone": "01011112222", "credit_limit": "5000.00" }
}
```

---

### 6.5 Delete Client

```
DELETE /api/v1/{slug}/clients/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{ "success": true, "message": "Client deleted successfully." }
```

---

### 6.6 Client Statement

```
GET /api/v1/{slug}/clients/{id}/statement
Authorization: Bearer <token>
```

**Query Parameters:** `from` (date), `to` (date)

**Success 200**
```json
{
  "success": true,
  "data": {
    "client": { "id": 1, "name": "Mohamed Ali" },
    "opening_balance": "500.00",
    "closing_balance": "1200.00",
    "transactions": [
      {
        "date": "2026-04-01",
        "type": "invoice",
        "reference": "INV-0042",
        "debit": "800.00",
        "credit": "0.00",
        "balance": "1300.00",
        "notes": "Sales Invoice"
      },
      {
        "date": "2026-04-10",
        "type": "payment",
        "reference": "PMT-0018",
        "debit": "0.00",
        "credit": "100.00",
        "balance": "1200.00",
        "notes": "Partial payment"
      }
    ]
  }
}
```

---

## 7. Suppliers

### 7.1 List Suppliers

```
GET /api/v1/{slug}/suppliers
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Tech Distributors Co.",
      "supplier_code": "SUP-001",
      "company_name": "Tech Distributors LLC",
      "contact_person": "Khaled Farouk",
      "email": "info@techdist.com",
      "phone": "+201234567890",
      "type": "company",
      "payable_balance": "25000.00",
      "status": "active"
    }
  ]
}
```

---

### 7.2 Get Supplier

```
GET /api/v1/{slug}/suppliers/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Tech Distributors Co.",
    "supplier_code": "SUP-001",
    "company_name": "Tech Distributors LLC",
    "contact_person": "Khaled Farouk",
    "email": "info@techdist.com",
    "phone": "+201234567890",
    "mobile": "+201111111111",
    "address": "10 Industry St, Cairo",
    "city": "Cairo",
    "country": "EG",
    "vat_number": "EG123456789",
    "type": "company",
    "opening_balance": "0.00",
    "payable_balance": "25000.00",
    "advance_balance": "0.00",
    "credit_limit": "100000.00",
    "payment_terms": 30,
    "status": "active",
    "rating": 5
  }
}
```

---

### 7.3 Create Supplier

```
POST /api/v1/{slug}/suppliers
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "name": "Global Supplies Ltd.",
  "company_name": "Global Supplies Ltd.",
  "contact_person": "John Smith",
  "email": "john@globalsupplies.com",
  "phone": "+441234567890",
  "type": "company",
  "address": "London, UK",
  "payment_terms": 45,
  "credit_limit": 50000.00
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Supplier created successfully.",
  "data": {
    "id": 10,
    "name": "Global Supplies Ltd.",
    "supplier_code": "SUP-010",
    "payable_balance": "0.00",
    "status": "active"
  }
}
```

---

### 7.4 Supplier Ledger

```
GET /api/v1/{slug}/suppliers/{id}/ledger
Authorization: Bearer <token>
```

**Query Parameters:** `from` (date), `to` (date)

**Success 200**
```json
{
  "success": true,
  "data": {
    "supplier": { "id": 1, "name": "Tech Distributors Co." },
    "opening_balance": "20000.00",
    "closing_balance": "25000.00",
    "transactions": [
      {
        "date": "2026-04-05",
        "type": "purchase_invoice",
        "reference": "PI-000012",
        "debit": "0.00",
        "credit": "8000.00",
        "balance": "28000.00"
      },
      {
        "date": "2026-04-12",
        "type": "payment",
        "reference": "SP-000005",
        "debit": "3000.00",
        "credit": "0.00",
        "balance": "25000.00"
      }
    ]
  }
}
```

---

## 8. Sales Invoices

### 8.1 List Sales Invoices

```
GET /api/v1/{slug}/sales-invoices
Authorization: Bearer <token>
```

**Query Parameters**
| Param | Type | Description |
|-------|------|-------------|
| `status` | string | `draft` \| `posted` \| `partially_paid` \| `paid` \| `overdue` \| `cancelled` |
| `client_id` | integer | Filter by client |
| `from` | date | Start date |
| `to` | date | End date |
| `search` | string | Search by invoice number |
| `page` | integer | Pagination page |
| `per_page` | integer | Items per page (default 20) |

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "invoice_number": "INV-0001",
      "status": "posted",
      "date": "2026-04-01",
      "due_date": "2026-05-01",
      "subtotal": "1000.00",
      "discount_total": "50.00",
      "tax_total": "133.00",
      "total_amount": "1083.00",
      "paid_amount": "0.00",
      "currency_code": "EGP",
      "client": {
        "id": 1,
        "name": "Mohamed Ali",
        "phone": "01012345678"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 20,
    "total": 54
  }
}
```

---

### 8.2 Get Sales Invoice

```
GET /api/v1/{slug}/sales-invoices/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "invoice_number": "INV-0001",
    "status": "posted",
    "date": "2026-04-01",
    "due_date": "2026-05-01",
    "posted_at": "2026-04-01T09:00:00Z",
    "subtotal": "1000.00",
    "discount_total": "50.00",
    "tax_total": "133.00",
    "total_amount": "1083.00",
    "paid_amount": "0.00",
    "currency_code": "EGP",
    "exchange_rate": "1.000000",
    "notes": "Thank you for your business.",
    "client": { "id": 1, "name": "Mohamed Ali" },
    "inventory": { "id": 1, "name": "Main Warehouse" },
    "items": [
      {
        "id": 1,
        "product_id": 7,
        "product_name": "Wireless Mouse",
        "quantity": 2,
        "unit_price": "500.00",
        "discount_value": "50.00",
        "discount_type": "fixed",
        "tax_rate": "14.00",
        "subtotal": "950.00",
        "tax_amount": "133.00",
        "total": "1083.00"
      }
    ]
  }
}
```

---

### 8.3 Create Sales Invoice

```
POST /api/v1/{slug}/sales-invoices
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "client_id": 1,
  "inventory_id": 1,
  "date": "2026-04-28",
  "due_date": "2026-05-28",
  "currency_code": "EGP",
  "notes": "First order",
  "items": [
    {
      "product_id": 7,
      "quantity": 2,
      "unit_price": 500.00,
      "discount_value": 50.00,
      "discount_type": "fixed"
    }
  ]
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Invoice created successfully.",
  "data": {
    "id": 55,
    "invoice_number": "INV-0055",
    "status": "draft",
    "total_amount": "1083.00",
    "date": "2026-04-28"
  }
}
```

**Error 422**
```json
{
  "message": "The items field is required.",
  "errors": {
    "items": ["The items field is required."],
    "client_id": ["The client id field is required."]
  }
}
```

**Error 422 — Closed accounting period**
```json
{
  "success": false,
  "message": "The selected date falls within a closed accounting period."
}
```

---

### 8.4 Post Invoice

```
POST /api/v1/{slug}/sales-invoices/{id}/post
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "message": "Invoice posted successfully.",
  "data": {
    "id": 55,
    "invoice_number": "INV-0055",
    "status": "posted",
    "posted_at": "2026-04-28T12:00:00Z"
  }
}
```

**Error 422 — Already posted**
```json
{
  "success": false,
  "message": "Invoice is already posted."
}
```

---

### 8.5 Record Payment on Invoice

```
POST /api/v1/{slug}/sales-invoices/{id}/record-payment
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "amount": 500.00,
  "account_id": 2,
  "payment_date": "2026-04-28",
  "payment_method": "cash",
  "notes": "Partial payment"
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Payment recorded successfully.",
  "data": {
    "id": 55,
    "paid_amount": "500.00",
    "total_amount": "1083.00",
    "status": "partially_paid"
  }
}
```

---

### 8.6 Cancel Invoice

```
POST /api/v1/{slug}/sales-invoices/{id}/cancel
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "message": "Invoice cancelled successfully.",
  "data": { "id": 55, "status": "cancelled" }
}
```

---

## 9. Purchase Invoices

### 9.1 List Purchase Invoices

```
GET /api/v1/{slug}/purchase-invoices
Authorization: Bearer <token>
```

**Query Parameters:** `status`, `supplier_id`, `from`, `to`, `search`, `page`, `per_page`

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "invoice_number": "PI-000001",
      "status": "posted",
      "date": "2026-04-01",
      "due_date": "2026-05-01",
      "subtotal": "8000.00",
      "tax_total": "0.00",
      "total_amount": "8000.00",
      "paid_amount": "3000.00",
      "currency_code": "EGP",
      "supplier": { "id": 1, "name": "Tech Distributors Co." }
    }
  ],
  "meta": { "current_page": 1, "last_page": 2, "per_page": 20, "total": 22 }
}
```

---

### 9.2 Get Purchase Invoice

```
GET /api/v1/{slug}/purchase-invoices/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "invoice_number": "PI-000001",
    "status": "posted",
    "date": "2026-04-01",
    "due_date": "2026-05-01",
    "subtotal": "8000.00",
    "tax_total": "0.00",
    "total_amount": "8000.00",
    "paid_amount": "3000.00",
    "notes": "Q2 stock replenishment",
    "supplier": { "id": 1, "name": "Tech Distributors Co." },
    "inventory": { "id": 1, "name": "Main Warehouse" },
    "items": [
      {
        "id": 1,
        "product_id": 1,
        "product_name": "Laptop Pro 15",
        "quantity": 5,
        "unit_price": "1200.00",
        "tax_rate": "0.00",
        "subtotal": "6000.00",
        "total": "6000.00"
      },
      {
        "id": 2,
        "product_id": 7,
        "product_name": "Wireless Mouse",
        "quantity": 20,
        "unit_price": "100.00",
        "tax_rate": "0.00",
        "subtotal": "2000.00",
        "total": "2000.00"
      }
    ]
  }
}
```

---

### 9.3 Create Purchase Invoice

```
POST /api/v1/{slug}/purchase-invoices
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "supplier_id": 1,
  "inventory_id": 1,
  "date": "2026-04-28",
  "due_date": "2026-05-28",
  "currency_code": "EGP",
  "notes": "Restocking order",
  "items": [
    {
      "product_id": 1,
      "quantity": 5,
      "unit_price": 1200.00
    }
  ]
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Purchase invoice created successfully.",
  "data": {
    "id": 22,
    "invoice_number": "PI-000022",
    "status": "draft",
    "total_amount": "6000.00"
  }
}
```

---

### 9.4 Post Purchase Invoice

```
POST /api/v1/{slug}/purchase-invoices/{id}/post
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "message": "Purchase invoice posted successfully.",
  "data": { "id": 22, "status": "posted" }
}
```

---

### 9.5 Add Payment to Purchase Invoice

```
POST /api/v1/{slug}/purchase-invoices/{id}/payment
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "amount": 3000.00,
  "account_id": 2,
  "payment_date": "2026-04-28",
  "payment_method": "bank_transfer",
  "notes": "Wire transfer ref TRF-4521"
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Payment added successfully.",
  "data": {
    "id": 22,
    "paid_amount": "3000.00",
    "total_amount": "6000.00",
    "status": "partially_paid"
  }
}
```

---

## 10. POS — Shifts

### 10.1 Open Shift

```
POST /api/v1/{slug}/pos/shift/open
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "terminal_id": 1,
  "opening_cash": 500.00,
  "notes": "Morning shift"
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Shift opened successfully.",
  "data": {
    "id": 18,
    "terminal_id": 1,
    "status": "open",
    "opened_by": 12,
    "opened_at": "2026-04-28T08:00:00Z",
    "opening_cash": "500.00",
    "drawer_account_id": 3,
    "terminal": { "id": 1, "name": "Terminal 1" }
  }
}
```

**Error 422 — Shift already open**
```json
{
  "success": false,
  "message": "A shift is already open on this terminal."
}
```

---

### 10.2 Get Current Shift

```
GET /api/v1/{slug}/pos/shift/current
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "id": 18,
    "terminal_id": 1,
    "status": "open",
    "opened_at": "2026-04-28T08:00:00Z",
    "opening_cash": "500.00",
    "drawer_account_id": 3,
    "terminal": { "id": 1, "name": "Terminal 1", "branch": { "id": 1, "name": "Main Branch" } },
    "orders_count": 7,
    "cash_sales": "3200.00",
    "total_sales": "4500.00"
  }
}
```

**Error 404 — No open shift**
```json
{
  "success": false,
  "message": "No open shift found."
}
```

---

### 10.3 Close Shift

```
POST /api/v1/{slug}/pos/shift/close
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "counted_cash": 3650.00,
  "notes": "End of morning shift"
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Shift closed successfully.",
  "data": {
    "id": 18,
    "status": "closed",
    "closed_at": "2026-04-28T16:00:00Z",
    "opening_cash": "500.00",
    "expected_cash": "3700.00",
    "counted_cash": "3650.00",
    "variance": "-50.00",
    "total_sales": "4500.00",
    "cash_sales": "3200.00"
  }
}
```

---

### 10.4 Shift Summary

```
GET /api/v1/{slug}/pos/shift/summary
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "shift_id": 18,
    "opened_at": "2026-04-28T08:00:00Z",
    "opening_cash": "500.00",
    "total_orders": 12,
    "total_sales": "6800.00",
    "cash_sales": "4200.00",
    "card_sales": "2600.00",
    "total_returns": "200.00",
    "total_expenses": "150.00",
    "cash_in": "0.00",
    "cash_out": "150.00",
    "expected_cash": "4550.00",
    "payment_breakdown": [
      { "method": "cash", "amount": "4200.00", "count": 8 },
      { "method": "card", "amount": "2600.00", "count": 4 }
    ]
  }
}
```

---

### 10.5 Record Cash Movement

```
POST /api/v1/{slug}/pos/shift/cash-movements
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "type": "cash_out",
  "amount": 200.00,
  "notes": "Petty cash for cleaning supplies"
}
```

*`type` can be `cash_in` or `cash_out`*

**Success 201**
```json
{
  "success": true,
  "message": "Cash movement recorded.",
  "data": {
    "id": 5,
    "type": "cash_out",
    "amount": "200.00",
    "notes": "Petty cash for cleaning supplies",
    "created_at": "2026-04-28T11:00:00Z"
  }
}
```

---

## 11. POS — Orders

### 11.1 List POS Orders

```
GET /api/v1/{slug}/pos-orders
Authorization: Bearer <token>
```

**Query Parameters:** `shift_id`, `payment_status` (`paid`/`partial`/`due`), `from`, `to`, `search`, `page`

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "receipt_number": "RCP-0001",
      "date": "2026-04-28",
      "grand_total": "228.00",
      "paid_amount": "228.00",
      "payment_status": "paid",
      "payment_method": "cash",
      "client_name": "Walk-in",
      "items_count": 2
    }
  ],
  "meta": { "current_page": 1, "last_page": 5, "per_page": 20, "total": 94 }
}
```

---

### 11.2 Create POS Order

```
POST /api/v1/{slug}/pos-orders
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "shift_id": 18,
  "client_id": null,
  "client_name": "Walk-in",
  "inventory_id": 1,
  "date": "2026-04-28",
  "payment_method": "cash",
  "paid_amount": 228.00,
  "notes": "",
  "discount_type": "percentage",
  "discount_value": 0,
  "items": [
    {
      "product_id": 7,
      "quantity": 2,
      "unit_price": 100.00
    }
  ]
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Order created successfully.",
  "data": {
    "id": 145,
    "receipt_number": "RCP-0145",
    "date": "2026-04-28",
    "subtotal": "200.00",
    "tax_total": "28.00",
    "grand_total": "228.00",
    "paid_amount": "228.00",
    "change_amount": "0.00",
    "payment_status": "paid",
    "payment_method": "cash"
  }
}
```

**Error 422 — Insufficient stock**
```json
{
  "success": false,
  "message": "Insufficient stock for Wireless Mouse. Available: 1, Requested: 2."
}
```

**Error 422 — No open shift**
```json
{
  "success": false,
  "message": "No open shift found. Please open a shift first."
}
```

---

### 11.3 Get POS Order

```
GET /api/v1/{slug}/pos-orders/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "id": 145,
    "receipt_number": "RCP-0145",
    "date": "2026-04-28",
    "subtotal": "200.00",
    "discount_total": "0.00",
    "tax_rate": "14.00",
    "tax_total": "28.00",
    "grand_total": "228.00",
    "paid_amount": "228.00",
    "change_amount": "0.00",
    "due_amount": "0.00",
    "payment_status": "paid",
    "payment_method": "cash",
    "client": null,
    "client_name": "Walk-in",
    "items": [
      {
        "id": 1,
        "product_id": 7,
        "product_name": "Wireless Mouse",
        "quantity": 2,
        "unit_price": "100.00",
        "subtotal": "200.00",
        "tax_amount": "28.00",
        "total": "228.00"
      }
    ]
  }
}
```

---

### 11.4 Get Receipt (Print Data)

```
GET /api/v1/{slug}/pos-orders/{id}/receipt
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "receipt_number": "RCP-0145",
    "date": "2026-04-28",
    "time": "14:30:00",
    "cashier": "Ahmed Hesham",
    "terminal": "Terminal 1",
    "business_name": "My Shop",
    "business_logo": null,
    "business_address": "Cairo, Egypt",
    "business_phone": "+201234567890",
    "items": [
      { "name": "Wireless Mouse", "qty": 2, "price": "100.00", "total": "200.00" }
    ],
    "subtotal": "200.00",
    "tax_label": "VAT 14%",
    "tax_total": "28.00",
    "grand_total": "228.00",
    "paid_amount": "228.00",
    "change_amount": "0.00",
    "payment_method": "Cash"
  }
}
```

---

## 12. Expenses

### 12.1 List Expenses

```
GET /api/v1/{slug}/expenses
Authorization: Bearer <token>
```

**Query Parameters:** `from`, `to`, `category_id`, `account_id`, `search`, `page`

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "date": "2026-04-10",
      "amount": "250.00",
      "description": "Office supplies",
      "category": { "id": 2, "name": "Office" },
      "account": { "id": 1, "name": "Cash Register" }
    }
  ],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 20, "total": 8 }
}
```

---

### 12.2 Create Expense

```
POST /api/v1/{slug}/expenses
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "amount": 250.00,
  "date": "2026-04-28",
  "description": "Printer paper and toner",
  "category_id": 2,
  "account_id": 1
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Expense created successfully.",
  "data": {
    "id": 22,
    "amount": "250.00",
    "date": "2026-04-28",
    "description": "Printer paper and toner",
    "category": { "id": 2, "name": "Office" }
  }
}
```

**Error 422**
```json
{
  "message": "The amount field is required.",
  "errors": {
    "amount": ["The amount field is required."],
    "account_id": ["The account id field is required."]
  }
}
```

---

### 12.3 Update Expense

```
PUT /api/v1/{slug}/expenses/{id}
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "amount": 300.00,
  "description": "Updated description"
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Expense updated successfully.",
  "data": { "id": 22, "amount": "300.00" }
}
```

---

### 12.4 Delete Expense

```
DELETE /api/v1/{slug}/expenses/{id}
Authorization: Bearer <token>
```

**Success 200**
```json
{ "success": true, "message": "Expense deleted successfully." }
```

---

## 13. Expense Categories

### 13.1 List Categories

```
GET /api/v1/{slug}/expense-categories
Authorization: Bearer <token>
```

**Success 200**
```json
[
  { "id": 1, "name": "Ads", "name_en": "Ads", "name_ar": "إعلانات", "is_default": true },
  { "id": 2, "name": "Office", "name_en": "Office", "name_ar": "مكتب", "is_default": false },
  { "id": 3, "name": "Logistics & Delivery", "name_en": "Logistics & Delivery", "name_ar": "لوجستيات", "is_default": true }
]
```

---

### 13.2 Create Category

```
POST /api/v1/{slug}/expense-categories
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "name_en": "Maintenance",
  "name_ar": "صيانة"
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Category created successfully.",
  "data": { "id": 4, "name_en": "Maintenance", "name_ar": "صيانة" }
}
```

---

## 14. Accounts

### 14.1 List Accounts

```
GET /api/v1/{slug}/accounts
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Cash Register",
      "type": "cash",
      "current_balance": "4550.00",
      "opening_balance": "500.00",
      "is_default": true,
      "is_drawer": true
    },
    {
      "id": 2,
      "name": "Business Bank Account",
      "type": "bank",
      "current_balance": "125000.00",
      "opening_balance": "100000.00",
      "is_default": false,
      "is_drawer": false
    }
  ]
}
```

---

### 14.2 Get Account Balance & History

```
GET /api/v1/{slug}/accounts/{id}/history
Authorization: Bearer <token>
```

**Query Parameters:** `from`, `to`, `page`

**Success 200**
```json
{
  "success": true,
  "data": {
    "account": { "id": 1, "name": "Cash Register", "current_balance": "4550.00" },
    "transactions": [
      {
        "id": 1,
        "date": "2026-04-28",
        "type": "pos_sale",
        "direction": "in",
        "amount": "228.00",
        "balance_after": "728.00",
        "description": "POS Order RCP-0145",
        "reference_id": 145,
        "reference_type": "PosOrder"
      }
    ]
  }
}
```

---

### 14.3 Deposit to Account

```
POST /api/v1/{slug}/accounts/deposit
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "account_id": 2,
  "amount": 5000.00,
  "description": "Cash deposit from sales",
  "date": "2026-04-28"
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Deposit recorded successfully.",
  "data": { "account_id": 2, "new_balance": "130000.00" }
}
```

---

### 14.4 Transfer Between Accounts

```
POST /api/v1/{slug}/accounts/transfer
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "from_account_id": 1,
  "to_account_id": 2,
  "amount": 2000.00,
  "description": "Bank deposit from cash",
  "date": "2026-04-28"
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Transfer completed successfully.",
  "data": {
    "from_account": { "id": 1, "name": "Cash Register", "new_balance": "2550.00" },
    "to_account": { "id": 2, "name": "Business Bank Account", "new_balance": "132000.00" }
  }
}
```

**Error 422 — Insufficient funds**
```json
{
  "success": false,
  "message": "Insufficient balance in the source account."
}
```

---

## 15. Inventory / Warehouses

### 15.1 List Inventories

```
GET /api/v1/{slug}/inventories
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Main Warehouse",
      "address": "Industrial Zone, Cairo",
      "is_default": true,
      "products_count": 320
    }
  ]
}
```

---

### 15.2 Get Inventory Products (Stock Levels)

```
GET /api/v1/{slug}/inventories/{id}/products
Authorization: Bearer <token>
```

**Query Parameters:** `search`, `low_stock` (boolean)

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "product_id": 1,
      "product_name": "Laptop Pro 15",
      "sku": "LP-001",
      "quantity": 25,
      "minimum_stock_alert": 5,
      "cost_price": "1200.00",
      "inventory_value": "30000.00",
      "is_low_stock": false
    }
  ]
}
```

---

### 15.3 Adjust Stock

```
PATCH /api/v1/{slug}/inventories/{id}/products/{product}
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "quantity": 30,
  "reason": "Stock count correction"
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Stock adjusted successfully.",
  "data": {
    "product_id": 1,
    "inventory_id": 1,
    "old_quantity": 25,
    "new_quantity": 30,
    "adjustment": 5
  }
}
```

---

## 16. Reports

### 16.1 Trial Balance

```
GET /api/v1/{slug}/reports/trial-balance
Authorization: Bearer <token>
```

**Query Parameters:** `as_of` (date)

**Success 200**
```json
{
  "success": true,
  "data": {
    "as_of": "2026-04-28",
    "accounts": [
      {
        "code": "1100",
        "name": "Cash",
        "type": "asset",
        "debit_balance": "45230.50",
        "credit_balance": "0.00"
      },
      {
        "code": "2000",
        "name": "Accounts Payable",
        "type": "liability",
        "debit_balance": "0.00",
        "credit_balance": "25000.00"
      }
    ],
    "totals": {
      "total_debits": "210000.00",
      "total_credits": "210000.00",
      "is_balanced": true
    }
  }
}
```

---

### 16.2 Income Statement

```
GET /api/v1/{slug}/reports/income-statement
Authorization: Bearer <token>
```

**Query Parameters:** `from`, `to`

**Success 200**
```json
{
  "success": true,
  "data": {
    "period": { "from": "2026-04-01", "to": "2026-04-28" },
    "revenue": {
      "total": "68000.00",
      "breakdown": [
        { "account": "Sales Revenue", "amount": "68000.00" }
      ]
    },
    "cost_of_goods_sold": "42000.00",
    "gross_profit": "26000.00",
    "expenses": {
      "total": "8500.00",
      "breakdown": [
        { "account": "Advertising", "amount": "3000.00" },
        { "account": "Office Expenses", "amount": "5500.00" }
      ]
    },
    "net_income": "17500.00"
  }
}
```

---

### 16.3 Daily Sales Report

```
GET /api/v1/{slug}/reports/daily-sales
Authorization: Bearer <token>
```

**Query Parameters:** `from`, `to`

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "date": "2026-04-28",
      "orders_count": 12,
      "total_sales": "6800.00",
      "total_returns": "200.00",
      "net_sales": "6600.00",
      "cash_sales": "4200.00",
      "credit_sales": "2600.00"
    }
  ]
}
```

---

### 16.4 AR Aging Report

```
GET /api/v1/{slug}/reports/ar-aging
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": {
    "as_of": "2026-04-28",
    "clients": [
      {
        "client_id": 1,
        "client_name": "Mohamed Ali",
        "current": "500.00",
        "days_1_30": "300.00",
        "days_31_60": "200.00",
        "days_61_90": "0.00",
        "over_90": "0.00",
        "total": "1000.00"
      }
    ],
    "totals": {
      "current": "8000.00",
      "days_1_30": "2500.00",
      "days_31_60": "1200.00",
      "days_61_90": "300.00",
      "over_90": "0.00",
      "total": "12000.00"
    }
  }
}
```

---

## 17. Settings — Taxes

### 17.1 List Taxes

```
GET /api/v1/{slug}/settings/taxes
Authorization: Bearer <token>
```

**Success 200**
```json
[
  {
    "id": 1,
    "name": "VAT 14%",
    "name_ar": "ضريبة القيمة المضافة 14%",
    "rate": "14.00",
    "is_compound": false,
    "is_default": true
  },
  {
    "id": 2,
    "name": "VAT 5%",
    "name_ar": "ضريبة القيمة المضافة 5%",
    "rate": "5.00",
    "is_compound": false,
    "is_default": false
  }
]
```

---

### 17.2 Get Tax Config

```
GET /api/v1/{slug}/settings/tax-config
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "tax_inclusive": false,
  "default_tax_id": 1,
  "show_tax_on_receipt": true
}
```

---

## 18. Settings — Payment Methods

### 18.1 List Payment Methods

```
GET /api/v1/{slug}/settings/payment-methods
Authorization: Bearer <token>
```

**Success 200**
```json
[
  {
    "id": 1,
    "name": "Cash",
    "name_ar": "نقدي",
    "is_active": true,
    "is_default": true,
    "account_id": 1
  },
  {
    "id": 2,
    "name": "Card",
    "name_ar": "بطاقة",
    "is_active": true,
    "is_default": false,
    "account_id": 2
  }
]
```

---

### 18.2 POS Active Payment Methods

```
GET /api/v1/{slug}/payment-methods/active
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": [
    { "id": 1, "name": "Cash", "name_ar": "نقدي", "account_id": 1 },
    { "id": 2, "name": "Card", "name_ar": "بطاقة", "account_id": 2 }
  ]
}
```

---

## 19. Settings — Currencies

### 19.1 List Currencies

```
GET /api/v1/{slug}/settings/currencies
Authorization: Bearer <token>
```

**Success 200**
```json
[
  {
    "id": 1,
    "code": "EGP",
    "name": "Egyptian Pound",
    "symbol": "ج.م",
    "is_default": true,
    "exchange_rate": "1.000000"
  },
  {
    "id": 2,
    "code": "USD",
    "name": "US Dollar",
    "symbol": "$",
    "is_default": false,
    "exchange_rate": "48.500000"
  }
]
```

---

## 20. Employees (Users)

### 20.1 List Employees

```
GET /api/v1/{slug}/employees
Authorization: Bearer <token>
```

**Success 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 12,
      "name": "Ahmed Hesham",
      "email": "ahmed@myshop.com",
      "phone": "01012345678",
      "is_active": true,
      "last_login_at": "2026-04-28T08:00:00Z",
      "role": { "id": 1, "name": "Admin" }
    },
    {
      "id": 15,
      "name": "Sara Kamal",
      "email": "sara@myshop.com",
      "phone": "01098765432",
      "is_active": true,
      "last_login_at": "2026-04-27T17:00:00Z",
      "role": { "id": 3, "name": "Cashier" }
    }
  ]
}
```

---

### 20.2 Create Employee

```
POST /api/v1/{slug}/employees
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "name": "Omar Farid",
  "email": "omar@myshop.com",
  "password": "Temp1234!",
  "password_confirmation": "Temp1234!",
  "phone": "01055556666",
  "role_id": 3
}
```

**Success 201**
```json
{
  "success": true,
  "message": "Employee created successfully.",
  "data": {
    "id": 20,
    "name": "Omar Farid",
    "email": "omar@myshop.com",
    "is_active": true,
    "role": { "id": 3, "name": "Cashier" }
  }
}
```

**Error 422**
```json
{
  "message": "The email has already been taken.",
  "errors": {
    "email": ["The email has already been taken."]
  }
}
```

---

### 20.3 Update Employee Status

```
PATCH /api/v1/{slug}/employees/{id}/status
Authorization: Bearer <token>
```

**Request Body**
```json
{
  "is_active": false
}
```

**Success 200**
```json
{
  "success": true,
  "message": "Employee status updated.",
  "data": { "id": 20, "is_active": false }
}
```

---

## Common Error Responses

### 401 — Token expired or missing
```json
{
  "message": "Unauthenticated."
}
```

### 403 — No permission
```json
{
  "success": false,
  "message": "You do not have permission to perform this action."
}
```

### 404 — Resource not found
```json
{
  "success": false,
  "message": "Resource not found."
}
```

### 422 — Validation (field errors)
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "field_name": [
      "Human-readable error message."
    ]
  }
}
```

### 500 — Server error
```json
{
  "success": false,
  "message": "Server error (500). Please try again."
}
```

### Network error (no response body)
Handled client-side — `ApiException.Network` is thrown when the request itself fails to complete.

---

## Authentication Flow Summary

```
1. POST /api/v1/login
   → receive token + user.tenant.slug

2. All subsequent requests:
   Authorization: Bearer <token>
   URL prefix: /api/v1/{tenant_slug}/

3. On 401 response:
   → Clear stored token
   → Redirect to login screen

4. On 403 response:
   → Show "Permission denied" error
   → Do NOT clear token (user is still authenticated)
```

---

*Last updated: 2026-04-28 | Operix API v1*
