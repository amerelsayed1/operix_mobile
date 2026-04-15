package me.amermahsoub.bfm.shared.data.pos

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PosProduct(
    val id: Long,
    val name: String,
    val sku: String? = null,
    val barcode: String? = null,
    @SerialName("selling_price") val sellingPrice: String? = null,
    val price: String? = null,
    @SerialName("current_stock") val currentStock: Double? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    val category: String? = null,
    @SerialName("has_variants") val hasVariants: Boolean = false,
    @SerialName("is_active") val isActive: Boolean = true,
) {
    val displayPrice: String get() = sellingPrice ?: price ?: "0.00"
    val inStock: Boolean get() = (currentStock ?: 0.0) > 0.0
}

@Serializable
data class PaymentMethodDto(
    val id: Long,
    val name: String,
    val code: String? = null,
    @SerialName("requires_account") val requiresAccount: Boolean = false,
    @SerialName("is_active") val isActive: Boolean = true,
)

@Serializable
data class PosAccountDto(
    val id: Long,
    val name: String,
    val type: String? = null,
    @SerialName("current_balance") val currentBalance: String? = null,
    @SerialName("is_drawer") val isDrawer: Boolean = false,
)

@Serializable
data class TaxDto(
    val id: Long,
    val name: String,
    val rate: Double,
    val code: String? = null,
)

// --- Shift -----------------------------------------------------------------

@Serializable
data class ShiftOpenRequest(
    @SerialName("terminal_id") val terminalId: Long? = null,
    @SerialName("drawer_account_id") val drawerAccountId: Long? = null,
    @SerialName("opening_cash") val openingCash: String,
    val note: String? = null,
)

@Serializable
data class ShiftCloseRequest(
    @SerialName("actual_cash") val actualCash: String,
    @SerialName("variance_notes") val varianceNotes: String? = null,
)

@Serializable
data class Shift(
    val id: Long,
    @SerialName("terminal_id") val terminalId: Long? = null,
    @SerialName("drawer_account_id") val drawerAccountId: Long? = null,
    val status: String,
    @SerialName("opened_at") val openedAt: String? = null,
    @SerialName("closed_at") val closedAt: String? = null,
    @SerialName("opened_by") val openedBy: String? = null,
    @SerialName("closed_by") val closedBy: String? = null,
    @SerialName("opening_cash") val openingCash: String? = null,
    @SerialName("expected_cash") val expectedCash: String? = null,
    @SerialName("counted_cash") val countedCash: String? = null,
    val variance: String? = null,
    val notes: String? = null,
)

@Serializable
data class ShiftSummary(
    @SerialName("total_sales") val totalSales: String? = null,
    @SerialName("total_orders") val totalOrders: Int? = null,
    @SerialName("cash_in") val cashIn: String? = null,
    @SerialName("cash_out") val cashOut: String? = null,
    @SerialName("expected_cash") val expectedCash: String? = null,
)

@Serializable
data class CashMovementRequest(
    val type: String, // "in" | "out"
    val amount: String,
    val reason: String,
    @SerialName("account_id") val accountId: Long? = null,
    @SerialName("payment_method_id") val paymentMethodId: Long? = null,
    val notes: String? = null,
)

@Serializable
data class CashMovement(
    val id: Long,
    val type: String,
    val amount: String,
    val reason: String,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("created_by") val createdBy: String? = null,
)

// --- Orders ----------------------------------------------------------------

@Serializable
data class PosOrderItemRequest(
    @SerialName("product_id") val productId: Long,
    @SerialName("product_variant_id") val productVariantId: Long? = null,
    val quantity: Double,
    @SerialName("unit_price") val unitPrice: String,
)

@Serializable
data class PosOrderCreateRequest(
    @SerialName("client_id") val clientId: Long? = null,
    @SerialName("inventory_id") val inventoryId: Long,
    val date: String,
    val items: List<PosOrderItemRequest>,
    @SerialName("discount_type") val discountType: String? = null,
    @SerialName("discount_value") val discountValue: Double? = null,
    @SerialName("tax_id") val taxId: Long? = null,
    @SerialName("payment_method_id") val paymentMethodId: Long? = null,
    @SerialName("paid_amount") val paidAmount: String,
    @SerialName("account_id") val accountId: Long? = null,
    val note: String? = null,
)

@Serializable
data class PosOrderItem(
    val id: Long,
    @SerialName("product_id") val productId: Long,
    @SerialName("product_name") val productName: String? = null,
    @SerialName("product_variant_id") val productVariantId: Long? = null,
    val quantity: Double,
    @SerialName("unit_price") val unitPrice: String,
    @SerialName("line_total") val lineTotal: String? = null,
    @SerialName("returned_quantity") val returnedQuantity: Double? = null,
)

@Serializable
data class PosOrder(
    val id: Long,
    @SerialName("receipt_number") val receiptNumber: String? = null,
    @SerialName("client_id") val clientId: Long? = null,
    @SerialName("client_name") val clientName: String? = null,
    @SerialName("inventory_id") val inventoryId: Long? = null,
    val subtotal: String? = null,
    @SerialName("discount_total") val discountTotal: String? = null,
    @SerialName("tax_total") val taxTotal: String? = null,
    @SerialName("grand_total") val grandTotal: String? = null,
    @SerialName("paid_amount") val paidAmount: String? = null,
    @SerialName("due_amount") val dueAmount: String? = null,
    @SerialName("payment_status") val paymentStatus: String? = null,
    val status: String? = null,
    val items: List<PosOrderItem> = emptyList(),
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class PosOrderCreatedResponse(
    val message: String? = null,
    @SerialName("pos_order") val posOrder: PosOrder? = null,
)
