package me.amermahsoub.bfm.shared.data.api

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.patch
import io.ktor.client.request.post
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import me.amermahsoub.bfm.shared.data.models.Account
import me.amermahsoub.bfm.shared.data.models.AccountStatementEntry
import me.amermahsoub.bfm.shared.data.models.AccountingPeriod
import me.amermahsoub.bfm.shared.data.models.ApiResponse
import me.amermahsoub.bfm.shared.data.models.BarcodeProduct
import me.amermahsoub.bfm.shared.data.models.Client
import me.amermahsoub.bfm.shared.data.models.ClientStatementEntry
import me.amermahsoub.bfm.shared.data.models.CloseShiftRequest
import me.amermahsoub.bfm.shared.data.models.CreateExpenseRequest
import me.amermahsoub.bfm.shared.data.models.CreatePosOrderRequest
import me.amermahsoub.bfm.shared.data.models.CreatePurchaseInvoiceRequest
import me.amermahsoub.bfm.shared.data.models.CreateSalesInvoiceRequest
import me.amermahsoub.bfm.shared.data.models.Expense
import me.amermahsoub.bfm.shared.data.models.ExpenseCategory
import me.amermahsoub.bfm.shared.data.models.GlAccount
import me.amermahsoub.bfm.shared.data.models.Inventory
import me.amermahsoub.bfm.shared.data.models.InventoryProduct
import me.amermahsoub.bfm.shared.data.models.JournalEntry
import me.amermahsoub.bfm.shared.data.models.OpenShiftRequest
import me.amermahsoub.bfm.shared.data.models.PaginatedResponse
import me.amermahsoub.bfm.shared.data.models.PaymentMethod
import me.amermahsoub.bfm.shared.data.models.PosOrder
import me.amermahsoub.bfm.shared.data.models.PosTerminal
import me.amermahsoub.bfm.shared.data.models.Product
import me.amermahsoub.bfm.shared.data.models.ProductCategory
import me.amermahsoub.bfm.shared.data.models.ProfitLossReport
import me.amermahsoub.bfm.shared.data.models.PurchaseInvoice
import me.amermahsoub.bfm.shared.data.models.RecordPaymentRequest
import me.amermahsoub.bfm.shared.data.models.SalesInvoice
import me.amermahsoub.bfm.shared.data.models.Shift
import me.amermahsoub.bfm.shared.data.models.ShiftSummary
import me.amermahsoub.bfm.shared.data.models.StockMovement
import me.amermahsoub.bfm.shared.data.models.Supplier
import me.amermahsoub.bfm.shared.data.models.TrialBalanceRow
import me.amermahsoub.bfm.shared.data.models.Unit
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder

/**
 * Comprehensive Ktor-based HTTP service for all Operix API endpoints.
 * The TenantNetworkInterceptor automatically injects the auth token
 * and tenant slug header on all requests.
 */
