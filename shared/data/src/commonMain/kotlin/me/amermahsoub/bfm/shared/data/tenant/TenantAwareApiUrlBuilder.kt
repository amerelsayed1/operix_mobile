package me.amermahsoub.bfm.shared.data.tenant

class TenantAwareApiUrlBuilder(
    private val tenantContext: TenantContext,
) {
    fun bootstrap(slug: String): String = "${tenantContext.baseUrl.value}/api/v1/$slug/bootstrap"

    fun login(): String {
        val slug = tenantContext.tenantSlug.value ?: error("Tenant slug is not selected")
        return "${tenantContext.baseUrl.value}/api/v1/$slug/auth/login"
    }
}
