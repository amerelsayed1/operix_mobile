package me.amermahsoub.bfm.shared.data.api

/**
 * All Operix API paths. Paths are relative to /api/v1/{slug}/.
 */
object OperixApiPaths {
    // Dashboard
    const val DASHBOARD = "dashboard"
    const val DASHBOARD_KPIS = "dashboard/kpis"
    const val DASHBOARD_LOW_STOCK = "dashboard/lists/low-stock"
    const val DASHBOARD_RECENT_ORDERS = "dashboard/lists/recent-orders"

    // Products
    const val PRODUCTS = "products"
    fun product(id: Int) = "products/$id"
    fun productRestore(id: Int) = "products/$id/restore"
    const val PRODUCT_CATEGORIES = "product-categories"
    fun productCategory(id: Int) = "product-categories/$id"
    const val UNITS = "units"
    fun unit(id: Int) = "units/$id"

    // Inventory
    const val INVENTORIES = "inventories"
    fun inventory(id: Int) = "inventories/$id"
    fun inventoryProducts(id: Int) = "inventories/$id/products"
    const val STOCK_MOVEMENTS = "stock-movements"
    const val STOCK_TRANSFERS = "stock-transfers"
    fun stockTransfer(id: Int) = "stock-transfers/$id"
    const val INVENTORY_COUNTS = "inventory-counts"
    fun inventoryCount(id: Int) = "inventory-counts/$id"
    fun inventoryCountApprove(id: Int) = "inventory-counts/$id/approve"

    // Clients
    const val CLIENTS = "clients"
    fun client(id: Int) = "clients/$id"

    // Suppliers
    const val SUPPLIERS = "suppliers"
    fun supplier(id: Int) = "suppliers/$id"

    // Sales Invoices
    const val SALES_INVOICES = "sales-invoices"
    fun salesInvoice(id: Int) = "sales-invoices/$id"
    fun salesInvoicePost(id: Int) = "sales-invoices/$id/post"
    fun salesInvoiceCancel(id: Int) = "sales-invoices/$id/cancel"
    fun salesInvoicePayments(id: Int) = "sales-invoices/$id/payments"
    const val SALES_RETURNS = "sales-returns"

    // Purchase Invoices
    const val PURCHASE_INVOICES = "purchase-invoices"
    fun purchaseInvoice(id: Int) = "purchase-invoices/$id"
    fun purchaseInvoicePost(id: Int) = "purchase-invoices/$id/post"
    fun purchaseInvoiceCancel(id: Int) = "purchase-invoices/$id/cancel"
    const val SUPPLIER_PAYMENTS = "supplier-payments"

    // POS
    const val POS_TERMINALS = "pos/terminals"
    fun posTerminal(id: Int) = "pos/terminals/$id"
    fun posTerminalCurrentShift(id: Int) = "pos/terminals/$id/current-shift"
    const val POS_SHIFTS = "pos/shifts"
    fun posShift(id: Int) = "pos/shifts/$id"
    fun posShiftClose(id: Int) = "pos/shifts/$id/close"
    fun posShiftSummary(id: Int) = "pos/shifts/$id/summary"
    const val POS_ORDERS = "pos/orders"
    fun posOrder(id: Int) = "pos/orders/$id"
    fun posOrderRefund(id: Int) = "pos/orders/$id/refund"
    const val POS_BARCODE = "pos/products/barcode"
    const val POS_SEARCH = "pos/products/search"

    // Accounts & GL
    const val ACCOUNTS = "accounts"
    fun account(id: Int) = "accounts/$id"
    const val GL_ACCOUNTS = "gl-accounts"
    fun glAccount(id: Int) = "gl-accounts/$id"
    const val JOURNAL_ENTRIES = "journal-entries"
    fun journalEntry(id: Int) = "journal-entries/$id"
    const val PAYMENT_METHODS = "payment-methods"
    const val ACCOUNTING_PERIODS = "accounting-periods"

    // Expenses
    const val EXPENSES = "expenses"
    fun expense(id: Int) = "expenses/$id"
    const val EXPENSE_CATEGORIES = "expense-categories"

    // Reports
    const val REPORT_PROFIT_LOSS = "reports/profit-loss"
    const val REPORT_TRIAL_BALANCE = "reports/trial-balance"
    const val REPORT_BALANCE_SHEET = "reports/balance-sheet"
    const val REPORT_SALES = "reports/sales"
    const val REPORT_EXPENSES = "reports/expenses"
    const val REPORT_INVENTORY_VALUATION = "reports/inventory-valuation"
    const val REPORT_POS_SALES = "reports/pos-sales"
    const val REPORT_RECEIVABLES_AGING = "reports/receivables-aging"
    const val REPORT_PAYABLES_AGING = "reports/payables-aging"
    const val REPORT_CLIENT_STATEMENT = "reports/client-statement"
    const val REPORT_SUPPLIER_STATEMENT = "reports/supplier-statement"
    const val REPORT_ACCOUNT_STATEMENT = "reports/account-statement"

    // Users / Employees
    const val USERS = "users"
    fun user(id: Int) = "users/$id"
    const val ROLES = "roles"

    // Settings
    const val BRANCHES = "branches"
    const val SETTINGS_ACCOUNTING = "settings/accounting"
    const val SETTINGS_INVOICE = "settings/invoice"
}
