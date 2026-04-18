package me.amermahsoub.bfm

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.engine.mock.respondError
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf

/**
 * In-process fake backend: a Ktor [MockEngine] that matches the URL paths the
 * screenshot tour hits and returns canned JSON. Everything lives in one file
 * so it's obvious what data each screen will render.
 *
 * Request paths are matched loosely (`endsWith` / `contains`) so query strings,
 * trailing slashes, and tenant slugs don't break the match.
 */
internal object FakeBackend {

    fun engine(): HttpClientEngine = MockEngine { request ->
        val path = request.url.encodedPath
        val body = route(path)
        if (body != null) {
            respond(
                content = body,
                status = HttpStatusCode.OK,
                headers = headersOf(HttpHeaders.ContentType, "application/json"),
            )
        } else {
            // Unknown path: 404 so the app's runCatching wrappers just
            // fall through to empty state instead of hanging.
            respondError(HttpStatusCode.NotFound)
        }
    }

    @Suppress("CyclomaticComplexMethod", "LongMethod")
    private fun route(path: String): String? = when {
        // --- Dashboard ------------------------------------------------------
        path.endsWith("/dashboard") -> DASHBOARD_SUMMARY
        path.endsWith("/dashboard/lists/low-stock") -> LOW_STOCK
        path.endsWith("/dashboard/lists/recent-orders") -> RECENT_ORDERS
        path.endsWith("/dashboard/charts/top-products") -> TOP_PRODUCTS

        // --- POS reference data --------------------------------------------
        path.endsWith("/pos/products") -> POS_PRODUCTS
        path.endsWith("/pos/payment-methods") -> PAYMENT_METHODS
        path.endsWith("/pos/accounts") -> POS_ACCOUNTS
        path.endsWith("/pos/taxes") -> TAXES
        path.endsWith("/pos/shift/current") -> CURRENT_SHIFT
        path.endsWith("/pos/shift/available-drawers") -> POS_ACCOUNTS
        path.endsWith("/pos/shift/summary") -> SHIFT_SUMMARY
        path.endsWith("/pos/shift/history") -> SHIFT_HISTORY
        path.endsWith("/pos-orders") -> POS_ORDERS

        // --- Clients -------------------------------------------------------
        path.endsWith("/clients") -> CLIENTS
        path.endsWith("/clients/summary") -> CLIENTS_SUMMARY

        // --- Products & Inventory -----------------------------------------
        path.endsWith("/products") -> PRODUCTS
        path.endsWith("/product-categories") -> PRODUCT_CATEGORIES
        path.endsWith("/inventories") -> INVENTORIES
        path.endsWith("/inventories/default") -> DEFAULT_INVENTORY

        // --- Accounts & Expenses ------------------------------------------
        path.endsWith("/accounts") -> ACCOUNTS
        path.endsWith("/expenses") -> EXPENSES
        path.endsWith("/expense-categories") -> EXPENSE_CATEGORIES

        // --- Profile -------------------------------------------------------
        path.endsWith("/profile") -> PROFILE

        else -> null
    }

    // -------------------------------------------------------------------------
    // Canned payloads. All responses use Laravel's `{data: ...}` envelope so
    // the app's `decodeData` / `decodePaginated` helpers pick them up cleanly.
    // -------------------------------------------------------------------------

    private val DASHBOARD_SUMMARY = """
        {
          "data": {
            "total_balance": "45,320.50",
            "total_revenue": "12,845.00",
            "total_expenses": "2,140.75",
            "total_purchases": "5,120.00",
            "total_returns": "320.00",
            "returns_count": 3,
            "net_profit": "10,704.25",
            "currency": "USD"
          }
        }
    """.trimIndent()

    private val LOW_STOCK = """
        {
          "data": [
            {"id": 101, "name": "Cola 330ml", "sku": "BEV-001", "available_qty": 4, "minimum_qty": 20},
            {"id": 102, "name": "Potato Chips (Large)", "sku": "SNK-014", "available_qty": 2, "minimum_qty": 15},
            {"id": 103, "name": "Whole Grain Bread", "sku": "BAK-022", "available_qty": 0, "minimum_qty": 10}
          ]
        }
    """.trimIndent()

