package me.amermahsoub.bfm.shared.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ProductCategory(
    val id: Int,
    @SerialName("name_en") val nameEn: String? = null,
    @SerialName("name_ar") val nameAr: String? = null,
    val name: String? = null,
) {
    fun displayName(locale: String = "en") =
        if (locale == "ar") nameAr ?: nameEn ?: name ?: "" else nameEn ?: name ?: nameAr ?: ""
}

@Serializable
data class Unit(
    val id: Int,
    @SerialName("name_en") val nameEn: String? = null,
    @SerialName("name_ar") val nameAr: String? = null,
    val name: String? = null,
) {
    fun displayName(locale: String = "en") =
        if (locale == "ar") nameAr ?: nameEn ?: name ?: "" else nameEn ?: name ?: nameAr ?: ""
}

@Serializable
data class ProductUnit(
    val id: Int,
    @SerialName("unit_id") val unitId: Int,
    val unit: Unit? = null,
    val barcode: String? = null,
    @SerialName("is_default") val isDefault: Boolean = false,
    @SerialName("conversion_factor") val conversionFactor: Double = 1.0,
)

@Serializable
data class ProductVariant(
    val id: Int,
    @SerialName("product_id") val productId: Int,
    val sku: String? = null,
    val barcode: String? = null,
    @SerialName("cost_price") val costPrice: String = "0.00",
    @SerialName("selling_price") val sellingPrice: String = "0.00",
    @SerialName("is_active") val isActive: Boolean = true,
    val attributes: Map<String, String> = emptyMap(),
)

@Serializable
data class Product(
    val id: Int,
    @SerialName("tenant_id") val tenantId: Int? = null,
    val name: String,
    val sku: String? = null,
    val barcode: String? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("cost_price") val costPrice: String = "0.00",
    @SerialName("selling_price") val sellingPrice: String = "0.00",
    @SerialName("minimum_stock_alert") val minimumStockAlert: Int = 0,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("has_variants") val hasVariants: Boolean = false,
    @SerialName("product_category_id") val productCategoryId: Int? = null,
    val category: ProductCategory? = null,
    @SerialName("unit_id") val unitId: Int? = null,
    val unit: Unit? = null,
    val units: List<ProductUnit> = emptyList(),
    val variants: List<ProductVariant> = emptyList(),
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class ProductListResponse(
    val data: List<Product> = emptyList(),
    val meta: PaginationMeta? = null,
)

@Serializable
data class InventoryProduct(
    val id: Int,
    @SerialName("product_id") val productId: Int,
    @SerialName("inventory_id") val inventoryId: Int,
    val product: Product? = null,
    val quantity: String = "0",
    @SerialName("reserved_quantity") val reservedQuantity: String = "0",
)
