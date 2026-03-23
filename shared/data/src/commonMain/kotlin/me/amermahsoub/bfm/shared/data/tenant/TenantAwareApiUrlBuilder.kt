package me.amermahsoub.bfm.shared.data.tenant

class TenantAwareApiUrlBuilder(
    private val baseUrl: String,
    private val tenantContext: TenantContext,
) {
    private fun activeSlug(): String = tenantContext.tenantSlug.value ?: error("Tenant slug is not selected")

    fun publicTenantConfig(slug: String): String = "$baseUrl/api/v1/tenant-config/$slug"

    fun systemConfig(slug: String = activeSlug()): String = "$baseUrl/api/v1/$slug/system/config"

    fun bootstrap(slug: String): String = systemConfig(slug)

    fun login(slug: String = activeSlug()): String = "$baseUrl/api/v1/$slug/login"

    fun logout(slug: String = activeSlug()): String = "$baseUrl/api/v1/$slug/logout"

    fun me(slug: String = activeSlug()): String = "$baseUrl/api/v1/$slug/me"

    fun permissions(slug: String = activeSlug()): String = "$baseUrl/api/v1/$slug/me/permissions"

    fun config(slug: String = activeSlug()): String = "$baseUrl/api/v1/$slug/config"

    fun dashboardKpis(slug: String = activeSlug()): String = "$baseUrl/api/v1/$slug/dashboard/kpis"

    fun lowStock(slug: String = activeSlug()): String = "$baseUrl/api/v1/$slug/dashboard/lists/low-stock"

    fun recentOrders(slug: String = activeSlug()): String = "$baseUrl/api/v1/$slug/dashboard/lists/recent-orders"
}
