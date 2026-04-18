package me.amermahsoub.bfm.shared.data.inventory

class InventoryRepository(private val api: InventoryApi) {
    suspend fun list() = api.list()
    suspend fun default() = api.default()
    suspend fun get(id: Long) = api.get(id)
    suspend fun products(inventoryId: Long, page: Int = 1) = api.products(inventoryId, page)
    suspend fun updateMinThreshold(productId: Long, inventoryId: Long, min: Double) =
        api.updateMinThreshold(productId, inventoryId, min)
}
