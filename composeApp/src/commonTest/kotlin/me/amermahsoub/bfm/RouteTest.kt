package me.amermahsoub.bfm

import me.amermahsoub.bfm.app.nav.Route
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class RouteTest {

    // ---- Singletons (data objects) ----

    @Test
    fun login_isSingleton() {
        assertSame(Route.Login, Route.Login)
    }

    @Test
    fun home_isSingleton() {
        assertSame(Route.Home, Route.Home)
    }

    @Test
    fun posCart_isSingleton() {
        assertSame(Route.PosCart, Route.PosCart)
    }

    @Test
    fun reports_isSingleton() {
        assertSame(Route.Reports, Route.Reports)
    }

    // ---- InvoiceDetail ----

    @Test
    fun invoiceDetail_carriesIdCorrectly() {
        val detail = Route.InvoiceDetail(id = 99L)
        assertEquals(99L, detail.id)
    }

    @Test
    fun invoiceDetail_sameIdAreEqual() {
        val a = Route.InvoiceDetail(id = 42L)
        val b = Route.InvoiceDetail(id = 42L)
        assertEquals(a, b)
    }

    @Test
    fun invoiceDetail_differentIdsAreNotEqual() {
        val a = Route.InvoiceDetail(id = 1L)
        val b = Route.InvoiceDetail(id = 2L)
        assertNotEquals(a, b)
    }

    @Test
    fun invoiceDetail_hashCodeConsistentWithEquals() {
        val a = Route.InvoiceDetail(id = 42L)
        val b = Route.InvoiceDetail(id = 42L)
        assertEquals(a.hashCode(), b.hashCode())
    }

    // ---- SupplierForm ----

    @Test
    fun supplierForm_defaultIdIsNull() {
        val form = Route.SupplierForm()
        assertNull(form.id)
    }

    @Test
    fun supplierForm_withId_carriesItCorrectly() {
        val form = Route.SupplierForm(id = 7L)
        assertEquals(7L, form.id)
    }

    @Test
    fun supplierForm_withNullAndWithIdAreNotEqual() {
        val a = Route.SupplierForm()
        val b = Route.SupplierForm(id = 1L)
        assertNotEquals(a, b)
    }

    @Test
    fun supplierForm_sameIdAreEqual() {
        val a = Route.SupplierForm(id = 5L)
        val b = Route.SupplierForm(id = 5L)
        assertEquals(a, b)
    }

    @Test
    fun supplierForm_bothNullAreEqual() {
        val a = Route.SupplierForm()
        val b = Route.SupplierForm()
        assertEquals(a, b)
    }

    // ---- ClientForm default id ----

    @Test
    fun clientForm_defaultIdIsNull() {
        val form = Route.ClientForm()
        assertNull(form.id)
    }

    @Test
    fun clientForm_withId_carriesItCorrectly() {
        val form = Route.ClientForm(id = 10L)
        assertEquals(10L, form.id)
    }

    // ---- ExpenseForm default id ----

    @Test
    fun expenseForm_defaultIdIsNull() {
        val form = Route.ExpenseForm()
        assertNull(form.id)
    }

    // ---- Distinct Route subtypes ----

    @Test
    fun login_isNotEqualToHome() {
        assertNotEquals<Route>(Route.Login, Route.Home)
    }

    @Test
    fun home_isNotEqualToPosCart() {
        assertNotEquals<Route>(Route.Home, Route.PosCart)
    }

    @Test
    fun login_isNotEqualToReports() {
        assertNotEquals<Route>(Route.Login, Route.Reports)
    }

    @Test
    fun invoiceDetail_isNotEqualToLogin() {
        val detail: Route = Route.InvoiceDetail(id = 1L)
        assertFalse(detail == Route.Login)
    }

    // ---- Type checks ----

    @Test
    fun login_isRouteSubtype() {
        val route: Route = Route.Login
        assertIs<Route.Login>(route)
    }

    @Test
    fun invoiceDetail_isRouteSubtype() {
        val route: Route = Route.InvoiceDetail(id = 1L)
        assertIs<Route.InvoiceDetail>(route)
    }

    @Test
    fun supplierForm_isRouteSubtype() {
        val route: Route = Route.SupplierForm(id = 3L)
        assertIs<Route.SupplierForm>(route)
    }

    // ---- Data class routes with Long ids ----

    @Test
    fun clientDetail_carriesId() {
        val detail = Route.ClientDetail(id = 55L)
        assertEquals(55L, detail.id)
    }

    @Test
    fun productDetail_carriesId() {
        val detail = Route.ProductDetail(id = 123L)
        assertEquals(123L, detail.id)
    }

    @Test
    fun posOrderDetail_carriesId() {
        val detail = Route.PosOrderDetail(id = 77L)
        assertEquals(77L, detail.id)
    }

    @Test
    fun recordClientPayment_carriesClientId() {
        val route = Route.RecordClientPayment(clientId = 33L)
        assertEquals(33L, route.clientId)
    }

    // ---- AccountDepositForm / AccountWithdrawForm default ----

    @Test
    fun accountDepositForm_defaultAccountIdIsNull() {
        val form = Route.AccountDepositForm()
        assertNull(form.accountId)
    }

    @Test
    fun accountWithdrawForm_defaultAccountIdIsNull() {
        val form = Route.AccountWithdrawForm()
        assertNull(form.accountId)
    }

    @Test
    fun accountDepositForm_withAccountId_carriesIt() {
        val form = Route.AccountDepositForm(accountId = 8L)
        assertEquals(8L, form.accountId)
    }
}
