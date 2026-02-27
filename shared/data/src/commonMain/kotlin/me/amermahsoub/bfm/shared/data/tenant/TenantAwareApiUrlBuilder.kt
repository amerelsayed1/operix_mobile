package me.amermahsoub.bfm.shared.data.tenant

class TenantAwareApiUrlBuilder(
    private val baseUrl: String,
    private val tenantContext: TenantContext,
) {
    fun tenantConfig(slug: String): String = "$baseUrl/api/v1/tenant-config/$slug"

    fun login(): String {
        val slug = tenantContext.tenantSlug.value ?: error("Tenant slug is not selected")
        return "$baseUrl/api/v1/$slug/auth/login"
    }
}
