package me.amermahsoub.bfm.shared.data.tenant

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn

class ConfigStore(
    tenantRepository: TenantRepository,
    tenantContext: TenantContext,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    val config: StateFlow<TenantConfig?> = tenantRepository
        .getSelectedTenantSlug()
        .flatMapLatest { slug ->
            tenantContext.setTenantSlug(slug)
            if (slug.isNullOrBlank()) flowOf(null) else tenantRepository.getCachedConfig(slug)
        }
        .stateIn(scope, SharingStarted.Eagerly, null)
}
