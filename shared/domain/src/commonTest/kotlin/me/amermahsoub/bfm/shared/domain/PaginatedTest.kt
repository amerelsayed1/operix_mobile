package me.amermahsoub.bfm.shared.domain

import me.amermahsoub.bfm.shared.domain.common.Paginated
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class PaginatedTest {

    @Test
    fun hasMore_currentPageLessThanLastPage_returnsTrue() {
        val paginated = Paginated(data = listOf("a"), currentPage = 1, lastPage = 3, perPage = 10, total = 25)
        assertTrue(paginated.hasMore)
    }

    @Test
    fun hasMore_currentPageEqualsLastPage_returnsFalse() {
        val paginated = Paginated(data = listOf("a"), currentPage = 3, lastPage = 3, perPage = 10, total = 25)
        assertFalse(paginated.hasMore)
    }

    @Test
    fun hasMore_currentPageGreaterThanLastPage_returnsFalse() {
        val paginated = Paginated(data = listOf("a"), currentPage = 5, lastPage = 3, perPage = 10, total = 25)
        assertFalse(paginated.hasMore)
    }

    @Test
    fun empty_returnsCorrectDefaults() {
        val paginated = Paginated.empty<String>()
        assertEquals(emptyList(), paginated.data)
        assertEquals(1, paginated.currentPage)
        assertEquals(1, paginated.lastPage)
        assertEquals(15, paginated.perPage)
        assertEquals(0, paginated.total)
        assertFalse(paginated.hasMore)
    }

    @Test
    fun data_accessWorksCorrectly() {
        val items = listOf("x", "y", "z")
        val paginated = Paginated(data = items, currentPage = 1, lastPage = 1, perPage = 10, total = 3)
        assertEquals(3, paginated.data.size)
        assertEquals("x", paginated.data[0])
        assertEquals("y", paginated.data[1])
        assertEquals("z", paginated.data[2])
    }

    @Test
    fun data_preservesOrder() {
        val items = listOf(3, 1, 2)
        val paginated = Paginated(data = items, currentPage = 1, lastPage = 1, perPage = 10, total = 3)
        assertEquals(listOf(3, 1, 2), paginated.data)
    }
}
