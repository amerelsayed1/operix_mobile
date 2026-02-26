package me.amermahsoub.bfm.shared.printing

class EscPosBuilder(private val config: PrinterConfig = PrinterConfig()) {

    fun buildReceipt(receipt: Receipt): ByteArray {
        val lines = mutableListOf<Byte>()
        lines += EscPosCommands.INIT.toList()

        appendCentered(lines, receipt.storeName.uppercase(), bold = true, doubleSize = true)
        appendCentered(lines, receipt.storeAddress)
        receipt.storePhone?.takeIf { it.isNotBlank() }?.let { appendCentered(lines, it) }
        appendNewLine(lines)

        appendLeft(lines, "Invoice: #${receipt.invoiceNumber}")
        appendLeft(lines, "Date: ${receipt.dateTime}")
        receipt.cashierName?.takeIf { it.isNotBlank() }?.let { appendLeft(lines, "Cashier: $it") }

        appendSeparator(lines)
        appendLeft(lines, formatItemHeader())
        receipt.items.forEach { appendItem(lines, it) }
        appendSeparator(lines)

        appendAmount(lines, "Subtotal:", receipt.subtotalCents)
        if (receipt.discountCents > 0) {
            appendAmount(lines, "Discount:", -receipt.discountCents)
        }
        appendAmount(lines, "Tax:", receipt.taxCents)
        appendAmount(lines, "TOTAL:", receipt.totalCents, bold = true)
        appendAmount(lines, "Payment:", textValue = receipt.paymentMethod.name)
        appendAmount(lines, "Paid:", receipt.paidAmountCents)
        receipt.changeAmountCents?.let { appendAmount(lines, "Change:", it) }

        appendSeparator(lines)
        receipt.footerMessage?.takeIf { it.isNotBlank() }?.let { appendCentered(lines, it) }

        repeat(config.feedLinesAfter) { appendNewLine(lines) }
        if (config.enableCut) {
            lines += EscPosCommands.FULL_CUT.toList()
        }

        return lines.toByteArray()
    }

    private fun appendItem(target: MutableList<Byte>, item: ReceiptItem) {
        val qtyWidth = 5
        val priceWidth = 10
        val totalWidth = 10
        val nameWidth = (config.charsPerLine - qtyWidth - priceWidth - totalWidth).coerceAtLeast(8)

        val wrappedNames = wrapText(item.name, nameWidth)
        wrappedNames.forEachIndexed { index, part ->
            val qty = if (index == 0) item.qty.padStart(qtyWidth) else "".padStart(qtyWidth)
            val price = if (index == 0) centsToMoney(item.unitPriceCents).padStart(priceWidth) else "".padStart(priceWidth)
            val totalLine = if (index == 0) centsToMoney(item.totalLineCents).padStart(totalWidth) else "".padStart(totalWidth)
            appendLeft(target, part.padEnd(nameWidth) + qty + price + totalLine)
        }
    }

    private fun formatItemHeader(): String {
        val qtyWidth = 5
        val priceWidth = 10
        val totalWidth = 10
        val nameWidth = (config.charsPerLine - qtyWidth - priceWidth - totalWidth).coerceAtLeast(8)
        return "Item".padEnd(nameWidth) + "Qty".padStart(qtyWidth) + "Price".padStart(priceWidth) + "Total".padStart(totalWidth)
    }

    private fun appendAmount(
        target: MutableList<Byte>,
        label: String,
        amountCents: Long? = null,
        textValue: String? = null,
        bold: Boolean = false,
    ) {
        val value = textValue ?: centsToMoney(amountCents ?: 0)
        val content = label + value.padStart((config.charsPerLine - label.length).coerceAtLeast(1))
        if (bold) target += EscPosCommands.BOLD_ON.toList()
        appendLeft(target, content)
        if (bold) target += EscPosCommands.BOLD_OFF.toList()
    }

    private fun appendSeparator(target: MutableList<Byte>) {
        appendLeft(target, "-".repeat(config.charsPerLine))
    }

    private fun appendCentered(target: MutableList<Byte>, text: String, bold: Boolean = false, doubleSize: Boolean = false) {
        target += EscPosCommands.ALIGN_CENTER.toList()
        if (bold) target += EscPosCommands.BOLD_ON.toList()
        if (doubleSize) target += EscPosCommands.DOUBLE_SIZE_ON.toList()
        appendEncoded(target, text)
        appendNewLine(target)
        if (doubleSize) target += EscPosCommands.DOUBLE_SIZE_OFF.toList()
        if (bold) target += EscPosCommands.BOLD_OFF.toList()
        target += EscPosCommands.ALIGN_LEFT.toList()
    }

    private fun appendLeft(target: MutableList<Byte>, text: String) {
        target += EscPosCommands.ALIGN_LEFT.toList()
        appendEncoded(target, text)
        appendNewLine(target)
    }

    private fun appendNewLine(target: MutableList<Byte>) {
        target += '\n'.code.toByte()
    }

    private fun appendEncoded(target: MutableList<Byte>, text: String) {
        // UTF-8 works for many network printers, while some models require explicit ESC/POS code-page setup.
        // CP1256 is kept as a config option for forward compatibility; this implementation currently writes UTF-8 bytes.
        val encoded = text.encodeToByteArray()
        target += encoded.toList()
    }

    private fun centsToMoney(cents: Long): String {
        val sign = if (cents < 0) "-" else ""
        val abs = kotlin.math.abs(cents)
        val major = abs / 100
        val minor = abs % 100
        return "$sign$major.${minor.toString().padStart(2, '0')}"
    }

    private fun wrapText(text: String, width: Int): List<String> {
        if (text.length <= width) return listOf(text)
        val chunks = mutableListOf<String>()
        var remaining = text
        while (remaining.isNotBlank()) {
            chunks += remaining.take(width)
            remaining = remaining.drop(width)
        }
        return chunks
    }
}

private object EscPosCommands {
    val INIT = byteArrayOf(0x1B, 0x40)
    val ALIGN_LEFT = byteArrayOf(0x1B, 0x61, 0x00)
    val ALIGN_CENTER = byteArrayOf(0x1B, 0x61, 0x01)
    val BOLD_ON = byteArrayOf(0x1B, 0x45, 0x01)
    val BOLD_OFF = byteArrayOf(0x1B, 0x45, 0x00)
    val DOUBLE_SIZE_ON = byteArrayOf(0x1D, 0x21, 0x11)
    val DOUBLE_SIZE_OFF = byteArrayOf(0x1D, 0x21, 0x00)
    val FULL_CUT = byteArrayOf(0x1D, 0x56, 0x00)
}
