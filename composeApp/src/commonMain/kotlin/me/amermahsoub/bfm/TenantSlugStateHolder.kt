package me.amermahsoub.bfm

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.tenant.TenantContext
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository

data class TenantSlugUiState(
    val slugText: String = "",
    val isSaving: Boolean = false,
    val errorMessage: String? = null,
)

class TenantSlugStateHolder(
    private val tenantRepository: TenantRepository,
    private val tenantContext: TenantContext,
    private val scope: CoroutineScope,
) {
    private val _state = MutableStateFlow(TenantSlugUiState())
    val state: StateFlow<TenantSlugUiState> = _state.asStateFlow()

    init {
        scope.launch {
            val cachedSlug = tenantRepository.getSelectedTenantSlug().first().orEmpty()
            _state.value = _state.value.copy(slugText = cachedSlug)
        }
    }

    fun onSlugChange(value: String) {
        _state.value = _state.value.copy(slugText = value, errorMessage = null)
    }

    fun saveAndContinue(onComplete: () -> Unit) {
        val slug = _state.value.slugText.trim()
        if (slug.isBlank()) return

        scope.launch {
            _state.value = _state.value.copy(isSaving = true, errorMessage = null)
            try {
                tenantRepository.selectTenant(slug)
                tenantContext.setTenantSlug(slug)
                _state.value = _state.value.copy(slugText = slug, isSaving = false)
                onComplete()
            } catch (e: Throwable) {
                _state.value = _state.value.copy(
                    isSaving = false,
                    errorMessage = e.message ?: "Unable to save tenant slug.",
                )
            }
        }
    }

    fun clear() {
        _state.value = _state.value.copy(slugText = "", errorMessage = null)
    }
}
