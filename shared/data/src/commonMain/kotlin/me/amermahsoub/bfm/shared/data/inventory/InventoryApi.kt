package me.amermahsoub.bfm.shared.data.inventory

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.patch
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.common.decodePaginated
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder
import me.amermahsoub.bfm.shared.domain.common.Paginated

@Serializable
data class Inventory(
    val id: Long,
    val name: String,
    val location: String? = null,
    @SerialName("branch_id") val branchId: Long? = null,
    @SerialName("is_default") val isDefault: Boolean = false,
    @SerialName("product_count") val productCount: Int? = null,
    @SerialName("total_stock") val totalStock: Double? = null,
    @SerialName("low_stock_count") val lowStockCount: Int? = null,
)

@Serializable
data class InventoryProduct(
    val id: Long,
    @SerialName("product_id") val productId: Long,
    @SerialName("product_name") val productName: String? = null,
    val sku: String? = null,
    val quantity: Double,
    @SerialName("min_threshold") val minThreshold: Double? = null,
    @SerialName("is_low_stock") val isLowStock: Boolean = false,
)

class InventoryApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun list(): List<Inventory> =
        json.decodeData(ListSerializer(Inventory.serializer())) { client.get(urls.inventories()) }

    suspend fun default(): Inventory =
        json.decodeData(Inventory.serializer()) { client.get(urls.defaultInventory()) }

    suspend fun get(id: Long): Inventory =
        json.decodeData(Inventory.serializer()) { client.get(urls.inventoryById(id)) }

    suspend fun products(inventoryId: Long, page: Int = 1, perPage: Int = 20): Paginated<InventoryProduct> =
        json.decodePaginated(InventoryProduct.serializer()) {
            client.get(urls.inventoryProducts(inventoryId)) {
                parameter("page", page)
                parameter("per_page", perPage)
            }
        }

    suspend fun updateMinThreshold(productId: Long, inventoryId: Long, min: Double): InventoryProduct {
        val payload = buildJsonObject { put("min_threshold", min) }
        val path = "${urls.productById(productId)}/inventories/$inventoryId/min-threshold"
        return json.decodeData(InventoryProduct.serializer()) {
            client.patch(path) {
                contentType(ContentType.Application.Json)
                setBody(payload)
            }
        }
    }
}