class OperixApiService(
    private val client: HttpClient,
    private val urlBuilder: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    private fun url(slug: String, path: String): String =
        "${urlBuilder.base}/api/v1/$slug/$path"

    // ── Error handling ────────────────────────────────────────────────────

    private suspend fun HttpResponse.checkError() {
        if (status.isSuccess()) return
        val code = status.value
        val text = try { bodyAsText() } catch (_: Exception) { "" }
        val obj = try { json.parseToJsonElement(text).jsonObject } catch (_: Exception) { null }
        val message = try {
            obj?.get("message")?.jsonPrimitive?.content
        } catch (_: Exception) { null } ?: status.description
        val fieldErrors: Map<String, List<String>> = obj?.get("errors")
            ?.let { it as? JsonObject }
            ?.mapValues { (_, v) ->
                (v as? JsonArray)?.map { it.jsonPrimitive.content } ?: emptyList()
            } ?: emptyMap()
        throw when (code) {
            422  -> ApiException.Validation(message, fieldErrors)
            401, 403 -> ApiException.Auth(message)
            404  -> ApiException.NotFound(message)
            in 500..599 -> ApiException.Server(message, code)
            else -> ApiException.Server(message, code)
        }
    }

    // ── HTTP helpers ──────────────────────────────────────────────────────

    private suspend inline fun <reified T> getList(slug: String, path: String, params: Map<String, Any?> = emptyMap()): List<T> {
        val response = client.get(url(slug, path)) {
            params.forEach { (k, v) -> if (v != null) parameter(k, v) }
        }
        response.checkError()
        val rawJson: JsonObject = response.body()
        return tryUnwrapList(rawJson)
    }

    private suspend inline fun <reified T> getPaginated(slug: String, path: String, params: Map<String, Any?> = emptyMap()): PaginatedResponse<T> {
        val response = client.get(url(slug, path)) {
            params.forEach { (k, v) -> if (v != null) parameter(k, v) }
        }
        response.checkError()
        val rawJson: JsonObject = response.body()
        val dataEl = rawJson["data"]
        return if (dataEl != null) {
            json.decodeFromJsonElement(rawJson)
        } else {
            PaginatedResponse(data = json.decodeFromJsonElement<List<T>>(rawJson))
        }
    }

    private suspend inline fun <reified T> getSingle(slug: String, path: String): T {
        val response = client.get(url(slug, path))
        response.checkError()
        val rawJson: JsonObject = response.body()
        return tryUnwrap(rawJson)
    }

    private suspend inline fun <reified T> postSingle(slug: String, path: String, body: Any? = null): T {
        val response = client.post(url(slug, path)) {
            contentType(ContentType.Application.Json)
            if (body != null) setBody(body)
        }
        response.checkError()
        val rawJson: JsonObject = response.body()
        return tryUnwrap(rawJson)
    }

    private suspend inline fun <reified T> putSingle(slug: String, path: String, body: Any): T {
        val response = client.put(url(slug, path)) {
            contentType(ContentType.Application.Json)
            setBody(body)
        }
        response.checkError()
        val rawJson: JsonObject = response.body()
        return tryUnwrap(rawJson)
    }

    private suspend fun deleteResource(slug: String, path: String) {
        client.delete(url(slug, path)).checkError()
    }

    private inline fun <reified T> tryUnwrap(obj: JsonObject): T {
        val dataEl = obj["data"]
        return if (dataEl != null && dataEl !is kotlinx.serialization.json.JsonNull) {
            json.decodeFromJsonElement(dataEl)
        } else {
            json.decodeFromJsonElement(obj)
        }
    }

    private inline fun <reified T> tryUnwrapList(obj: JsonObject): List<T> {
        val dataEl = obj["data"]
        return if (dataEl != null) {
            json.decodeFromJsonElement(dataEl)
        } else {
            json.decodeFromJsonElement(obj)
        }
    }

    // ── Dashboard ─────────────────────────────────────────────────────────

    suspend fun getDashboard(slug: String): JsonObject =
        client.get(url(slug, OperixApiPaths.DASHBOARD)).body()

    // ── Products ──────────────────────────────────────────────────────────

    suspend fun getProducts(
        slug: String,
        search: String? = null,
        categoryId: Int? = null,
        isActive: Boolean? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): PaginatedResponse<Product> = getPaginated(slug, OperixApiPaths.PRODUCTS, mapOf(
        "search" to search, "category_id" to categoryId, "is_active" to isActive,
        "page" to page, "per_page" to perPage,
    ))

    suspend fun getProduct(slug: String, id: Int): Product =
        getSingle(slug, OperixApiPaths.product(id))

    suspend fun createProduct(slug: String, body: Map<String, Any?>): Product =
        postSingle(slug, OperixApiPaths.PRODUCTS, body)

    suspend fun updateProduct(slug: String, id: Int, body: Map<String, Any?>): Product =
        putSingle(slug, OperixApiPaths.product(id), body)

    suspend fun deleteProduct(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.product(id))

    suspend fun getProductCategories(slug: String, search: String? = null): List<ProductCategory> =
        getList(slug, OperixApiPaths.PRODUCT_CATEGORIES, mapOf("search" to search))

    suspend fun createProductCategory(slug: String, nameEn: String, nameAr: String? = null): ProductCategory =
        postSingle(slug, OperixApiPaths.PRODUCT_CATEGORIES, mapOf("name_en" to nameEn, "name_ar" to nameAr))

    suspend fun getUnits(slug: String): List<Unit> =
        getList(slug, OperixApiPaths.UNITS)

    suspend fun createUnit(slug: String, nameEn: String, nameAr: String? = null): Unit =
        postSingle(slug, OperixApiPaths.UNITS, mapOf("name_en" to nameEn, "name_ar" to nameAr))

    // ── Inventory ─────────────────────────────────────────────────────────

    suspend fun getInventories(slug: String): List<Inventory> =
        getList(slug, OperixApiPaths.INVENTORIES)

    suspend fun getInventoryProducts(
        slug: String,
        inventoryId: Int,
        search: String? = null,
        lowStockOnly: Boolean? = null,
        page: Int = 1,
    ): PaginatedResponse<InventoryProduct> = getPaginated(
        slug, OperixApiPaths.inventoryProducts(inventoryId),
        mapOf("search" to search, "low_stock_only" to lowStockOnly, "page" to page),
    )

    suspend fun getStockMovements(
        slug: String,
        inventoryId: Int? = null,
        productId: Int? = null,
        type: String? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
    ): PaginatedResponse<StockMovement> = getPaginated(
        slug, OperixApiPaths.STOCK_MOVEMENTS,
        mapOf("inventory_id" to inventoryId, "product_id" to productId, "type" to type,
              "from_date" to fromDate, "to_date" to toDate, "page" to page),
    )

    // ── Clients ───────────────────────────────────────────────────────────

    suspend fun getClients(
        slug: String,
        search: String? = null,
        isActive: Boolean? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): PaginatedResponse<Client> = getPaginated(slug, OperixApiPaths.CLIENTS, mapOf(
        "search" to search, "is_active" to isActive, "page" to page, "per_page" to perPage,
    ))

    suspend fun getClient(slug: String, id: Int): Client =
        getSingle(slug, OperixApiPaths.client(id))

    suspend fun createClient(slug: String, body: Map<String, Any?>): Client =
        postSingle(slug, OperixApiPaths.CLIENTS, body)

    suspend fun updateClient(slug: String, id: Int, body: Map<String, Any?>): Client =
        putSingle(slug, OperixApiPaths.client(id), body)

    // ── Suppliers ─────────────────────────────────────────────────────────

    suspend fun getSuppliers(
        slug: String,
        search: String? = null,
        isActive: Boolean? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): PaginatedResponse<Supplier> = getPaginated(slug, OperixApiPaths.SUPPLIERS, mapOf(
        "search" to search, "is_active" to isActive, "page" to page, "per_page" to perPage,
    ))

    suspend fun getSupplier(slug: String, id: Int): Supplier =
        getSingle(slug, OperixApiPaths.supplier(id))

    suspend fun createSupplier(slug: String, body: Map<String, Any?>): Supplier =
        postSingle(slug, OperixApiPaths.SUPPLIERS, body)

    suspend fun updateSupplier(slug: String, id: Int, body: Map<String, Any?>): Supplier =
        putSingle(slug, OperixApiPaths.supplier(id), body)

    // ── Sales Invoices ────────────────────────────────────────────────────

    suspend fun getSalesInvoices(
        slug: String,
        status: String? = null,
        clientId: Int? = null,
        fromDate: String? = null,
        toDate: String? = null,
        search: String? = null,
        page: Int = 1,
    ): PaginatedResponse<SalesInvoice> = getPaginated(
        slug, OperixApiPaths.SALES_INVOICES,
        mapOf("status" to status, "client_id" to clientId, "from_date" to fromDate,
              "to_date" to toDate, "search" to search, "page" to page),
    )

    suspend fun getSalesInvoice(slug: String, id: Int): SalesInvoice =
        getSingle(slug, OperixApiPaths.salesInvoice(id))

    suspend fun createSalesInvoice(slug: String, request: CreateSalesInvoiceRequest): SalesInvoice =
        postSingle(slug, OperixApiPaths.SALES_INVOICES, request)

    suspend fun postSalesInvoice(slug: String, id: Int): SalesInvoice =
        postSingle(slug, OperixApiPaths.salesInvoicePost(id))

    suspend fun cancelSalesInvoice(slug: String, id: Int, reason: String? = null): SalesInvoice =
        postSingle(slug, OperixApiPaths.salesInvoiceCancel(id), mapOf("reason" to reason))

    suspend fun recordSalesPayment(slug: String, id: Int, request: RecordPaymentRequest): SalesInvoice =
        postSingle(slug, OperixApiPaths.salesInvoicePayments(id), request)

    // ── Purchase Invoices ─────────────────────────────────────────────────

    suspend fun getPurchaseInvoices(
        slug: String,
        status: String? = null,
        supplierId: Int? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
    ): PaginatedResponse<PurchaseInvoice> = getPaginated(
        slug, OperixApiPaths.PURCHASE_INVOICES,
        mapOf("status" to status, "supplier_id" to supplierId,
              "from_date" to fromDate, "to_date" to toDate, "page" to page),
    )

    suspend fun getPurchaseInvoice(slug: String, id: Int): PurchaseInvoice =
        getSingle(slug, OperixApiPaths.purchaseInvoice(id))

    suspend fun createPurchaseInvoice(slug: String, request: CreatePurchaseInvoiceRequest): PurchaseInvoice =
        postSingle(slug, OperixApiPaths.PURCHASE_INVOICES, request)

    suspend fun postPurchaseInvoice(slug: String, id: Int): PurchaseInvoice =
        postSingle(slug, OperixApiPaths.purchaseInvoicePost(id))

    suspend fun recordSupplierPayment(slug: String, request: RecordPaymentRequest, invoiceId: Int): PurchaseInvoice =
        postSingle(slug, OperixApiPaths.SUPPLIER_PAYMENTS, buildMap {
            put("purchase_invoice_id", invoiceId)
            put("amount", request.amount)
            put("payment_method_id", request.paymentMethodId)
            put("payment_date", request.paymentDate)
            if (request.notes != null) put("notes", request.notes)
        })

    // ── POS ───────────────────────────────────────────────────────────────

    suspend fun getPosTerminals(slug: String): List<PosTerminal> =
        getList(slug, OperixApiPaths.POS_TERMINALS)

    suspend fun getCurrentShift(slug: String, terminalId: Int): Shift? = runCatching {
        getSingle<Shift>(slug, OperixApiPaths.posTerminalCurrentShift(terminalId))
    }.getOrNull()

    suspend fun openShift(slug: String, request: OpenShiftRequest): Shift =
        postSingle(slug, OperixApiPaths.POS_SHIFTS, request)

    suspend fun closeShift(slug: String, shiftId: Int, request: CloseShiftRequest): Shift =
        postSingle(slug, OperixApiPaths.posShiftClose(shiftId), request)

    suspend fun getShiftSummary(slug: String, shiftId: Int): ShiftSummary =
        getSingle(slug, OperixApiPaths.posShiftSummary(shiftId))

    suspend fun getPosOrders(
        slug: String,
        shiftId: Int? = null,
        terminalId: Int? = null,
        status: String? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
    ): PaginatedResponse<PosOrder> = getPaginated(
        slug, OperixApiPaths.POS_ORDERS,
        mapOf("shift_id" to shiftId, "terminal_id" to terminalId, "status" to status,
              "from_date" to fromDate, "to_date" to toDate, "page" to page),
    )

    suspend fun getPosOrder(slug: String, orderId: Int): PosOrder =
        getSingle(slug, OperixApiPaths.posOrder(orderId))

    suspend fun createPosOrder(slug: String, request: CreatePosOrderRequest): PosOrder =
        postSingle(slug, OperixApiPaths.POS_ORDERS, request)

    suspend fun refundPosOrder(slug: String, orderId: Int, reason: String? = null): PosOrder =
        postSingle(slug, OperixApiPaths.posOrderRefund(orderId), mapOf("reason" to reason))

    suspend fun lookupBarcode(slug: String, barcode: String, inventoryId: Int? = null): BarcodeProduct =
        getSingle<BarcodeProduct>(slug, "${OperixApiPaths.POS_BARCODE}?barcode=$barcode${if (inventoryId != null) "&inventory_id=$inventoryId" else ""}")

    suspend fun searchPosProducts(slug: String, query: String, inventoryId: Int? = null): List<Product> =
        getList(slug, OperixApiPaths.POS_SEARCH, mapOf("q" to query, "inventory_id" to inventoryId))

    // ── Accounts & GL ─────────────────────────────────────────────────────

    suspend fun getAccounts(slug: String, type: String? = null): List<Account> =
        getList(slug, OperixApiPaths.ACCOUNTS, mapOf("type" to type))

    suspend fun getGlAccounts(slug: String, accountType: String? = null): List<GlAccount> =
        getList(slug, OperixApiPaths.GL_ACCOUNTS, mapOf("account_type" to accountType))

    suspend fun getJournalEntries(
        slug: String,
        sourceType: String? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
    ): PaginatedResponse<JournalEntry> = getPaginated(
        slug, OperixApiPaths.JOURNAL_ENTRIES,
        mapOf("source_type" to sourceType, "from_date" to fromDate, "to_date" to toDate, "page" to page),
    )

    suspend fun getPaymentMethods(slug: String): List<PaymentMethod> =
        getList(slug, OperixApiPaths.PAYMENT_METHODS)

    suspend fun getAccountingPeriods(slug: String): List<AccountingPeriod> =
        getList(slug, OperixApiPaths.ACCOUNTING_PERIODS)

    // ── Expenses ──────────────────────────────────────────────────────────

    suspend fun getExpenses(
        slug: String,
        categoryId: Int? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
    ): PaginatedResponse<Expense> = getPaginated(
        slug, OperixApiPaths.EXPENSES,
        mapOf("category_id" to categoryId, "from_date" to fromDate, "to_date" to toDate, "page" to page),
    )

    suspend fun createExpense(slug: String, request: CreateExpenseRequest): Expense =
        postSingle(slug, OperixApiPaths.EXPENSES, request)

    suspend fun getExpenseCategories(slug: String): List<ExpenseCategory> =
        getList(slug, OperixApiPaths.EXPENSE_CATEGORIES)

    // ── Reports ───────────────────────────────────────────────────────────

    suspend fun getProfitLoss(slug: String, fromDate: String, toDate: String): ProfitLossReport =
        getSingle(slug, "${OperixApiPaths.REPORT_PROFIT_LOSS}?from_date=$fromDate&to_date=$toDate")

    suspend fun getTrialBalance(slug: String, fromDate: String, toDate: String): List<TrialBalanceRow> =
        getList(slug, OperixApiPaths.REPORT_TRIAL_BALANCE, mapOf("from_date" to fromDate, "to_date" to toDate))

    suspend fun getClientStatement(
        slug: String,
        clientId: Int,
        fromDate: String,
        toDate: String,
    ): List<ClientStatementEntry> =
        getList(slug, OperixApiPaths.REPORT_CLIENT_STATEMENT,
            mapOf("client_id" to clientId, "from_date" to fromDate, "to_date" to toDate))

    suspend fun getSupplierStatement(
        slug: String,
        supplierId: Int,
        fromDate: String,
        toDate: String,
    ): List<ClientStatementEntry> =
        getList(slug, OperixApiPaths.REPORT_SUPPLIER_STATEMENT,
            mapOf("supplier_id" to supplierId, "from_date" to fromDate, "to_date" to toDate))

    suspend fun getAccountStatement(
        slug: String,
        accountId: Int,
        fromDate: String,
        toDate: String,
    ): List<AccountStatementEntry> =
        getList(slug, OperixApiPaths.REPORT_ACCOUNT_STATEMENT,
            mapOf("account_id" to accountId, "from_date" to fromDate, "to_date" to toDate))
}
