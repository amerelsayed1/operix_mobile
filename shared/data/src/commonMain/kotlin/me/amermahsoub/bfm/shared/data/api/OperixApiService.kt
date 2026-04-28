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
import me.amermahsoub.bfm.shared.data.models.AccountHistoryEntry
import me.amermahsoub.bfm.shared.data.models.AccountHistoryResponse
import me.amermahsoub.bfm.shared.data.models.AccountStatementEntry
import me.amermahsoub.bfm.shared.data.models.AccountTransferRequest
import me.amermahsoub.bfm.shared.data.models.AccountTransferResult
import me.amermahsoub.bfm.shared.data.models.AccountingPeriod
import me.amermahsoub.bfm.shared.data.models.AgingReport
import me.amermahsoub.bfm.shared.data.models.ApiResponse
import me.amermahsoub.bfm.shared.data.models.BarcodeProduct
import me.amermahsoub.bfm.shared.data.models.CashMovement
import me.amermahsoub.bfm.shared.data.models.Client
import me.amermahsoub.bfm.shared.data.models.ClientStatementEntry
import me.amermahsoub.bfm.shared.data.models.CloseShiftRequest
import me.amermahsoub.bfm.shared.data.models.CreateExpenseRequest
import me.amermahsoub.bfm.shared.data.models.CreatePosOrderRequest
import me.amermahsoub.bfm.shared.data.models.CreatePurchaseInvoiceRequest
import me.amermahsoub.bfm.shared.data.models.CreateSalesInvoiceRequest
import me.amermahsoub.bfm.shared.data.models.Currency
import me.amermahsoub.bfm.shared.data.models.DailySalesEntry
import me.amermahsoub.bfm.shared.data.models.DashboardSummary
import me.amermahsoub.bfm.shared.data.models.DepositRequest
import me.amermahsoub.bfm.shared.data.models.Employee
import me.amermahsoub.bfm.shared.data.models.Expense
import me.amermahsoub.bfm.shared.data.models.ExpenseCategory
import me.amermahsoub.bfm.shared.data.models.GlAccount
import me.amermahsoub.bfm.shared.data.models.IncomeStatementReport
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
import me.amermahsoub.bfm.shared.data.models.PurchaseInvoice
import me.amermahsoub.bfm.shared.data.models.ReceiptData
import me.amermahsoub.bfm.shared.data.models.RecordCashMovementRequest
import me.amermahsoub.bfm.shared.data.models.RecordPaymentRequest
import me.amermahsoub.bfm.shared.data.models.SalesInvoice
import me.amermahsoub.bfm.shared.data.models.SalesTrendEntry
import me.amermahsoub.bfm.shared.data.models.Shift
import me.amermahsoub.bfm.shared.data.models.ShiftSummary
import me.amermahsoub.bfm.shared.data.models.StockMovement
import me.amermahsoub.bfm.shared.data.models.Supplier
import me.amermahsoub.bfm.shared.data.models.Tax
import me.amermahsoub.bfm.shared.data.models.TaxConfig
import me.amermahsoub.bfm.shared.data.models.TopProductEntry
import me.amermahsoub.bfm.shared.data.models.TrialBalanceRow
import me.amermahsoub.bfm.shared.data.models.Unit
import me.amermahsoub.bfm.shared.data.models.WithdrawRequest
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder

