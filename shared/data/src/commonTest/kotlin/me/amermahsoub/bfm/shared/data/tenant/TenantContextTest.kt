package me.amermahsoub.bfm.shared.data.tenant

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class TenantContextTest {

    @Test
    fun initialValueIsNull() {
        val context = TenantContext()
        assertNull(context.tenantSlug.value)
    }

    @Test
    fun setTenantSlugUpdatesValue() {
        val context = TenantContext()
        context.setTenantSlug("my-tenant")
        assertEquals("my-tenant", context.tenantSlug.value)
    }

    @Test
    fun setTenantSlugToNullClearsValue() {
        val context = TenantContext()
        context.setTenantSlug("my-tenant")
        context.setTenantSlug(null)
        assertNull(context.tenantSlug.value)
    }

    @Test
    fun multipleUpdatesLastValueWins() {
        val context = TenantContext()
        context.setTenantSlug("first")
        context.setTenantSlug("second")
        context.setTenantSlug("third")
        assertEquals("third", context.tenantSlug.value)
    }
}
