package me.amermahsoub.bfm.shared.data.products

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.common.decodePaginated
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder
import me.amermahsoub.bfm.shared.domain.common.Paginated

@Serializable
data class Product(
    val id: Long,
    val name: String,
    val sku: String? = null,
    val barcode: String? = null,
    val category: ProductCategory? = null,
    @SerialName("selling_price") val sellingPrice: String? = null,
    @SerialName("cost_price") val costPrice: String? = null,
    @SerialName("current_stock") val currentStock: Double? = null,
    @SerialName("minimum_stock_alert") val minimumStockAlert: Double? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("has_variants") val hasVariants: Boolean = false,
    @SerialName("is_active") val isActive: Boolean = true,
    val unit: String? = null,
) {
    val displayPrice: String get() = sellingPrice ?: "0.00"
    val stockLabel: String get() = when {
        (currentStock ?: 0.0) <= 0.0 -> "Out of stock"
        minimumStockAlert != null && (currentStock ?: 0.0) <= minimumStockAlert -> "Low stock"
        else -> "In stock"
    }
}

@Serializable
data class ProductCategory(
    val id: Long,
    val name: String,
)

@Serializable
data class ProductTransaction(
    val id: Long,
    val type: String,
    val quantity: Double,
    @SerialName("balance_after") val balanceAfter: Double? = null,
    val reference: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

class ProductsApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun list(
        search: String? = null,
        categoryId: Long? = null,
        isActive: Boolean? = null,
        page: Int = 1,
        perPage: Int = 20,
    ): Paginated<Product> =
        json.decodePaginated(Product.serializer()) {
            client.get(urls.products()) {
                search?.let { parameter("search", it) }
                categoryId?.let { parameter("category", it) }
                isActive?.let { parameter("is_active", it) }
                parameter("page", page)
                parameter("per_page", perPage)
            }
        }

    suspend fun get(id: Long): Product =
        json.decodeData(Product.serializer()) { client.get(urls.productById(id)) }

    suspend fun categories(): List<ProductCategory> =
        json.decodeData(ListSerializer(ProductCategory.serializer())) {
            client.get(urls.productCategories())
        }

    suspend fun transactions(productId: Long): List<ProductTransaction> =
        json.decodeData(ListSerializer(ProductTransaction.serializer())) {
            client.get(urls.productTransactions(productId))
        }
}
