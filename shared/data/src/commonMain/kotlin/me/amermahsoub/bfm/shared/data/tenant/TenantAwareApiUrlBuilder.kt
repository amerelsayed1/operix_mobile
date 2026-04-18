package me.amermahsoub.bfm.shared.data.tenant

/**
 * Builds tenant-aware URLs for all API calls. Base URL is normalized per
 * platform (e.g. Android emulator rewrites `localhost` to `10.0.2.2`).
 *
 * Every URL beneath the `/api/v1/{tenant_slug}/` prefix requires a selected
 * tenant. Public endpoints (tenant-config) accept an explicit slug.
 */
class TenantAwareApiUrlBuilder(
    baseUrl: String,
    private val tenantContext: TenantContext,
) {
    private val normalizedBaseUrl = normalizeTenantBaseUrl(baseUrl).removeSuffix("/")

    private fun activeSlug(): String =
        tenantContext.tenantSlug.value ?: error("Tenant slug is not selected")

    private fun tenant(path: String, slug: String = activeSlug()): String =
        "$normalizedBaseUrl/api/v1/$slug/${path.trimStart('/')}"

    // --- Public / bootstrap ----------------------------------------------
    fun publicTenantConfig(slug: String): String =
        "$normalizedBaseUrl/api/v1/tenant-config/$slug"

    fun systemConfig(slug: String = activeSlug()): String = tenant("system/config", slug)
    fun bootstrap(slug: String): String = systemConfig(slug)
    fun login(slug: String = activeSlug()): String = tenant("login", slug)
    fun logout(slug: String = activeSlug()): String = tenant("logout", slug)
    fun forgotPassword(): String = "$normalizedBaseUrl/api/v1/auth/forgot-password"

    // --- Session ---------------------------------------------------------
    fun me(slug: String = activeSlug()): String = tenant("me", slug)
    fun permissions(slug: String = activeSlug()): String = tenant("me/permissions", slug)
    fun config(slug: String = activeSlug()): String = tenant("config", slug)

    // --- Dashboard -------------------------------------------------------
    fun dashboard(): String = tenant("dashboard")
    fun dashboardSummary(): String = tenant("dashboard/summary")
    fun dashboardKpis(): String = tenant("dashboard/kpis")
    fun dashboardSalesTrend(): String = tenant("dashboard/charts/sales-trend")
    fun dashboardTopProducts(): String = tenant("dashboard/charts/top-products")
    fun lowStock(): String = tenant("dashboard/lists/low-stock")
    fun recentOrders(): String = tenant("dashboard/lists/recent-orders")

    // --- POS -------------------------------------------------------------
    fun posProducts(): String = tenant("pos/products")
    fun posAccounts(): String = tenant("pos/accounts")
    fun posPaymentMethods(): String = tenant("pos/payment-methods")
    fun posTaxes(): String = tenant("pos/taxes")

    fun posShiftOpen(): String = tenant("pos/shift/open")
    fun posShiftClose(): String = tenant("pos/shift/close")
    fun posShiftCurrent(): String = tenant("pos/shift/current")
    fun posShiftSummary(): String = tenant("pos/shift/summary")
    fun posShiftHistory(): String = tenant("pos/shift/history")
    fun posShiftById(id: Long): String = tenant("pos/shifts/$id")
    fun posShiftCashMovements(): String = tenant("pos/shift/cash-movements")
    fun posShiftAvailableDrawers(): String = tenant("pos/shift/available-drawers")

    fun posOrders(): String = tenant("pos-orders")
    fun posOrderById(id: Long): String = tenant("pos-orders/$id")
    fun posOrderReceipt(id: Long): String = tenant("pos-orders/$id/receipt")
    fun posOrderReturn(id: Long): String = tenant("pos-orders/$id/return")
    fun posOrderPayments(id: Long): String = tenant("pos-orders/$id/payments")

    // --- Clients ---------------------------------------------------------
    fun clients(): String = tenant("clients")
    fun clientById(id: Long): String = tenant("clients/$id")
    fun clientByPhone(): String = tenant("clients/by-phone")
    fun clientsSummary(): String = tenant("clients/summary")
    fun clientOrders(id: Long): String = tenant("clients/$id/orders")
    fun clientDueOrders(id: Long): String = tenant("clients/$id/due-orders")
    fun clientPayments(id: Long): String = tenant("clients/$id/payments")
    fun clientStatement(id: Long): String = tenant("clients/$id/statement")
    fun clientRecordPayment(id: Long): String = tenant("clients/$id/record-payment")
    fun clientBlock(id: Long): String = tenant("clients/$id/block")
    fun clientUnblock(id: Long): String = tenant("clients/$id/unblock")
    fun clientCredit(id: Long): String = tenant("clients/$id/credit")
    fun clientPaymentsCollection(): String = tenant("client-payments")

    // --- Products & Inventory -------------------------------------------
    fun products(): String = tenant("products")
    fun productById(id: Long): String = tenant("products/$id")
    fun productTransactions(id: Long): String = tenant("products/$id/transactions")
    fun productCategories(): String = tenant("product-categories")

    fun inventories(): String = tenant("inventories")
    fun inventoryById(id: Long): String = tenant("inventories/$id")
    fun defaultInventory(): String = tenant("inventories/default")
    fun inventoryProducts(inventoryId: Long): String = tenant("inventories/$inventoryId/products")
    fun inventoryTransfer(): String = tenant("inventories/transfer")
    fun stockMovements(): String = tenant("stock-movements")

    // --- Expenses --------------------------------------------------------
    fun expenses(): String = tenant("expenses")
    fun expenseById(id: Long): String = tenant("expenses/$id")
    fun expenseCategories(): String = tenant("expense-categories")

    // --- Accounts --------------------------------------------------------
    fun accounts(): String = tenant("accounts")
    fun accountById(id: Long): String = tenant("accounts/$id")
    fun accountHistory(id: Long): String = tenant("accounts/$id/history")
    fun accountDeposit(): String = tenant("accounts/deposit")
    fun accountWithdraw(): String = tenant("accounts/withdraw")
    fun accountTransfer(): String = tenant("accounts/transfer")
    fun accountTransfers(): String = tenant("accounts/transfers")
    fun accountAdjustments(): String = tenant("account-adjustments")

    // --- Profile ---------------------------------------------------------
    fun profile(): String = tenant("profile")
    fun profileAvatar(): String = tenant("profile/avatar")
    fun profilePassword(): String = tenant("profile/password")

    // --- Settings (read-only MVP) ---------------------------------------
    fun settingsCompany(): String = tenant("settings/company")
    fun settingsCurrencies(): String = tenant("settings/currencies")
    fun settingsTaxes(): String = tenant("settings/taxes")
    fun settingsPaymentMethods(): String = tenant("settings/payment-methods")
    fun settingsReceipt(): String = tenant("settings/receipt")

    // --- Billing (read-only) --------------------------------------------
    fun billingSubscription(): String = tenant("billing/subscription")
    fun billingTransactions(): String = tenant("billing/transactions")

    // --- Reports ---------------------------------------------------------
    fun reportsSales(): String = tenant("reports/sales")
    fun reportsSalesTrend(): String = tenant("reports/sales-trend")
    fun reportsTopProducts(): String = tenant("reports/top-products")
    fun reportsExpenses(): String = tenant("reports/expenses")
    fun reportsProfit(): String = tenant("reports/profit")
    fun reportsClients(): String = tenant("reports/clients")

    // --- Invoices --------------------------------------------------------
    fun invoices(): String = tenant("invoices")
    fun invoiceById(id: Long): String = tenant("invoices/$id")

    // --- Suppliers -------------------------------------------------------
    fun suppliers(): String = tenant("suppliers")
    fun supplierById(id: Long): String = tenant("suppliers/$id")
    fun purchaseOrders(): String = tenant("purchase-orders")
    fun purchaseOrderById(id: Long): String = tenant("purchase-orders/$id")

    // --- Notifications ---------------------------------------------------
    fun notifications(): String = tenant("notifications")
    fun notificationMarkRead(id: Long): String = tenant("notifications/$id/mark-read")
    fun notificationsMarkAllRead(): String = tenant("notifications/mark-all-read")
}
