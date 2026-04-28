package me.amermahsoub.bfm.shared.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PosTerminal(
    val id: Int,
    val name: String,
    @SerialName("slot_number") val slotNumber: Int,
    @SerialName("is_active") val isActive: Boolean = true,
    @SerialName("drawer_account_id") val drawerAccountId: Int? = null,
    @SerialName("drawer_account") val drawerAccount: AccountRef? = null,
)

@Serializable
data class AccountRef(
    val id: Int,
    val name: String,
    val balance: String = "0.00",
)

@Serializable
data class Shift(
    val id: Int,
    @SerialName("terminal_id") val terminalId: Int,
    val terminal: PosTerminal? = null,
    val status: String,
    @SerialName("opening_cash") val openingCash: String,
    @SerialName("closing_cash") val closingCash: String? = null,
    @SerialName("expected_cash") val expectedCash: String? = null,
    @SerialName("cash_variance") val cashVariance: String? = null,
    @SerialName("total_sales") val totalSales: String = "0.00",
    @SerialName("total_refunds") val totalRefunds: String = "0.00",
    @SerialName("opened_at") val openedAt: String? = null,
    @SerialName("closed_at") val closedAt: String? = null,
    @SerialName("opened_by") val openedBy: Int? = null,
    @SerialName("drawer_account_id") val drawerAccountId: Int? = null,
    val notes: String? = null,
) {
    val isOpen get() = status == "open"
    val isClosed get() = status == "closed"
}

@Serializable
data class PosOrderItem(
    val id: Int,
    @SerialName("product_id") val productId: Int,
    @SerialName("variant_id") val variantId: Int? = null,
    val product: Product? = null,
    val quantity: String,
    @SerialName("unit_price") val unitPrice: String,
    val discount: String = "0",
    val subtotal: String,
    val tax: String = "0.00",
    val total: String,
)

@Serializable
data class PosOrderPayment(
    val id: Int,
    val amount: String,
    @SerialName("payment_method_id") val paymentMethodId: Int,
    @SerialName("payment_method") val paymentMethod: PaymentMethodRef? = null,
)

@Serializable
data class PosOrder(
    val id: Int,
    @SerialName("order_number") val orderNumber: String? = null,
    @SerialName("shift_id") val shiftId: Int,
    @SerialName("client_id") val clientId: Int? = null,
    val client: Client? = null,
    val status: String,
    val subtotal: String = "0.00",
    val discount: String = "0.00",
    @SerialName("tax_total") val taxTotal: String = "0.00",
    val total: String = "0.00",
    val items: List<PosOrderItem> = emptyList(),
    val payments: List<PosOrderPayment> = emptyList(),
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class ShiftSummary(
    val shift: Shift,
    @SerialName("total_orders") val totalOrders: Int = 0,
    @SerialName("total_sales") val totalSales: String = "0.00",
    @SerialName("total_refunds") val totalRefunds: String = "0.00",
    @SerialName("total_cash_sales") val totalCashSales: String = "0.00",
    @SerialName("total_card_sales") val totalCardSales: String = "0.00",
    @SerialName("expected_cash") val expectedCash: String = "0.00",
    @SerialName("counted_cash") val countedCash: String? = null,
    @SerialName("cash_variance") val cashVariance: String? = null,
    @SerialName("payment_breakdown") val paymentBreakdown: List<PaymentBreakdown> = emptyList(),
)

@Serializable
data class PaymentBreakdown(
    @SerialName("payment_method") val paymentMethod: String,
    val total: String,
    val count: Int,
)

@Serializable
data class OpenShiftRequest(
    @SerialName("terminal_id") val terminalId: Int,
    @SerialName("opening_cash") val openingCash: Double,
    val notes: String? = null,
)

@Serializable
data class CloseShiftRequest(
    @SerialName("closing_cash") val closingCash: Double,
    val notes: String? = null,
)

@Serializable
data class CreatePosOrderItemRequest(
    @SerialName("product_id") val productId: Int,
    @SerialName("variant_id") val variantId: Int? = null,
    val quantity: Double,
    @SerialName("unit_price") val unitPrice: Double,
    val discount: Double = 0.0,
)

@Serializable
data class CreatePosOrderPaymentRequest(
    @SerialName("payment_method_id") val paymentMethodId: Int,
    val amount: Double,
)

@Serializable
data class CreatePosOrderRequest(
    @SerialName("shift_id") val shiftId: Int,
    @SerialName("client_id") val clientId: Int? = null,
    @SerialName("inventory_id") val inventoryId: Int,
    val items: List<CreatePosOrderItemRequest>,
    val payments: List<CreatePosOrderPaymentRequest>,
    val discount: Double = 0.0,
    val notes: String? = null,
)

@Serializable
data class BarcodeProduct(
    val product: Product,
    @SerialName("product_unit") val productUnit: ProductUnit? = null,
    val inventory: InventoryProduct? = null,
)

// Cart models (local state only, not from API)
data class CartItem(
    val productId: Int,
    val variantId: Int? = null,
    val name: String,
    val unitPrice: Double,
    var quantity: Double,
    var discount: Double = 0.0,
    val imageUrl: String? = null,
) {
    val lineTotal: Double get() = unitPrice * quantity * (1 - discount / 100)
}
