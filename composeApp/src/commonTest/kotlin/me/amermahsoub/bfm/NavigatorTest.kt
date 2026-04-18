package me.amermahsoub.bfm

import me.amermahsoub.bfm.app.nav.AppNavigator
import me.amermahsoub.bfm.app.nav.Route
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class NavigatorTest {

    // ---- Initial state ----

    @Test
    fun initialState_currentIsInitialRoute() {
        val nav = AppNavigator(Route.Login)
        assertSame(Route.Login, nav.current)
    }

    @Test
    fun initialState_stackSizeIsOne() {
        val nav = AppNavigator(Route.Home)
        assertEquals(1, nav.stack.size)
    }

    @Test
    fun initialState_canPopIsFalse() {
        val nav = AppNavigator(Route.Login)
        assertFalse(nav.canPop)
    }

    // ---- push ----

    @Test
    fun push_addsRouteToStack() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)
        assertEquals(2, nav.stack.size)
        assertSame(Route.Home, nav.current)
    }

    @Test
    fun push_canPopBecomesTrue() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)
        assertTrue(nav.canPop)
    }

    @Test
    fun pushMultiple_stackGrowsCorrectly() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)
        nav.push(Route.PosCart)
        nav.push(Route.Reports)
        assertEquals(4, nav.stack.size)
        assertEquals(
            listOf(Route.Login, Route.Home, Route.PosCart, Route.Reports),
            nav.stack
        )
        assertSame(Route.Reports, nav.current)
    }

    // ---- pop ----

    @Test
    fun pop_removesLastAndReturnsTrue() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)
        val result = nav.pop()
        assertTrue(result)
        assertEquals(1, nav.stack.size)
        assertSame(Route.Login, nav.current)
    }

    @Test
    fun pop_onSingleItem_returnsFalseAndStackUnchanged() {
        val nav = AppNavigator(Route.Login)
        val result = nav.pop()
        assertFalse(result)
        assertEquals(1, nav.stack.size)
        assertSame(Route.Login, nav.current)
    }

    // ---- replace ----

    @Test
    fun replace_replacesLastWithoutGrowingStack() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)
        assertEquals(2, nav.stack.size)

        nav.replace(Route.PosCart)
        assertEquals(2, nav.stack.size)
        assertSame(Route.PosCart, nav.current)
        assertEquals(listOf(Route.Login, Route.PosCart), nav.stack)
    }

    @Test
    fun replace_onSingleItem_replacesRoot() {
        val nav = AppNavigator(Route.Login)
        nav.replace(Route.Home)
        assertEquals(1, nav.stack.size)
        assertSame(Route.Home, nav.current)
    }

    // ---- reset ----

    @Test
    fun reset_clearsStackToSingleItem() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)
        nav.push(Route.PosCart)
        nav.push(Route.Reports)

        nav.reset(Route.Login)
        assertEquals(1, nav.stack.size)
        assertSame(Route.Login, nav.current)
        assertFalse(nav.canPop)
    }

    // ---- popWithResult + consumeResult ----

    @Test
    fun popWithResult_resultIsAvailableAfterPop() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)

        nav.popWithResult("selectedId", 42L)
        assertSame(Route.Login, nav.current)

        val result = nav.consumeResult<Long>("selectedId")
        assertEquals(42L, result)
    }

    @Test
    fun consumeResult_returnsNullIfKeyNotSet() {
        val nav = AppNavigator(Route.Login)
        val result = nav.consumeResult<String>("nonexistent")
        assertNull(result)
    }

    @Test
    fun consumeResult_removesResult_secondCallReturnsNull() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)
        nav.popWithResult("key", "value")

        val first = nav.consumeResult<String>("key")
        assertEquals("value", first)

        val second = nav.consumeResult<String>("key")
        assertNull(second)
    }

    @Test
    fun popWithResult_withNullValue() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)
        nav.popWithResult("key", null)

        val result = nav.consumeResult<String>("key")
        assertNull(result)
    }

    // ---- LIFO order ----

    @Test
    fun multiplePushesThenPops_lifoOrder() {
        val nav = AppNavigator(Route.Login)
        nav.push(Route.Home)
        nav.push(Route.PosCart)
        nav.push(Route.Reports)
        nav.push(Route.InvoicesList)

        assertEquals(5, nav.stack.size)

        assertSame(Route.InvoicesList, nav.current)
        assertTrue(nav.pop())
        assertSame(Route.Reports, nav.current)
        assertTrue(nav.pop())
        assertSame(Route.PosCart, nav.current)
        assertTrue(nav.pop())
        assertSame(Route.Home, nav.current)
        assertTrue(nav.pop())
        assertSame(Route.Login, nav.current)
        assertFalse(nav.pop())
    }

    // ---- Stack snapshot ----

    @Test
    fun stack_reflectsAllOperations() {
        val nav = AppNavigator(Route.Login)
        assertEquals(listOf(Route.Login), nav.stack)

        nav.push(Route.Home)
        assertEquals(listOf(Route.Login, Route.Home), nav.stack)

        nav.replace(Route.PosCart)
        assertEquals(listOf(Route.Login, Route.PosCart), nav.stack)

        nav.push(Route.Reports)
        assertEquals(listOf(Route.Login, Route.PosCart, Route.Reports), nav.stack)

        nav.pop()
        assertEquals(listOf(Route.Login, Route.PosCart), nav.stack)

        nav.reset(Route.Home)
        assertEquals(listOf(Route.Home), nav.stack)
    }
}
