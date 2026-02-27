package me.amermahsoub.bfm.shared.data.tenant

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class TenantContext(defaultBaseUrl: String) {
    private val _tenantSlug = MutableStateFlow<String?>(null)
    val tenantSlug: StateFlow<String?> = _tenantSlug.asStateFlow()

    private val _baseUrl = MutableStateFlow(defaultBaseUrl.trimEnd('/'))
    val baseUrl: StateFlow<String> = _baseUrl.asStateFlow()

    fun setTenantSlug(slug: String?) {
        _tenantSlug.value = slug
    }

    fun setBaseUrl(url: String) {
        _baseUrl.value = url.trim().trimEnd('/')
    }
}
