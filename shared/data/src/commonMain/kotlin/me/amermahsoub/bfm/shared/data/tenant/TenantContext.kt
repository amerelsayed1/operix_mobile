package me.amermahsoub.bfm.shared.data.tenant

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class TenantContext {
    private val _tenantSlug = MutableStateFlow<String?>(null)
    val tenantSlug: StateFlow<String?> = _tenantSlug.asStateFlow()

    fun setTenantSlug(slug: String?) {
        _tenantSlug.value = slug
    }
}