/**
 * Comprehensive Ktor-based HTTP service for all Operix API endpoints.
 * The TenantNetworkInterceptor automatically injects the auth token
 * and tenant-slug header on every request.
 *
 * Path reference: docs/API_REFERENCE.md
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
        val obj  = try { json.parseToJsonElement(text).jsonObject } catch (_: Exception) { null }
        val message = try {
            obj?.get("message")?.jsonPrimitive?.content
        } catch (_: Exception) { null } ?: status.description
        val fieldErrors: Map<String, List<String>> = obj?.get("errors")
            ?.let { it as? JsonObject }
            ?.mapValues { (_, v) ->
                (v as? JsonArray)?.map { it.jsonPrimitive.content } ?: emptyList()
            } ?: emptyMap()
        throw when (code) {
            422       -> ApiException.Validation(message, fieldErrors)
            401, 403  -> ApiException.Auth(message)
            404       -> ApiException.NotFound(message)
            in 500..599 -> ApiException.Server(message, code)
            else      -> ApiException.Server(message, code)
        }
    }

    // ── HTTP helpers ──────────────────────────────────────────────────────

    private suspend inline fun <reified T> getList(
        slug: String, path: String, params: Map<String, Any?> = emptyMap(),
    ): List<T> {
        val response = client.get(url(slug, path)) {
            params.forEach { (k, v) -> if (v != null) parameter(k, v) }
        }
        response.checkError()
        val rawJson: JsonObject = response.body()
        return tryUnwrapList(rawJson)
    }

    private suspend inline fun <reified T> getPaginated(
        slug: String, path: String, params: Map<String, Any?> = emptyMap(),
    ): PaginatedResponse<T> {
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

    private suspend inline fun <reified T> postSingle(
        slug: String, path: String, body: Any? = null,
    ): T {
        val response = client.post(url(slug, path)) {
            contentType(ContentType.Application.Json)
            if (body != null) setBody(body)
        }
        response.checkError()
        val rawJson: JsonObject = response.body()
        return tryUnwrap(rawJson)
    }

    private suspend fun postVoid(slug: String, path: String, body: Any? = null) {
        val response = client.post(url(slug, path)) {
            contentType(ContentType.Application.Json)
            if (body != null) setBody(body)
        }
        response.checkError()
    }

    private suspend inline fun <reified T> putSingle(
        slug: String, path: String, body: Any,
    ): T {
        val response = client.put(url(slug, path)) {
            contentType(ContentType.Application.Json)
            setBody(body)
        }
        response.checkError()
        val rawJson: JsonObject = response.body()
        return tryUnwrap(rawJson)
    }

    private suspend inline fun <reified T> patchSingle(
        slug: String, path: String, body: Any,
    ): T {
        val response = client.patch(url(slug, path)) {
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

    // ═══════════════════════════════════════════════════════════════════════
    // DASHBOARD
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getDashboardSummary(slug: String): DashboardSummary =
        getSingle(slug, OperixApiPaths.DASHBOARD)

    suspend fun getDashboardKpis(slug: String): JsonObject =
        client.get(url(slug, OperixApiPaths.DASHBOARD_KPIS)).body()

    suspend fun getSalesTrend(
        slug: String,
        from: String? = null,
        to: String? = null,
        groupBy: String? = null,
    ): List<SalesTrendEntry> = getList(
        slug, OperixApiPaths.DASHBOARD_SALES_TREND,
        mapOf("from" to from, "to" to to, "groupBy" to groupBy),
    )

    suspend fun getTopProducts(slug: String): List<TopProductEntry> =
        getList(slug, OperixApiPaths.DASHBOARD_TOP_PRODUCTS)

    suspend fun getLowStock(slug: String): List<JsonObject> =
        getList(slug, OperixApiPaths.DASHBOARD_LOW_STOCK)

    suspend fun getRecentOrders(slug: String): List<JsonObject> =
        getList(slug, OperixApiPaths.DASHBOARD_RECENT_ORDERS)

    // ═══════════════════════════════════════════════════════════════════════
    // PRODUCTS
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getProducts(
        slug: String,
        search: String? = null,
        categoryId: Int? = null,
        isActive: Boolean? = null,
        hasVariants: Boolean? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): PaginatedResponse<Product> = getPaginated(
        slug, OperixApiPaths.PRODUCTS,
        mapOf(
            "search" to search, "product_category_id" to categoryId,
            "is_active" to isActive, "has_variants" to hasVariants,
            "page" to page, "per_page" to perPage,
        ),
    )

    suspend fun getProduct(slug: String, id: Int): Product =
        getSingle(slug, OperixApiPaths.product(id))

    suspend fun createProduct(slug: String, body: Map<String, Any?>): Product =
        postSingle(slug, OperixApiPaths.PRODUCTS, body)

    suspend fun updateProduct(slug: String, id: Int, body: Map<String, Any?>): Product =
        putSingle(slug, OperixApiPaths.product(id), body)

    suspend fun deleteProduct(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.product(id))

    suspend fun getNextProductCodes(slug: String): JsonObject =
        client.get(url(slug, OperixApiPaths.PRODUCT_NEXT_CODES)).body()

    // ── Product categories ────────────────────────────────────────────────

    suspend fun getProductCategories(
        slug: String, search: String? = null,
    ): List<ProductCategory> =
        getList(slug, OperixApiPaths.PRODUCT_CATEGORIES, mapOf("search" to search))

    suspend fun createProductCategory(
        slug: String, nameEn: String, nameAr: String? = null,
    ): ProductCategory =
        postSingle(slug, OperixApiPaths.PRODUCT_CATEGORIES,
            mapOf("name" to nameEn, "name_en" to nameEn, "name_ar" to nameAr))

    suspend fun updateProductCategory(
        slug: String, id: Int, nameEn: String, nameAr: String? = null,
    ): ProductCategory =
        putSingle(slug, OperixApiPaths.productCategory(id),
            mapOf("name" to nameEn, "name_en" to nameEn, "name_ar" to nameAr))

    suspend fun deleteProductCategory(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.productCategory(id))

    // ── Units ─────────────────────────────────────────────────────────────

    suspend fun getUnits(slug: String): List<Unit> =
        getList(slug, OperixApiPaths.SETTINGS_UNITS)

    suspend fun createUnit(slug: String, nameEn: String, nameAr: String? = null): Unit =
        postSingle(slug, OperixApiPaths.SETTINGS_UNITS,
            mapOf("name_en" to nameEn, "name_ar" to nameAr))

    suspend fun updateUnit(slug: String, id: Int, nameEn: String, nameAr: String? = null): Unit =
        putSingle(slug, OperixApiPaths.settingsUnit(id),
            mapOf("name_en" to nameEn, "name_ar" to nameAr))

    suspend fun deleteUnit(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.settingsUnit(id))

    // ═══════════════════════════════════════════════════════════════════════
    // INVENTORY / WAREHOUSES
    // ═══════════════════════════════════════════════════════════════════════

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
        mapOf("search" to search, "low_stock" to lowStockOnly, "page" to page),
    )

    suspend fun adjustStock(
        slug: String, inventoryId: Int, productId: Int,
        quantity: Int, reason: String? = null,
    ): JsonObject {
        val response = client.patch(
            url(slug, OperixApiPaths.inventoryProductAdjust(inventoryId, productId))
        ) {
            contentType(ContentType.Application.Json)
            setBody(mapOf("quantity" to quantity, "reason" to reason))
        }
        response.checkError()
        return response.body()
    }

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
        mapOf(
            "inventory_id" to inventoryId, "product_id" to productId,
            "type" to type, "from_date" to fromDate, "to_date" to toDate, "page" to page,
        ),
    )

    // ═══════════════════════════════════════════════════════════════════════
    // CLIENTS
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getClients(
        slug: String,
        search: String? = null,
        status: String? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): PaginatedResponse<Client> = getPaginated(
        slug, OperixApiPaths.CLIENTS,
        mapOf("search" to search, "status" to status, "page" to page, "per_page" to perPage),
    )

    suspend fun getClient(slug: String, id: Int): Client =
        getSingle(slug, OperixApiPaths.client(id))

    suspend fun createClient(slug: String, body: Map<String, Any?>): Client =
        postSingle(slug, OperixApiPaths.CLIENTS, body)

    suspend fun updateClient(slug: String, id: Int, body: Map<String, Any?>): Client =
        putSingle(slug, OperixApiPaths.client(id), body)

    suspend fun deleteClient(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.client(id))

    suspend fun getClientStatement(
        slug: String, clientId: Int, fromDate: String, toDate: String,
    ): List<ClientStatementEntry> =
        getList(slug, OperixApiPaths.clientStatement(clientId),
            mapOf("from" to fromDate, "to" to toDate))

    // ═══════════════════════════════════════════════════════════════════════
    // SUPPLIERS
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getSuppliers(
        slug: String,
        search: String? = null,
        status: String? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): PaginatedResponse<Supplier> = getPaginated(
        slug, OperixApiPaths.SUPPLIERS,
        mapOf("search" to search, "status" to status, "page" to page, "per_page" to perPage),
    )

    suspend fun getSupplier(slug: String, id: Int): Supplier =
        getSingle(slug, OperixApiPaths.supplier(id))

    suspend fun createSupplier(slug: String, body: Map<String, Any?>): Supplier =
        postSingle(slug, OperixApiPaths.SUPPLIERS, body)

    suspend fun updateSupplier(slug: String, id: Int, body: Map<String, Any?>): Supplier =
        putSingle(slug, OperixApiPaths.supplier(id), body)

    suspend fun deleteSupplier(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.supplier(id))

    suspend fun getSupplierLedger(
        slug: String, supplierId: Int, fromDate: String, toDate: String,
    ): List<ClientStatementEntry> =
        getList(slug, OperixApiPaths.supplierLedger(supplierId),
            mapOf("from" to fromDate, "to" to toDate))

    // ═══════════════════════════════════════════════════════════════════════
    // SALES INVOICES
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getSalesInvoices(
        slug: String,
        status: String? = null,
        clientId: Int? = null,
        fromDate: String? = null,
        toDate: String? = null,
        search: String? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): PaginatedResponse<SalesInvoice> = getPaginated(
        slug, OperixApiPaths.SALES_INVOICES,
        mapOf(
            "status" to status, "client_id" to clientId,
            "from" to fromDate, "to" to toDate,
            "search" to search, "page" to page, "per_page" to perPage,
        ),
    )

    suspend fun getSalesInvoice(slug: String, id: Int): SalesInvoice =
        getSingle(slug, OperixApiPaths.salesInvoice(id))

    suspend fun createSalesInvoice(
        slug: String, request: CreateSalesInvoiceRequest,
    ): SalesInvoice =
        postSingle(slug, OperixApiPaths.SALES_INVOICES, request)

    suspend fun updateSalesInvoice(
        slug: String, id: Int, request: CreateSalesInvoiceRequest,
    ): SalesInvoice =
        putSingle(slug, OperixApiPaths.salesInvoice(id), request)

    suspend fun deleteSalesInvoice(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.salesInvoice(id))

    suspend fun postSalesInvoice(slug: String, id: Int): SalesInvoice =
        postSingle(slug, OperixApiPaths.salesInvoicePost(id))

    suspend fun cancelSalesInvoice(slug: String, id: Int, reason: String? = null): SalesInvoice =
        postSingle(slug, OperixApiPaths.salesInvoiceCancel(id),
            mapOf("reason" to reason))

    suspend fun recordSalesPayment(
        slug: String, id: Int, request: RecordPaymentRequest,
    ): SalesInvoice =
        postSingle(slug, OperixApiPaths.salesInvoicePayment(id), request)

    // ═══════════════════════════════════════════════════════════════════════
    // PURCHASE INVOICES
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getPurchaseInvoices(
        slug: String,
        status: String? = null,
        supplierId: Int? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): PaginatedResponse<PurchaseInvoice> = getPaginated(
        slug, OperixApiPaths.PURCHASE_INVOICES,
        mapOf(
            "status" to status, "supplier_id" to supplierId,
            "from" to fromDate, "to" to toDate,
            "page" to page, "per_page" to perPage,
        ),
    )

    suspend fun getPurchaseInvoice(slug: String, id: Int): PurchaseInvoice =
        getSingle(slug, OperixApiPaths.purchaseInvoice(id))

    suspend fun createPurchaseInvoice(
        slug: String, request: CreatePurchaseInvoiceRequest,
    ): PurchaseInvoice =
        postSingle(slug, OperixApiPaths.PURCHASE_INVOICES, request)

    suspend fun updatePurchaseInvoice(
        slug: String, id: Int, request: CreatePurchaseInvoiceRequest,
    ): PurchaseInvoice =
        putSingle(slug, OperixApiPaths.purchaseInvoice(id), request)

    suspend fun deletePurchaseInvoice(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.purchaseInvoice(id))

    suspend fun postPurchaseInvoice(slug: String, id: Int): PurchaseInvoice =
        postSingle(slug, OperixApiPaths.purchaseInvoicePost(id))

    suspend fun cancelPurchaseInvoice(slug: String, id: Int): PurchaseInvoice =
        postSingle(slug, OperixApiPaths.purchaseInvoiceCancel(id))

    suspend fun recordSupplierPayment(
        slug: String, invoiceId: Int, request: RecordPaymentRequest,
    ): PurchaseInvoice =
        postSingle(slug, OperixApiPaths.purchaseInvoicePayment(invoiceId), buildMap {
            put("amount", request.amount)
            put("payment_method_id", request.paymentMethodId)
            put("payment_date", request.paymentDate)
            if (request.notes != null) put("notes", request.notes)
        })

    // ═══════════════════════════════════════════════════════════════════════
    // POS — SHIFTS
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun openShift(slug: String, request: OpenShiftRequest): Shift =
        postSingle(slug, OperixApiPaths.POS_SHIFT_OPEN, request)

    suspend fun getCurrentShift(slug: String): Shift? = runCatching {
        getSingle<Shift>(slug, OperixApiPaths.POS_SHIFT_CURRENT)
    }.getOrNull()

    suspend fun closeShift(slug: String, request: CloseShiftRequest): Shift =
        postSingle(slug, OperixApiPaths.POS_SHIFT_CLOSE, request)

    suspend fun getShiftSummary(slug: String): ShiftSummary =
        getSingle(slug, OperixApiPaths.POS_SHIFT_SUMMARY)

    suspend fun recordCashMovement(
        slug: String, request: RecordCashMovementRequest,
    ): CashMovement =
        postSingle(slug, OperixApiPaths.POS_SHIFT_CASH_MOVEMENTS, request)

    suspend fun getCashMovements(slug: String): List<CashMovement> =
        getList(slug, OperixApiPaths.POS_SHIFT_CASH_MOVEMENTS)

    suspend fun reverseCashMovement(slug: String, movementId: Int): CashMovement =
        postSingle(slug, OperixApiPaths.posCashMovementReverse(movementId))

    // ── POS terminals ─────────────────────────────────────────────────────

    suspend fun getPosTerminals(slug: String): List<PosTerminal> =
        getList(slug, OperixApiPaths.POS_TERMINALS)

    // ═══════════════════════════════════════════════════════════════════════
    // POS — ORDERS
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getPosOrders(
        slug: String,
        shiftId: Int? = null,
        paymentStatus: String? = null,
        fromDate: String? = null,
        toDate: String? = null,
        search: String? = null,
        page: Int = 1,
    ): PaginatedResponse<PosOrder> = getPaginated(
        slug, OperixApiPaths.POS_ORDERS,
        mapOf(
            "shift_id" to shiftId, "payment_status" to paymentStatus,
            "from" to fromDate, "to" to toDate, "search" to search, "page" to page,
        ),
    )

    suspend fun getPosOrder(slug: String, orderId: Int): PosOrder =
        getSingle(slug, OperixApiPaths.posOrder(orderId))

    suspend fun createPosOrder(slug: String, request: CreatePosOrderRequest): PosOrder =
        postSingle(slug, OperixApiPaths.POS_ORDERS, request)

    suspend fun returnPosOrder(slug: String, orderId: Int, reason: String? = null): PosOrder =
        postSingle(slug, OperixApiPaths.posOrderReturn(orderId),
            mapOf("reason" to reason))

    suspend fun getPosOrderReceipt(slug: String, orderId: Int): ReceiptData =
        getSingle(slug, OperixApiPaths.posOrderReceipt(orderId))

    // ── Product lookup ────────────────────────────────────────────────────

    suspend fun lookupBarcode(
        slug: String, barcode: String, inventoryId: Int? = null,
    ): BarcodeProduct {
        val path = buildString {
            append(OperixApiPaths.POS_BARCODE)
            append("?barcode=")
            append(barcode)
            if (inventoryId != null) append("&inventory_id=$inventoryId")
        }
        return getSingle(slug, path)
    }

    suspend fun searchPosProducts(
        slug: String, query: String, inventoryId: Int? = null,
    ): List<Product> =
        getList(slug, OperixApiPaths.POS_SEARCH,
            mapOf("q" to query, "inventory_id" to inventoryId))

    // ═══════════════════════════════════════════════════════════════════════
    // ACCOUNTS
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getAccounts(slug: String, type: String? = null): List<Account> =
        getList(slug, OperixApiPaths.ACCOUNTS, mapOf("type" to type))

    suspend fun getAccount(slug: String, id: Int): Account =
        getSingle(slug, OperixApiPaths.account(id))

    suspend fun getAccountHistory(
        slug: String, accountId: Int,
        fromDate: String? = null, toDate: String? = null,
        page: Int = 1,
    ): AccountHistoryResponse =
        getSingle(slug, "${OperixApiPaths.accountHistory(accountId)}?page=$page" +
            (if (fromDate != null) "&from=$fromDate" else "") +
            (if (toDate != null) "&to=$toDate" else ""))

    suspend fun depositToAccount(slug: String, request: DepositRequest): JsonObject {
        val response = client.post(url(slug, OperixApiPaths.ACCOUNTS_DEPOSIT)) {
            contentType(ContentType.Application.Json)
            setBody(request)
        }
        response.checkError()
        return response.body()
    }

    suspend fun withdrawFromAccount(slug: String, request: WithdrawRequest): JsonObject {
        val response = client.post(url(slug, OperixApiPaths.ACCOUNTS_WITHDRAW)) {
            contentType(ContentType.Application.Json)
            setBody(request)
        }
        response.checkError()
        return response.body()
    }

    suspend fun transferBetweenAccounts(
        slug: String, request: AccountTransferRequest,
    ): AccountTransferResult =
        postSingle(slug, OperixApiPaths.ACCOUNTS_TRANSFER, request)

    // ── GL accounts ───────────────────────────────────────────────────────

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
        mapOf(
            "source_type" to sourceType,
            "from_date" to fromDate, "to_date" to toDate, "page" to page,
        ),
    )

    suspend fun getAccountingPeriods(slug: String): List<AccountingPeriod> =
        getList(slug, OperixApiPaths.ACCOUNTING_PERIODS)

    // ═══════════════════════════════════════════════════════════════════════
    // EXPENSES
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getExpenses(
        slug: String,
        categoryId: Int? = null,
        accountId: Int? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
    ): PaginatedResponse<Expense> = getPaginated(
        slug, OperixApiPaths.EXPENSES,
        mapOf(
            "category_id" to categoryId, "account_id" to accountId,
            "from" to fromDate, "to" to toDate, "page" to page,
        ),
    )

    suspend fun createExpense(slug: String, request: CreateExpenseRequest): Expense =
        postSingle(slug, OperixApiPaths.EXPENSES, request)

    suspend fun updateExpense(slug: String, id: Int, request: CreateExpenseRequest): Expense =
        putSingle(slug, OperixApiPaths.expense(id), request)

    suspend fun deleteExpense(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.expense(id))

    // ── Expense categories ────────────────────────────────────────────────

    suspend fun getExpenseCategories(slug: String): List<ExpenseCategory> =
        getList(slug, OperixApiPaths.EXPENSE_CATEGORIES)

    suspend fun createExpenseCategory(
        slug: String, nameEn: String, nameAr: String? = null,
    ): ExpenseCategory =
        postSingle(slug, OperixApiPaths.EXPENSE_CATEGORIES,
            mapOf("name_en" to nameEn, "name_ar" to nameAr))

    suspend fun updateExpenseCategory(
        slug: String, id: Int, nameEn: String, nameAr: String? = null,
    ): ExpenseCategory =
        putSingle(slug, OperixApiPaths.expenseCategory(id),
            mapOf("name_en" to nameEn, "name_ar" to nameAr))

    suspend fun deleteExpenseCategory(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.expenseCategory(id))

    // ═══════════════════════════════════════════════════════════════════════
    // EMPLOYEES
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getEmployees(slug: String, search: String? = null): List<Employee> =
        getList(slug, OperixApiPaths.EMPLOYEES, mapOf("search" to search))

    suspend fun getEmployee(slug: String, id: Int): Employee =
        getSingle(slug, OperixApiPaths.employee(id))

    suspend fun createEmployee(
        slug: String, request: me.amermahsoub.bfm.shared.data.models.CreateEmployeeRequest,
    ): Employee =
        postSingle(slug, OperixApiPaths.EMPLOYEES, request)

    suspend fun updateEmployee(slug: String, id: Int, body: Map<String, Any?>): Employee =
        putSingle(slug, OperixApiPaths.employee(id), body)

    suspend fun deleteEmployee(slug: String, id: Int) =
        deleteResource(slug, OperixApiPaths.employee(id))

    suspend fun updateEmployeeStatus(
        slug: String, id: Int,
        request: me.amermahsoub.bfm.shared.data.models.UpdateEmployeeStatusRequest,
    ): Employee =
        patchSingle(slug, OperixApiPaths.employeeStatus(id), request)

    // ═══════════════════════════════════════════════════════════════════════
    // SETTINGS — TAXES / PAYMENT METHODS / CURRENCIES
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getTaxes(slug: String): List<Tax> =
        getList(slug, OperixApiPaths.SETTINGS_TAXES)

    suspend fun getTaxConfig(slug: String): TaxConfig =
        getSingle(slug, OperixApiPaths.SETTINGS_TAX_CONFIG)

    /** Active payment methods used at POS checkout */
    suspend fun getActivePaymentMethods(slug: String): List<PaymentMethod> =
        getList(slug, OperixApiPaths.PAYMENT_METHODS_ACTIVE)

    /** All payment methods from settings */
    suspend fun getPaymentMethods(slug: String): List<PaymentMethod> =
        getList(slug, OperixApiPaths.SETTINGS_PAYMENT_METHODS)

    suspend fun getCurrencies(slug: String): List<Currency> =
        getList(slug, OperixApiPaths.SETTINGS_CURRENCIES)

    // ═══════════════════════════════════════════════════════════════════════
    // REPORTS
    // ═══════════════════════════════════════════════════════════════════════

    suspend fun getTrialBalance(
        slug: String, fromDate: String, toDate: String,
    ): List<TrialBalanceRow> = getList(
        slug, OperixApiPaths.REPORT_TRIAL_BALANCE,
        mapOf("from" to fromDate, "to" to toDate),
    )

    suspend fun getIncomeStatement(
        slug: String, fromDate: String, toDate: String,
    ): IncomeStatementReport =
        getSingle(slug, "${OperixApiPaths.REPORT_INCOME_STATEMENT}?from=$fromDate&to=$toDate")

    suspend fun getDailySalesReport(
        slug: String, fromDate: String, toDate: String,
    ): List<DailySalesEntry> = getList(
        slug, OperixApiPaths.REPORT_DAILY_SALES,
        mapOf("from" to fromDate, "to" to toDate),
    )

    suspend fun getArAgingReport(slug: String): AgingReport =
        getSingle(slug, OperixApiPaths.REPORT_AR_AGING)

    suspend fun getApAgingReport(slug: String): AgingReport =
        getSingle(slug, OperixApiPaths.REPORT_AP_AGING)

    suspend fun getAccountStatement(
        slug: String, accountId: Int, fromDate: String, toDate: String,
    ): List<AccountStatementEntry> = getList(
        slug, OperixApiPaths.accountHistory(accountId),
        mapOf("from" to fromDate, "to" to toDate),
    )
}
