package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.plugins.api.createClientPlugin
import io.ktor.client.request.header
import io.ktor.http.HttpHeaders

val TenantNetworkInterceptor = createClientPlugin(
    name = "TenantNetworkInterceptor",
    createConfiguration = ::TenantNetworkInterceptorConfig,
) {
    val tokenProvider = pluginConfig.tokenProvider
    val tenantSlugProvider = pluginConfig.tenantSlugProvider

    onRequest { request, _ ->
        val path = request.url.build().encodedPath
        val token = tokenProvider()
        val tenantSlug = tenantSlugProvider()

        if (tenantSlug != null && request.headers["X-Tenant-Slug"] == null) {
            request.header("X-Tenant-Slug", tenantSlug)
        }

        val isPublicPath = path.contains("/tenant-config/") ||
            path.endsWith("/system/config") ||
            path.endsWith("/login") ||
            path.endsWith("/forgot-password") ||
            path.endsWith("/reset-password")

        if (!isPublicPath && token != null && request.headers[HttpHeaders.Authorization] == null) {
            request.header(HttpHeaders.Authorization, "Bearer $token")
        }
    }
}

class TenantNetworkInterceptorConfig {
    var tokenProvider: () -> String? = { null }
    var tenantSlugProvider: () -> String? = { null }
}
