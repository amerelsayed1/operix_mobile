package me.amermahsoub.bfm.shared.printing

import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertFalse
import kotlinx.datetime.LocalDateTime

class EscPosBuilderTest {

    @Test
    fun `build receipt includes init cut and expected text`() {
        val builder = EscPosBuilder(PrinterConfig(charsPerLine = 42, enableCut = true))
        val receipt = sampleReceipt()

        val bytes = builder.buildReceipt(receipt)
        val text = bytes.decodeToString()

        assertContains(text, "BFM MARKET")
        assertContains(text, "Invoice: #12345")
        assertContains(text, "TOTAL:")
        assertContains(text, "Thank you!")
        assert(bytes[0] == 0x1B.toByte() && bytes[1] == 0x40.toByte())
        assert(bytes.takeLast(3).toByteArray().contentEquals(byteArrayOf(0x1D, 0x56, 0x00)))
    }

    @Test
    fun `long product names are wrapped while alignment stays intact`() {
        val builder = EscPosBuilder(PrinterConfig(charsPerLine = 32, enableCut = false))
        val receipt = sampleReceipt().copy(
            items = listOf(
                ReceiptItem(
                    name = "Very Long Product Name For Alignment Validation",
                    qty = "2",
                    unitPriceCents = 1_000,
                    totalLineCents = 2_000,
                ),
            ),
        )

        val text = builder.buildReceipt(receipt).decodeToString()
        // nameWidth = (32 - 5 - 10 - 10).coerceAtLeast(8) = 8
        val firstChunk = text.lines().firstOrNull { it.contains("Very Lon") }
        val secondChunk = text.lines().firstOrNull { it.contains("g Produc") }

        assertFalse(firstChunk.isNullOrBlank())
        assertFalse(secondChunk.isNullOrBlank())
        assertContains(text, "2")
        assertContains(text, "10.00")
        assertContains(text, "20.00")
    }

    private fun sampleReceipt() = Receipt(
        storeName = "BFM Market",
        storeAddress = "123 POS Street",
        storePhone = "+1-555-0100",
        invoiceNumber = "12345",
        dateTime = LocalDateTime(2026, 2, 27, 21, 30),
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
