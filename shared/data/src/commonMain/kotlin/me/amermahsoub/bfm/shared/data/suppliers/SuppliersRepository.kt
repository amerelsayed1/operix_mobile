package me.amermahsoub.bfm.shared.data.suppliers

import me.amermahsoub.bfm.shared.domain.common.Paginated

class SuppliersRepository(private val api: SuppliersApi) {
    suspend fun list(page: Int = 1, search: String? = null) = api.list(page, search)
    suspend fun get(id: Long) = api.get(id)
    suspend fun create(req: SupplierCreateRequest) = api.create(req)
    suspend fun update(id: Long, req: SupplierCreateRequest) = api.update(id, req)
    suspend fun purchaseOrders(page: Int = 1) = api.purchaseOrders(page)
    suspend fun getPurchaseOrder(id: Long) = api.getPurchaseOrder(id)
    suspend fun createPurchaseOrder(req: PurchaseOrderCreateRequest) = api.createPurchaseOrder(req)
}