    private val RECENT_ORDERS = """
        {
          "data": [
            {"id": 9021, "receipt_number": "OR-2026-9021", "customer": "Sara Ahmad", "total": "48.20", "status": "paid", "created_at": "2026-04-15T09:14:00Z"},
            {"id": 9020, "receipt_number": "OR-2026-9020", "customer": "Walk-in", "total": "12.75", "status": "paid", "created_at": "2026-04-15T08:56:00Z"},
            {"id": 9019, "receipt_number": "OR-2026-9019", "customer": "Omar Khalid", "total": "134.00", "status": "partial", "created_at": "2026-04-15T08:41:00Z"},
            {"id": 9018, "receipt_number": "OR-2026-9018", "customer": "Walk-in", "total": "7.50", "status": "paid", "created_at": "2026-04-15T08:22:00Z"},
            {"id": 9017, "receipt_number": "OR-2026-9017", "customer": "Layla Hassan", "total": "61.25", "status": "paid", "created_at": "2026-04-15T08:04:00Z"}
          ]
        }
    """.trimIndent()

    private val TOP_PRODUCTS = """
        {
          "data": [
            {"id": 201, "name": "Cappuccino", "revenue": "842.00", "units_sold": 112, "category": "Beverages"},
            {"id": 202, "name": "Chicken Shawarma", "revenue": "615.50", "units_sold": 41, "category": "Food"},
            {"id": 203, "name": "Fresh Orange Juice", "revenue": "380.25", "units_sold": 67, "category": "Beverages"},
            {"id": 204, "name": "Falafel Wrap", "revenue": "298.00", "units_sold": 38, "category": "Food"}
          ]
        }
    """.trimIndent()

    private val POS_PRODUCTS = """
        {
          "data": [
            {"id": 201, "name": "Cappuccino", "sku": "BEV-CAP", "selling_price": "3.50", "current_stock": 120, "category": "Beverages", "is_active": true},
            {"id": 202, "name": "Espresso", "sku": "BEV-ESP", "selling_price": "2.25", "current_stock": 80, "category": "Beverages", "is_active": true},
            {"id": 203, "name": "Fresh Orange Juice", "sku": "BEV-OJ", "selling_price": "4.00", "current_stock": 45, "category": "Beverages", "is_active": true},
            {"id": 204, "name": "Chicken Shawarma", "sku": "FOD-SHA", "selling_price": "8.50", "current_stock": 30, "category": "Food", "is_active": true},
            {"id": 205, "name": "Falafel Wrap", "sku": "FOD-FAL", "selling_price": "6.25", "current_stock": 25, "category": "Food", "is_active": true},
            {"id": 206, "name": "Greek Salad", "sku": "FOD-GRK", "selling_price": "7.00", "current_stock": 18, "category": "Food", "is_active": true},
            {"id": 207, "name": "Chocolate Croissant", "sku": "BAK-CHC", "selling_price": "2.75", "current_stock": 22, "category": "Bakery", "is_active": true},
            {"id": 208, "name": "Iced Latte", "sku": "BEV-ICL", "selling_price": "4.25", "current_stock": 60, "category": "Beverages", "is_active": true}
          ],
          "meta": {"current_page": 1, "last_page": 1, "per_page": 15, "total": 8}
        }
    """.trimIndent()

    private val PAYMENT_METHODS = """
        {
          "data": [
            {"id": 1, "name": "Cash", "code": "cash", "requires_account": true, "is_active": true},
            {"id": 2, "name": "Card", "code": "card", "requires_account": true, "is_active": true},
            {"id": 3, "name": "Bank Transfer", "code": "bank_transfer", "requires_account": true, "is_active": true}
          ]
        }
    """.trimIndent()

    private val POS_ACCOUNTS = """
        {
          "data": [
            {"id": 1, "name": "Front Register", "type": "cash", "current_balance": "820.00", "is_drawer": true},
            {"id": 2, "name": "Main Bank", "type": "bank", "current_balance": "42,180.50", "is_drawer": false}
          ]
        }
    """.trimIndent()

    private val TAXES = """
        {
          "data": [
            {"id": 1, "name": "VAT 15%", "rate": 15.0, "code": "vat_15"},
            {"id": 2, "name": "No Tax", "rate": 0.0, "code": "none"}
          ]
        }
    """.trimIndent()

    private val CURRENT_SHIFT = """
        {
          "data": {
            "id": 4412,
            "terminal_id": 1,
            "drawer_account_id": 1,
            "status": "open",
            "opened_at": "2026-04-15T07:30:00Z",
            "opened_by": "Demo Owner",
            "opening_cash": "200.00",
            "expected_cash": "820.00"
          }
        }
    """.trimIndent()

