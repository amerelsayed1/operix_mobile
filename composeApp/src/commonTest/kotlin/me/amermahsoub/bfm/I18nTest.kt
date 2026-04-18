package me.amermahsoub.bfm

import androidx.compose.ui.unit.LayoutDirection
import me.amermahsoub.bfm.app.i18n.AppStrings
import me.amermahsoub.bfm.app.i18n.AppStringsRegistry
import me.amermahsoub.bfm.app.i18n.ArStrings
import me.amermahsoub.bfm.app.i18n.EnStrings
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame
import kotlin.test.assertTrue

class I18nTest {

    // ---- Locale codes ----

    @Test
    fun enStrings_localeCodeIsEn() {
        assertEquals("en", EnStrings.localeCode)
    }

    @Test
    fun arStrings_localeCodeIsAr() {
        assertEquals("ar", ArStrings.localeCode)
    }

    // ---- Layout direction ----

    @Test
    fun enStrings_layoutDirectionIsLtr() {
        assertEquals(LayoutDirection.Ltr, EnStrings.layoutDirection)
    }

    @Test
    fun arStrings_layoutDirectionIsRtl() {
        assertEquals(LayoutDirection.Rtl, ArStrings.layoutDirection)
    }

    // ---- AppStringsRegistry ----

    @Test
    fun registry_forLocaleEn_returnsEnStrings() {
        assertSame(EnStrings, AppStringsRegistry.forLocale("en"))
    }

    @Test
    fun registry_forLocaleAr_returnsArStrings() {
        assertSame(ArStrings, AppStringsRegistry.forLocale("ar"))
    }

    @Test
    fun registry_forLocaleNull_returnsEnStringsAsDefault() {
        assertSame(EnStrings, AppStringsRegistry.forLocale(null))
    }

    @Test
    fun registry_forLocaleUppercaseAR_returnsArStrings() {
        assertSame(ArStrings, AppStringsRegistry.forLocale("AR"))
    }

    @Test
    fun registry_forLocaleMixedCaseAr_returnsArStrings() {
        assertSame(ArStrings, AppStringsRegistry.forLocale("Ar"))
    }

    @Test
    fun registry_forLocaleUnknown_returnsEnStringsAsFallback() {
        assertSame(EnStrings, AppStringsRegistry.forLocale("fr"))
    }

    @Test
    fun registry_forLocaleEmptyString_returnsEnStrings() {
        assertSame(EnStrings, AppStringsRegistry.forLocale(""))
    }

    // ---- App name ----

    @Test
    fun enStrings_appNameIsOperix() {
        assertEquals("Operix", EnStrings.appName)
    }

    @Test
    fun arStrings_appNameIsArabic() {
        assertEquals("\u0623\u0648\u0628\u0631\u064A\u0643\u0633", ArStrings.appName)
    }

    // ---- EnStrings representative sample: non-blank ----

    @Test
    fun enStrings_globalStringsAreNonBlank() {
        val strings: AppStrings = EnStrings
        val sample = listOf(
            strings.appName,
            strings.loading,
            strings.retry,
            strings.cancel,
            strings.save,
            strings.delete,
            strings.ok,
            strings.search,
            strings.error,
            strings.logout,
        )
        for ((index, value) in sample.withIndex()) {
            assertTrue(value.isNotBlank(), "EnStrings global string at index $index is blank")
        }
    }

    @Test
    fun enStrings_loginStringsAreNonBlank() {
        val strings: AppStrings = EnStrings
        val sample = listOf(
            strings.loginTitle,
            strings.loginSubtitle,
            strings.companyCode,
            strings.username,
            strings.password,
            strings.accessPortal,
            strings.forgotPassword,
        )
        for ((index, value) in sample.withIndex()) {
            assertTrue(value.isNotBlank(), "EnStrings login string at index $index is blank")
        }
    }

    @Test
    fun enStrings_featureStringsAreNonBlank() {
        val strings: AppStrings = EnStrings
        val sample = listOf(
            strings.tabDashboard,
            strings.posTitle,
            strings.clientsTitle,
            strings.productsTitle,
            strings.expensesTitle,
            strings.accountsTitle,
            strings.profileTitle,
            strings.reportsTitle,
            strings.invoicesTitle,
            strings.suppliersTitle,
            strings.notificationsTitle,
        )
        for ((index, value) in sample.withIndex()) {
            assertTrue(value.isNotBlank(), "EnStrings feature string at index $index is blank")
        }
    }

    // ---- ArStrings representative sample: non-blank ----

    @Test
    fun arStrings_globalStringsAreNonBlank() {
        val strings: AppStrings = ArStrings
        val sample = listOf(
            strings.appName,
            strings.loading,
            strings.retry,
            strings.cancel,
            strings.save,
            strings.delete,
            strings.ok,
            strings.search,
            strings.error,
            strings.logout,
        )
        for ((index, value) in sample.withIndex()) {
            assertTrue(value.isNotBlank(), "ArStrings global string at index $index is blank")
        }
    }

    @Test
    fun arStrings_loginStringsAreNonBlank() {
        val strings: AppStrings = ArStrings
        val sample = listOf(
            strings.loginTitle,
            strings.loginSubtitle,
            strings.companyCode,
            strings.username,
            strings.password,
            strings.accessPortal,
            strings.forgotPassword,
        )
        for ((index, value) in sample.withIndex()) {
            assertTrue(value.isNotBlank(), "ArStrings login string at index $index is blank")
        }
    }

    @Test
    fun arStrings_featureStringsAreNonBlank() {
        val strings: AppStrings = ArStrings
        val sample = listOf(
            strings.tabDashboard,
            strings.posTitle,
            strings.clientsTitle,
            strings.productsTitle,
            strings.expensesTitle,
            strings.accountsTitle,
            strings.profileTitle,
            strings.reportsTitle,
            strings.invoicesTitle,
            strings.suppliersTitle,
            strings.notificationsTitle,
        )
        for ((index, value) in sample.withIndex()) {
            assertTrue(value.isNotBlank(), "ArStrings feature string at index $index is blank")
        }
    }

    // ---- Translations differ between locales ----

    @Test
    fun enAndArStrings_appNamesDiffer() {
        assertTrue(
            EnStrings.appName != ArStrings.appName,
            "English and Arabic appName should differ"
        )
    }

    @Test
    fun enAndArStrings_loginTitlesDiffer() {
        assertTrue(
            EnStrings.loginTitle != ArStrings.loginTitle,
            "English and Arabic loginTitle should differ"
        )
    }
}
