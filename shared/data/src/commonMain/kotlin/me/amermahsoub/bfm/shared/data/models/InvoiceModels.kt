package me.amermahsoub.bfm.shared.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Client(
    val id: Int,
    val name: String,
    val phone: String? = null,
    val email: String? = null,
    val address: String? = null,
    @SerialName("tax_number") val taxNumber: String? = null,
    @SerialName("credit_limit") val creditLimit: String = "0.00",
    val balance: String = "0.00",
    @SerialName("is_active") val isActive: Boolean = true,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class Supplier(
    val id: Int,
    @SerialName("company_name") val companyName: String,
    @SerialName("contact_name") val contactName: String? = null,
    val phone: String? = null,
    val email: String? = null,
    val address: String? = null,
    @SerialName("tax_number") val taxNumber: String? = null,
    @SerialName("payable_balance") val payableBalance: String = "0.00",
    @SerialName("payment_terms") val paymentTerms: Int? = null,
    @SerialName("is_active") val isActive: Boolean = true,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class InvoiceItem(
    val id: Int,
    @SerialName("product_id") val productId: Int,
    val product: Product? = null,
    val quantity: String,
    @SerialName("unit_price") val unitPrice: String,
    val discount: String = "0",
    val subtotal: String,
    val tax: String = "0.00",
    val total: String,
    val notes: String? = null,
)

@Serializable
data class InvoicePayment(
    val id: Int,
    val amount: String,
    @SerialName("payment_date") val paymentDate: String,
    @SerialName("payment_method_id") val paymentMethodId: Int,
    @SerialName("payment_method") val paymentMethod: PaymentMethodRef? = null,
    val notes: String? = null,
)

@Serializable
data class PaymentMethodRef(
    val id: Int,
    @SerialName("name_en") val nameEn: String? = null,
    @SerialName("name_ar") val nameAr: String? = null,
    val type: String? = null,
)

@Serializable
data class SalesInvoice(
    val id: Int,
    @SerialName("invoice_number") val invoiceNumber: String,
    @SerialName("client_id") val clientId: Int? = null,
    val client: Client? = null,
    val status: String,
    @SerialName("invoice_date") val invoiceDate: String,
    @SerialName("due_date") val dueDate: String? = null,
    val subtotal: String = "0.00",
    val discount: String = "0.00",
    @SerialName("tax_total") val taxTotal: String = "0.00",
    val total: String = "0.00",
    @SerialName("paid_amount") val paidAmount: String = "0.00",
    @SerialName("remaining_amount") val remainingAmount: String = "0.00",
    val notes: String? = null,
    val items: List<InvoiceItem> = emptyList(),
    val payments: List<InvoicePayment> = emptyList(),
    @SerialName("created_at") val createdAt: String? = null,
) {
    val isPaid get() = status == "paid"
    val isPosted get() = status == "posted" || status == "partial" || status == "paid"
    val isDraft get() = status == "draft"
    val isCancelled get() = status == "cancelled"
}

@Serializable
data class PurchaseInvoice(
    val id: Int,
    @SerialName("invoice_number") val invoiceNumber: String,
    @SerialName("supplier_id") val supplierId: Int? = null,
    val supplier: Supplier? = null,
    val status: String,
    @SerialName("invoice_date") val invoiceDate: String,
    @SerialName("due_date") val dueDate: String? = null,
    @SerialName("supplier_invoice_number") val supplierInvoiceNumber: String? = null,
    val subtotal: String = "0.00",
    val discount: String = "0.00",
    @SerialName("tax_total") val taxTotal: String = "0.00",
    val total: String = "0.00",
    @SerialName("paid_amount") val paidAmount: String = "0.00",
    @SerialName("remaining_amount") val remainingAmount: String = "0.00",
    val notes: String? = null,
    val items: List<InvoiceItem> = emptyList(),
    val payments: List<InvoicePayment> = emptyList(),
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class CreateInvoiceItemRequest(
    @SerialName("product_id") val productId: Int,
    val quantity: Double,
    @SerialName("unit_price") val unitPrice: Double,
    val discount: Double = 0.0,
    val notes: String? = null,
)

@Serializable
data class CreateSalesInvoiceRequest(
    @SerialName("client_id") val clientId: Int,
    @SerialName("invoice_date") val invoiceDate: String,
    @SerialName("due_date") val dueDate: String? = null,
    @SerialName("inventory_id") val inventoryId: Int,
    val items: List<CreateInvoiceItemRequest>,
    val discount: Double = 0.0,
    val notes: String? = null,
)

@Serializable
data class CreatePurchaseInvoiceRequest(
    @SerialName("supplier_id") val supplierId: Int,
    @SerialName("invoice_date") val invoiceDate: String,
    @SerialName("due_date") val dueDate: String? = null,
    @SerialName("inventory_id") val inventoryId: Int,
    @SerialName("supplier_invoice_number") val supplierInvoiceNumber: String? = null,
    val items: List<CreateInvoiceItemRequest>,
    val notes: String? = null,
)

@Serializable
data class RecordPaymentRequest(
    val amount: Double,
    @SerialName("payment_method_id") val paymentMethodId: Int,
    @SerialName("payment_date") val paymentDate: String,
    val notes: String? = null,
)
