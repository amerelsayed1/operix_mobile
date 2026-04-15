package me.amermahsoub.bfm.shared.data.pos

import me.amermahsoub.bfm.shared.domain.common.Paginated

class PosRepository(
    private val api: PosApi,
) {
    suspend fun loadReferenceData(): PosReferenceData {
        val products = runCatching { api.products(search = null) }.getOrElse { Paginated.empty() }
        val paymentMethods = runCatching { api.paymentMethods() }.getOrElse { emptyList() }
        val accounts = runCatching { api.accounts() }.getOrElse { emptyList() }
        val taxes = runCatching { api.taxes() }.getOrElse { emptyList() }
        return PosReferenceData(products.data, paymentMethods, accounts, taxes)
    }

    suspend fun searchProducts(query: String): List<PosProduct> =
        runCatching { api.products(search = query.ifBlank { null }).data }.getOrElse { emptyList() }

    suspend fun currentShift(): Shift? = api.currentShift()

    suspend fun openShift(req: ShiftOpenRequest): Shift = api.openShift(req)
    suspend fun closeShift(req: ShiftCloseRequest): Shift = api.closeShift(req)
    suspend fun shiftSummary(): ShiftSummary = api.shiftSummary()
    suspend fun shiftHistory(page: Int = 1) = api.shiftHistory(page)
    suspend fun addCashMovement(req: CashMovementRequest) = api.addCashMovement(req)
    suspend fun availableDrawers() = api.availableDrawers()

    suspend fun listOrders(page: Int = 1) = api.listOrders(page = page)
    suspend fun createOrder(req: PosOrderCreateRequest) = api.createOrder(req)
    suspend fun getOrder(id: Long) = api.getOrder(id)
    suspend fun returnOrder(id: Long, items: List<PosOrderItemRequest>, reason: String? = null) =
        api.returnOrder(id, items, reason)
}

data class PosReferenceData(
    val products: List<PosProduct>,
    val paymentMethods: List<PaymentMethodDto>,
    val accounts: List<PosAccountDto>,
    val taxes: List<TaxDto>,
)
