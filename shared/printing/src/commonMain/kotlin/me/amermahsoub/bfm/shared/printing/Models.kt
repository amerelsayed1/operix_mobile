package me.amermahsoub.bfm.shared.printing

import kotlinx.datetime.LocalDateTime

data class Receipt(
    val storeName: String,
    val storeAddress: String,
    val storePhone: String? = null,
    val invoiceNumber: String,
    val dateTime: LocalDateTime,
    val cashierName: String? = null,
    val items: List<ReceiptItem>,
    val subtotalCents: Long,
    val discountCents: Long,
    val taxCents: Long,
    val totalCents: Long,
    val paymentMethod: PaymentMethod,
    val paidAmountCents: Long,
    val changeAmountCents: Long? = null,
    val footerMessage: String? = null,
)

data class ReceiptItem(
    val name: String,
    val qty: String,
    val unitPriceCents: Long,
    val totalLineCents: Long,
)

enum class PaymentMethod {
    CASH,
    VISA,
    WALLET,
}

enum class PrinterEncoding {
    UTF8,
    CP1256,
}

data class PrinterConfig(
    val charsPerLine: Int = 42,
    val enableCut: Boolean = true,
    val feedLinesAfter: Int = 3,
    val encoding: PrinterEncoding = PrinterEncoding.UTF8,
)
