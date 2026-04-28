package me.amermahsoub.bfm.shared.data.api

/**
 * All Operix API paths. Paths are relative to /api/v1/{slug}/.
 * Matches the routes defined in the Operix Laravel backend.
 */
object OperixApiPaths {

    // ── Dashboard ─────────────────────────────────────────────────────────
    const val DASHBOARD         = "dashboard"
    const val DASHBOARD_KPIS    = "dashboard/kpis"
    const val DASHBOARD_SALES_TREND    = "dashboard/charts/sales-trend"
    const val DASHBOARD_TOP_PRODUCTS   = "dashboard/charts/top-products"
    const val DASHBOARD_LOW_STOCK      = "dashboard/lists/low-stock"
    const val DASHBOARD_RECENT_ORDERS  = "dashboard/lists/recent-orders"

    // ── Products ──────────────────────────────────────────────────────────
    const val PRODUCTS          = "products"
    const val PRODUCT_NEXT_CODES = "products/next-codes"
    fun product(id: Int)        = "products/$id"

    // ── Product categories ────────────────────────────────────────────────
    const val PRODUCT_CATEGORIES = "product-categories"
    fun productCategory(id: Int) = "product-categories/$id"

    // ── Settings — Units ──────────────────────────────────────────────────
    const val SETTINGS_UNITS    = "settings/units"
    fun settingsUnit(id: Int)   = "settings/units/$id"

    // ── Settings — Taxes ──────────────────────────────────────────────────
    const val SETTINGS_TAXES      = "settings/taxes"
    fun settingsTax(id: Int)      = "settings/taxes/$id"
    const val SETTINGS_TAX_CONFIG = "settings/tax-config"

    // ── Settings — Payment methods ────────────────────────────────────────
    const val SETTINGS_PAYMENT_METHODS = "settings/payment-methods"
    fun settingsPaymentMethod(id: Int) = "settings/payment-methods/$id"
    /** Active payment methods used by POS */
    const val PAYMENT_METHODS_ACTIVE   = "payment-methods/active"

    // ── Settings — Currencies ─────────────────────────────────────────────
    const val SETTINGS_CURRENCIES = "settings/currencies"
    fun settingsCurrency(id: Int)  = "settings/currencies/$id"

    // ── Inventory / Warehouses ────────────────────────────────────────────
    const val INVENTORIES        = "inventories"
    fun inventory(id: Int)       = "inventories/$id"
    fun inventoryProducts(id: Int) = "inventories/$id/products"
    fun inventoryProductAdjust(invId: Int, productId: Int) = "inventories/$invId/products/$productId"
    const val STOCK_MOVEMENTS    = "stock-movements"
    const val STOCK_TRANSFERS    = "stock-transfers"
    fun stockTransfer(id: Int)   = "stock-transfers/$id"
    const val INVENTORY_COUNTS   = "inventory-counts"
    fun inventoryCount(id: Int)  = "inventory-counts/$id"
    fun inventoryCountApprove(id: Int) = "inventory-counts/$id/approve"

    // ── Clients ───────────────────────────────────────────────────────────
    const val CLIENTS            = "clients"
    fun client(id: Int)          = "clients/$id"
    fun clientStatement(id: Int) = "clients/$id/statement"
    fun clientOrders(id: Int)    = "clients/$id/orders"
    fun clientPayments(id: Int)  = "clients/$id/payments"

    // ── Suppliers ─────────────────────────────────────────────────────────
    const val SUPPLIERS          = "suppliers"
    fun supplier(id: Int)        = "suppliers/$id"
    fun supplierLedger(id: Int)  = "suppliers/$id/ledger"
    fun supplierInvoices(id: Int) = "suppliers/$id/invoices"
    fun supplierPayments(id: Int) = "suppliers/$id/payments"

    // ── Sales Invoices ────────────────────────────────────────────────────
    const val SALES_INVOICES     = "sales-invoices"
    fun salesInvoice(id: Int)    = "sales-invoices/$id"
    fun salesInvoicePost(id: Int)    = "sales-invoices/$id/post"
    fun salesInvoiceCancel(id: Int)  = "sales-invoices/$id/cancel"
    fun salesInvoicePayment(id: Int) = "sales-invoices/$id/record-payment"
    const val SALES_RETURNS      = "sales-returns"

    // ── Purchase Invoices ─────────────────────────────────────────────────
    const val PURCHASE_INVOICES  = "purchase-invoices"
    fun purchaseInvoice(id: Int) = "purchase-invoices/$id"
    fun purchaseInvoicePost(id: Int)    = "purchase-invoices/$id/post"
    fun purchaseInvoiceCancel(id: Int)  = "purchase-invoices/$id/cancel"
    fun purchaseInvoicePayment(id: Int) = "purchase-invoices/$id/payment"
    const val SUPPLIER_PAYMENTS  = "supplier-payments"
    fun supplierPayment(id: Int) = "supplier-payments/$id"

