package me.amermahsoub.bfm.shared.data.tenant

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TenantValidationTest {

    @Test
    fun validSlugMinLength() {
        assertTrue(isValidTenantSlug("abc"))
    }

    @Test
    fun validSlugWithHyphen() {
        assertTrue(isValidTenantSlug("my-company"))
    }

    @Test
    fun validSlugWithNumbers() {
        assertTrue(isValidTenantSlug("company-123"))
    }

    @Test
    fun validSlugThreeCharsWithHyphen() {
        assertTrue(isValidTenantSlug("a-b"))
    }

    @Test
    fun validSlugMaxLength() {
        val slug = "a".repeat(50)
        assertTrue(isValidTenantSlug(slug))
    }

    @Test
    fun invalidSlugEmpty() {
        assertFalse(isValidTenantSlug(""))
    }

    @Test
    fun invalidSlugTooShort() {
        assertFalse(isValidTenantSlug("ab"))
    }

    @Test
    fun invalidSlugUppercase() {
        assertFalse(isValidTenantSlug("ABC"))
    }

    @Test
    fun invalidSlugUnderscore() {
        assertFalse(isValidTenantSlug("my_company"))
    }

    @Test
    fun invalidSlugSpace() {
        assertFalse(isValidTenantSlug("my company"))
    }

    @Test
    fun invalidSlugDot() {
        assertFalse(isValidTenantSlug("my.company"))
    }

    @Test
    fun invalidSlugTooLong() {
        val slug = "a".repeat(51)
        assertFalse(isValidTenantSlug(slug))
    }

    @Test
    fun invalidSlugSpecialChars() {
        assertFalse(isValidTenantSlug("abc!"))
    }
}
