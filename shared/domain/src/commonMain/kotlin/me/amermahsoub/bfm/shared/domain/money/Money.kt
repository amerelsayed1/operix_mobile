package me.amermahsoub.bfm.shared.domain.money

/**
 * Money is kept as a string in the domain to preserve precision across the wire.
 * The API returns and accepts amounts as decimal strings like "100.50".
 *
 * For arithmetic, convert to [toCents] and back. All mobile calculations are
 * advisory only — the server is authoritative.
 */
data class Money(
    val amount: String,
    val currencyCode: String,
) {
    fun toDoubleOrZero(): Double = amount.toDoubleOrNull() ?: 0.0

    fun toCents(): Long {
        val value = toDoubleOrZero()
        return (value * 100).toLong()
    }

    fun formatted(): String = "${format2Decimals(toDoubleOrZero())} $currencyCode"

    companion object {
        fun zero(currencyCode: String): Money = Money("0.00", currencyCode)

        fun fromCents(cents: Long, currencyCode: String): Money =
            Money(format2Decimals(cents / 100.0), currencyCode)

        fun format2Decimals(value: Double): String {
            val rounded = kotlin.math.round(value * 100) / 100.0
            val whole = rounded.toLong()
            val fraction = kotlin.math.round(kotlin.math.abs(rounded - whole) * 100).toLong()
            val fractionPadded = fraction.toString().padStart(2, '0')
            return "$whole.$fractionPadded"
        }
    }
}