    // ── POS — Shifts ──────────────────────────────────────────────────────
    const val POS_SHIFT_OPEN          = "pos/shift/open"
    const val POS_SHIFT_CURRENT       = "pos/shift/current"
    const val POS_SHIFT_CLOSE         = "pos/shift/close"
    const val POS_SHIFT_SUMMARY       = "pos/shift/summary"
    const val POS_SHIFT_CASH_MOVEMENTS = "pos/shift/cash-movements"
    fun posCashMovementReverse(id: Int) = "pos/shift/cash-movements/$id/reverse"
    const val POS_SHIFT_HISTORY       = "pos/shift/history"
    fun posShift(id: Int)             = "pos/shifts/$id"

    // ── POS — Terminals ───────────────────────────────────────────────────
    const val POS_TERMINALS      = "pos/terminals"
    fun posTerminal(id: Int)     = "pos/terminals/$id"

    // ── POS — Orders ──────────────────────────────────────────────────────
    const val POS_ORDERS         = "pos-orders"
    fun posOrder(id: Int)        = "pos-orders/$id"
    fun posOrderReceipt(id: Int) = "pos-orders/$id/receipt"
    fun posOrderReturn(id: Int)  = "pos-orders/$id/return"

    // ── POS — Product lookup ──────────────────────────────────────────────
    const val POS_PRODUCTS       = "pos/products"
    const val POS_BARCODE        = "pos/products"   // append ?barcode=… in code
    const val POS_SEARCH         = "pos/products/search"

    // ── Accounts ─────────────────────────────────────────────────────────
    const val ACCOUNTS           = "accounts"
    fun account(id: Int)         = "accounts/$id"
    fun accountHistory(id: Int)  = "accounts/$id/history"
    const val ACCOUNTS_DEPOSIT   = "accounts/deposit"
    const val ACCOUNTS_WITHDRAW  = "accounts/withdraw"
    const val ACCOUNTS_TRANSFER  = "accounts/transfer"

    // ── GL / Journal entries ──────────────────────────────────────────────
    const val GL_ACCOUNTS        = "gl-accounts"
    fun glAccount(id: Int)       = "gl-accounts/$id"
    const val JOURNAL_ENTRIES    = "journal-entries"
    fun journalEntry(id: Int)    = "journal-entries/$id"
    fun journalEntryReverse(id: Int) = "journal-entries/$id/reverse"

    // ── Accounting periods ────────────────────────────────────────────────
    const val ACCOUNTING_PERIODS = "accounting-periods"
    fun accountingPeriod(id: Int) = "accounting-periods/$id"

    // ── Expenses ──────────────────────────────────────────────────────────
    const val EXPENSES           = "expenses"
    fun expense(id: Int)         = "expenses/$id"
    const val EXPENSE_CATEGORIES = "expense-categories"
    fun expenseCategory(id: Int) = "expense-categories/$id"

    // ── Employees ─────────────────────────────────────────────────────────
    const val EMPLOYEES          = "employees"
    fun employee(id: Int)        = "employees/$id"
    fun employeeStatus(id: Int)  = "employees/$id/status"
    const val ROLES              = "settings/roles"

    // ── Branches ──────────────────────────────────────────────────────────
    const val BRANCHES           = "branches"
    fun branch(id: Int)          = "branches/$id"

    // ── Reports ───────────────────────────────────────────────────────────
    const val REPORT_TRIAL_BALANCE      = "reports/trial-balance"
    const val REPORT_INCOME_STATEMENT   = "reports/income-statement"
    const val REPORT_BALANCE_SHEET      = "reports/balance-sheet"
    const val REPORT_CASH_FLOW          = "reports/cash-flow"
    const val REPORT_GENERAL_LEDGER     = "reports/general-ledger"
    const val REPORT_DAILY_SALES        = "reports/daily-sales"
    const val REPORT_MONTHLY_SALES      = "reports/monthly-sales"
    const val REPORT_PRODUCT_SALES      = "reports/product-sales"
    const val REPORT_PRODUCT_PROFIT     = "reports/product-profit"
    const val REPORT_AR_AGING           = "reports/ar-aging"
    const val REPORT_AP_AGING           = "reports/ap-aging"
    const val REPORT_OUTSTANDING_INVOICES = "reports/outstanding-invoices"
    const val REPORT_SALES_RETURNS      = "reports/sales-returns"
    const val REPORT_NET_SALES          = "reports/net-sales"
    const val REPORT_INVENTORY_VALUATION = "reports/inventory-valuation"
    const val REPORT_POS_SHIFT_VARIANCE = "reports/pos-shift-variance"
    const val REPORT_EXPENSES           = "reports/expenses"

    // ── Settings — misc ───────────────────────────────────────────────────
    const val SETTINGS_COMPANY          = "settings/company"
    const val SETTINGS_ACCOUNTING       = "accounting-settings"
    const val SETTINGS_INVOICE          = "settings/invoice"
    const val SETTINGS_RECEIPT          = "settings/receipt"
}
