package me.amermahsoub.bfm.shared.data.suppliers

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Supplier(
    val id: Long,
    val name: String = "",
    val phone: String? = null,
    val email: String? = null,
    val address: String? = null,
    @SerialName("contact_person") val contactPerson: String? = null,
    @SerialName("tax_number") val taxNumber: String? = null,
    val balance: String? = null,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class SupplierCreateRequest(
    val name: String,
    val phone: String? = null,
    val email: String? = null,
    val address: String? = null,
    @SerialName("contact_person") val contactPerson: String? = null,
    @SerialName("tax_number") val taxNumber: String? = null,
)

@Serializable
data class PurchaseOrder(
    val id: Long,
    @SerialName("purchase_order_number") val purchaseOrderNumber: String? = null,
    @SerialName("supplier_id") val supplierId: Long? = null,
    @SerialName("supplier_name") val supplierName: String? = null,
    val status: String? = null,
    val total: String? = null,
    @SerialName("paid_amount") val paidAmount: String? = null,
    @SerialName("due_amount") val dueAmount: String? = null,
    val date: String? = null,
    val note: String? = null,
    val items: List<PurchaseOrderItem> = emptyList(),
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class PurchaseOrderItem(
    val id: Long? = null,
    @SerialName("product_id") val productId: Long? = null,
    @SerialName("product_name") val productName: String? = null,
    val quantity: Double = 0.0,
    @SerialName("unit_cost") val unitCost: String? = null,
    val total: String? = null,
)

@Serializable
data class PurchaseOrderCreateRequest(
    @SerialName("supplier_id") val supplierId: Long,
    val date: String,
    @SerialName("inventory_id") val inventoryId: Long? = null,
    val items: List<PurchaseOrderItemRequest>,
    val note: String? = null,
)

@Serializable
data class PurchaseOrderItemRequest(
    @SerialName("product_id") val productId: Long,
    val quantity: Double,
    @SerialName("unit_cost") val unitCost: String,
)
