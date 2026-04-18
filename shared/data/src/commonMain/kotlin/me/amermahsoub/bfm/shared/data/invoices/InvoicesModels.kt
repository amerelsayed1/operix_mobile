package me.amermahsoub.bfm.shared.data.invoices

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Invoice(
    val id: Long,
    @SerialName("invoice_number") val invoiceNumber: String? = null,
    @SerialName("order_id") val orderId: Long? = null,
    @SerialName("client_id") val clientId: Long? = null,
    @SerialName("client_name") val clientName: String? = null,
    val status: String? = null,
    val subtotal: String? = null,
    val discount: String? = null,
    val tax: String? = null,
    val total: String? = null,
    @SerialName("paid_amount") val paidAmount: String? = null,
    @SerialName("due_amount") val dueAmount: String? = null,
    @SerialName("issue_date") val issueDate: String? = null,
    @SerialName("due_date") val dueDate: String? = null,
    val note: String? = null,
    val items: List<InvoiceItem> = emptyList(),
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class InvoiceItem(
    val id: Long? = null,
    @SerialName("product_id") val productId: Long? = null,
    @SerialName("product_name") val productName: String? = null,
    val quantity: Double = 0.0,
    @SerialName("unit_price") val unitPrice: String? = null,
    val total: String? = null,
)

@Serializable
data class InvoiceCreateRequest(
    @SerialName("order_id") val orderId: Long? = null,
    @SerialName("client_id") val clientId: Long? = null,
    @SerialName("due_date") val dueDate: String? = null,
    val note: String? = null,
)
