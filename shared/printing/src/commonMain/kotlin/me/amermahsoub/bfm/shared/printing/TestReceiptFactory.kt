package me.amermahsoub.bfm.shared.printing

import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime

object TestReceiptFactory {

    @OptIn(ExperimentalTime::class)
    fun create(): Receipt {
        return Receipt(
            storeName = "BFM Market",
            storeAddress = "123 POS Street",
            storePhone = "+1-555-0100",
            invoiceNumber = "12345",
            dateTime = Clock.System.now()
                .toLocalDateTime(TimeZone.currentSystemDefault()),
            cashierName = "Ahmed",
            items = listOf(
                ReceiptItem(name = "Product A", qty = "2", unitPriceCents = 1_000, totalLineCents = 2_000),
                ReceiptItem(name = "Product B", qty = "1", unitPriceCents = 1_500, totalLineCents = 1_500),
            ),
            subtotalCents = 3_500,
            discountCents = 500,
            taxCents = 210,
            totalCents = 3_210,
            paymentMethod = PaymentMethod.CASH,
            paidAmountCents = 5_000,
            changeAmountCents = 1_790,
            footerMessage = "Thank you!",
        )
    }
}