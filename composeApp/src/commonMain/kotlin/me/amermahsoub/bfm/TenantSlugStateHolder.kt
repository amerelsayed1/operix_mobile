package me.amermahsoub.bfm

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.tenant.TenantConfigLoadException
import me.amermahsoub.bfm.shared.data.tenant.TenantContext
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository

private val TENANT_SLUG_REGEX = Regex("^[a-z0-9]+(?:-[a-z0-9]+)*$")
private const val INVALID_SLUG_MESSAGE =
    "Invalid slug. Use lowercase letters, numbers, and hyphens only."

data class TenantSlugUiState(
    val slugText: String = "",
    val isSaving: Boolean = false,
    val errorMessage: String? = null,
) {
    val isSlugValid: Boolean = slugText.isNotBlank() && TENANT_SLUG_REGEX.matches(slugText)
}

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
            val normalizedSlug = normalizeSlug(cachedSlug)
            _state.value = _state.value.copy(
                slugText = normalizedSlug,
                errorMessage = validateSlugOrNull(normalizedSlug),
            )
        }
    }

    fun onSlugChange(value: String) {
        val normalizedSlug = normalizeSlug(value)
        _state.value = _state.value.copy(
            slugText = normalizedSlug,
            errorMessage = validateSlugOrNull(normalizedSlug),
        )
    }

    fun loadTenantAndContinue(onComplete: () -> Unit) {
        val slug = normalizeSlug(_state.value.slugText)
        val validationError = validateSlugOrNull(slug)
        if (validationError != null) {
            _state.value = _state.value.copy(errorMessage = validationError, slugText = slug)
            return
        }

        scope.launch {
            _state.value = _state.value.copy(isSaving = true, errorMessage = null)
            try {
                tenantRepository.refreshConfig(slug)
                tenantRepository.selectTenant(slug)
                tenantContext.setTenantSlug(slug)
                _state.value = _state.value.copy(slugText = slug, isSaving = false)
                onComplete()
            } catch (e: TenantConfigLoadException.NotFound) {
                _state.value = _state.value.copy(
                    isSaving = false,
                    errorMessage = "Tenant not found. Check the slug.",
                )
            } catch (e: TenantConfigLoadException.Network) {
                _state.value = _state.value.copy(
                    isSaving = false,
                    errorMessage = "Cannot reach server. Check connection.",
                )
            } catch (e: Throwable) {
                _state.value = _state.value.copy(
                    isSaving = false,
                    errorMessage = "Failed to load tenant config.",
                )
            }
        }
    }

    fun clearInput() {
        _state.value = _state.value.copy(slugText = "", errorMessage = null)
    }

    fun resetTenant(onComplete: () -> Unit) {
        scope.launch {
            val currentSlug = tenantRepository.getSelectedTenantSlug().first()
            if (!currentSlug.isNullOrBlank()) {
                tenantRepository.clearTenantData(currentSlug)
                tenantRepository.clearTenantConfig(currentSlug)
            }
            tenantRepository.clearSelectedTenant()
            tenantContext.setTenantSlug(null)
            _state.value = TenantSlugUiState()
            onComplete()
        }
    }

    private fun normalizeSlug(rawInput: String): String {
        val trimmed = rawInput.trim().lowercase()
        if (trimmed.isBlank()) return ""

        val withoutQuery = trimmed.substringBefore('?').substringBefore('#')
        val candidate = withoutQuery
            .split('/')
            .lastOrNull { it.isNotBlank() }
            ?: withoutQuery

        return candidate.trim()
    }

    private fun validateSlugOrNull(slug: String): String? = when {
        slug.isBlank() -> null
        TENANT_SLUG_REGEX.matches(slug) -> null
        else -> INVALID_SLUG_MESSAGE
    }
}