    private val SHIFT_SUMMARY = """
        {
          "data": {
            "total_sales": "3,428.75",
            "total_orders": 42,
            "cash_in": "120.00",
            "cash_out": "35.00",
            "expected_cash": "820.00"
          }
        }
    """.trimIndent()

    private val SHIFT_HISTORY = """
        {
          "data": [
            {"id": 4411, "status": "closed", "opened_at": "2026-04-14T07:30:00Z", "closed_at": "2026-04-14T22:05:00Z", "opened_by": "Demo Owner", "counted_cash": "1,245.50"},
            {"id": 4410, "status": "closed", "opened_at": "2026-04-13T07:28:00Z", "closed_at": "2026-04-13T22:12:00Z", "opened_by": "Demo Owner", "counted_cash": "1,108.75"},
            {"id": 4409, "status": "closed", "opened_at": "2026-04-12T07:33:00Z", "closed_at": "2026-04-12T22:01:00Z", "opened_by": "Demo Owner", "counted_cash": "980.00"}
          ],
          "meta": {"current_page": 1, "last_page": 1, "per_page": 20, "total": 3}
        }
    """.trimIndent()

    private val POS_ORDERS = """
        {
          "data": [
            {"id": 9021, "receipt_number": "OR-2026-9021", "client_name": "Sara Ahmad", "grand_total": "48.20", "paid_amount": "48.20", "due_amount": "0.00", "payment_status": "paid", "status": "completed", "created_at": "2026-04-15T09:14:00Z"},
            {"id": 9020, "receipt_number": "OR-2026-9020", "client_name": "Walk-in", "grand_total": "12.75", "paid_amount": "12.75", "due_amount": "0.00", "payment_status": "paid", "status": "completed", "created_at": "2026-04-15T08:56:00Z"},
            {"id": 9019, "receipt_number": "OR-2026-9019", "client_name": "Omar Khalid", "grand_total": "134.00", "paid_amount": "100.00", "due_amount": "34.00", "payment_status": "partial", "status": "completed", "created_at": "2026-04-15T08:41:00Z"}
          ],
          "meta": {"current_page": 1, "last_page": 1, "per_page": 20, "total": 3}
        }
    """.trimIndent()

    private val CLIENTS = """
        {
          "data": [
            {"id": 301, "name": "Sara Ahmad", "phone": "+971 50 123 4567", "email": "sara@example.com", "balance": "0.00", "credit_limit": "500.00", "is_blocked": false},
            {"id": 302, "name": "Omar Khalid", "phone": "+971 52 987 6543", "email": "omar@example.com", "balance": "34.00", "credit_limit": "1000.00", "is_blocked": false},
            {"id": 303, "name": "Layla Hassan", "phone": "+971 54 555 2211", "email": "layla@example.com", "balance": "120.50", "credit_limit": "750.00", "is_blocked": false},
            {"id": 304, "name": "Khalid Nasser", "phone": "+971 55 444 8899", "email": "khalid@example.com", "balance": "0.00", "credit_limit": "500.00", "is_blocked": false},
            {"id": 305, "name": "Fatima Yousef", "phone": "+971 50 777 3344", "email": "fatima@example.com", "balance": "62.25", "credit_limit": "600.00", "is_blocked": false},
            {"id": 306, "name": "Ahmed Rashid", "phone": "+971 58 222 1100", "email": "ahmed@example.com", "balance": "0.00", "credit_limit": "500.00", "is_blocked": true}
          ],
          "meta": {"current_page": 1, "last_page": 1, "per_page": 20, "total": 6}
        }
    """.trimIndent()

    private val CLIENTS_SUMMARY = """
        {
          "data": {
            "total_receivables": "216.75",
            "overdue": "34.00",
            "clients_count": 6
          }
        }
    """.trimIndent()

