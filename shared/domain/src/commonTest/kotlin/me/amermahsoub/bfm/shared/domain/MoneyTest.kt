package me.amermahsoub.bfm.shared.domain

import me.amermahsoub.bfm.shared.domain.money.Money
import kotlin.test.Test
import kotlin.test.assertEquals

class MoneyTest {

    @Test
    fun toDoubleOrZero_validAmount_returnsDouble() {
        assertEquals(100.5, Money("100.50", "USD").toDoubleOrZero())
    }

    @Test
    fun toDoubleOrZero_zero_returnsZero() {
        assertEquals(0.0, Money("0", "USD").toDoubleOrZero())
    }

    @Test
    fun toDoubleOrZero_invalidAmount_returnsZero() {
        assertEquals(0.0, Money("abc", "USD").toDoubleOrZero())
    }

    @Test
    fun toDoubleOrZero_emptyAmount_returnsZero() {
        assertEquals(0.0, Money("", "USD").toDoubleOrZero())
    }

    @Test
    fun toCents_199() {
        assertEquals(199L, Money("1.99", "USD").toCents())
    }

    @Test
    fun toCents_oneCent() {
        assertEquals(1L, Money("0.01", "USD").toCents())
    }

    @Test
    fun toCents_wholeAmount() {
        assertEquals(10000L, Money("100.00", "USD").toCents())
    }

    @Test
    fun toCents_negativeAmount() {
        assertEquals(-5000L, Money("-50.00", "USD").toCents())
    }

    @Test
    fun formatted_returnsAmountWithCurrency() {
        assertEquals("100.50 USD", Money("100.50", "USD").formatted())
    }

    @Test
    fun formatted_negativeAmount() {
        assertEquals("-50.00 USD", Money("-50.00", "USD").formatted())
    }

    @Test
    fun zero_returnsZeroMoney() {
        val money = Money.zero("SAR")
        assertEquals(Money("0.00", "SAR"), money)
    }

    @Test
    fun fromCents_199_returnsCorrectMoney() {
        assertEquals(Money("1.99", "USD"), Money.fromCents(199, "USD"))
    }

    @Test
    fun fromCents_zero_returnsZeroMoney() {
        assertEquals(Money("0.00", "EUR"), Money.fromCents(0, "EUR"))
    }

    @Test
    fun fromCents_negativeCents() {
        assertEquals(Money("-5.00", "USD"), Money.fromCents(-500, "USD"))
    }

    @Test
    fun format2Decimals_padsFraction() {
        assertEquals("10.50", Money.format2Decimals(10.5))
    }

    @Test
    fun format2Decimals_zero() {
        assertEquals("0.00", Money.format2Decimals(0.0))
    }

    @Test
    fun format2Decimals_roundsUp() {
        assertEquals("100.00", Money.format2Decimals(99.999))
    }

    @Test
    fun format2Decimals_roundsToTwoDecimals() {
        assertEquals("1.24", Money.format2Decimals(1.235))
    }
}