    private val PRODUCTS = """
        {
          "data": [
            {"id": 201, "name": "Cappuccino", "sku": "BEV-CAP", "selling_price": "3.50", "current_stock": 120, "category": "Beverages", "is_active": true, "minimum_qty": 20},
            {"id": 202, "name": "Espresso", "sku": "BEV-ESP", "selling_price": "2.25", "current_stock": 80, "category": "Beverages", "is_active": true, "minimum_qty": 20},
            {"id": 203, "name": "Fresh Orange Juice", "sku": "BEV-OJ", "selling_price": "4.00", "current_stock": 45, "category": "Beverages", "is_active": true, "minimum_qty": 10},
            {"id": 204, "name": "Chicken Shawarma", "sku": "FOD-SHA", "selling_price": "8.50", "current_stock": 30, "category": "Food", "is_active": true, "minimum_qty": 10},
            {"id": 205, "name": "Falafel Wrap", "sku": "FOD-FAL", "selling_price": "6.25", "current_stock": 25, "category": "Food", "is_active": true, "minimum_qty": 10},
            {"id": 206, "name": "Greek Salad", "sku": "FOD-GRK", "selling_price": "7.00", "current_stock": 18, "category": "Food", "is_active": true, "minimum_qty": 8},
            {"id": 101, "name": "Cola 330ml", "sku": "BEV-001", "selling_price": "1.50", "current_stock": 4, "category": "Beverages", "is_active": true, "minimum_qty": 20},
            {"id": 102, "name": "Potato Chips (Large)", "sku": "SNK-014", "selling_price": "2.00", "current_stock": 2, "category": "Snacks", "is_active": true, "minimum_qty": 15},
            {"id": 103, "name": "Whole Grain Bread", "sku": "BAK-022", "selling_price": "3.25", "current_stock": 0, "category": "Bakery", "is_active": true, "minimum_qty": 10}
          ],
          "meta": {"current_page": 1, "last_page": 1, "per_page": 20, "total": 9}
        }
    """.trimIndent()

    private val PRODUCT_CATEGORIES = """
        {
          "data": [
            {"id": 1, "name": "Beverages"},
            {"id": 2, "name": "Food"},
            {"id": 3, "name": "Bakery"},
            {"id": 4, "name": "Snacks"}
          ]
        }
    """.trimIndent()

    private val INVENTORIES = """
        {
          "data": [
            {"id": 1, "name": "Main Store", "is_default": true, "products_count": 48, "total_stock": 1247},
            {"id": 2, "name": "Warehouse", "is_default": false, "products_count": 32, "total_stock": 4310}
          ],
          "meta": {"current_page": 1, "last_page": 1, "per_page": 20, "total": 2}
        }
    """.trimIndent()

    private val DEFAULT_INVENTORY = """
        {"data": {"id": 1, "name": "Main Store", "is_default": true}}
    """.trimIndent()

    private val ACCOUNTS = """
        {
          "data": [
            {"id": 1, "name": "Front Register", "type": "cash", "current_balance": "820.00", "is_default": false},
            {"id": 2, "name": "Main Bank", "type": "bank", "current_balance": "42,180.50", "is_default": true},
            {"id": 3, "name": "Petty Cash", "type": "cash", "current_balance": "320.00", "is_default": false},
            {"id": 4, "name": "Card Processor", "type": "gateway", "current_balance": "2,000.00", "is_default": false}
          ]
        }
    """.trimIndent()

    private val EXPENSES = """
        {
          "data": [
            {"id": 501, "category": "Rent", "amount": "1,200.00", "date": "2026-04-01", "description": "Monthly storefront rent", "account_id": 2, "account_name": "Main Bank"},
            {"id": 502, "category": "Utilities", "amount": "180.50", "date": "2026-04-03", "description": "Electricity", "account_id": 2, "account_name": "Main Bank"},
            {"id": 503, "category": "Supplies", "amount": "95.25", "date": "2026-04-10", "description": "Coffee beans", "account_id": 1, "account_name": "Front Register"},
            {"id": 504, "category": "Marketing", "amount": "250.00", "date": "2026-04-12", "description": "Social media ads", "account_id": 2, "account_name": "Main Bank"},
            {"id": 505, "category": "Maintenance", "amount": "415.00", "date": "2026-04-14", "description": "Fridge repair", "account_id": 2, "account_name": "Main Bank"}
          ],
          "meta": {"current_page": 1, "last_page": 1, "per_page": 20, "total": 5}
        }
    """.trimIndent()

    private val EXPENSE_CATEGORIES = """
        {
          "data": [
            {"id": 1, "name": "Rent"},
            {"id": 2, "name": "Utilities"},
            {"id": 3, "name": "Supplies"},
            {"id": 4, "name": "Marketing"},
            {"id": 5, "name": "Maintenance"},
            {"id": 6, "name": "Salaries"}
          ]
        }
    """.trimIndent()

    private val PROFILE = """
        {
          "data": {
            "id": 1,
            "name": "Demo Owner",
            "email": "owner@operix.app",
            "phone": "+1 555 555 0123",
            "role": "Owner",
            "locale": "en"
          }
        }
    """.trimIndent()
}
