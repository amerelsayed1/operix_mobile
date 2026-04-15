package me.amermahsoub.bfm.features.auth

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.shared.data.tenant.isValidTenantSlug
import me.amermahsoub.bfm.shared.domain.common.AppError

data class LoginUiState(
    val tenantSlug: String = "",
    val identity: String = "",
    val password: String = "",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val offlineNotice: Boolean = false,
    val loggedIn: Boolean = false,
)

class LoginViewModel(
    private val tenantRepository: TenantRepository,
    initialSlug: String? = null,
) : FeatureViewModel() {

    private val _state = MutableStateFlow(LoginUiState(tenantSlug = initialSlug.orEmpty()))
    val state = _state.asStateFlow()

    fun updateSlug(v: String) {
        _state.value = _state.value.copy(tenantSlug = v.trim().lowercase(), error = null, offlineNotice = false)
    }

    fun updateIdentity(v: String) { _state.value = _state.value.copy(identity = v, error = null) }
    fun updatePassword(v: String) { _state.value = _state.value.copy(password = v, error = null) }

    fun submit() {
        val s = _state.value
        if (!isValidTenantSlug(s.tenantSlug)) {
            _state.value = s.copy(error = AppError.Validation("Invalid company code"))
            return
        }
        if (s.identity.isBlank() || s.password.isBlank()) {
            _state.value = s.copy(error = AppError.Validation("Enter identity and security key"))
            return
        }
        scope.launch {
            _state.value = s.copy(submitting = true, error = null, offlineNotice = false)
            var offline = false
            try {
                // Best-effort pre-login bootstrap. The public tenant-config
                // endpoint may not exist on every backend; if it fails we
                // just proceed — the protected /config endpoint fetched
                // after login fills in tenant info.
                runCatching { tenantRepository.refreshConfig(s.tenantSlug) }
                    .onFailure {
                        val cached = tenantRepository.getCachedConfigOnce(s.tenantSlug)
                        if (cached == null) offline = true
                    }
                tenantRepository.selectTenant(s.tenantSlug)
                tenantRepository.loginAndBootstrapSession(s.tenantSlug, s.identity, s.password)
                _state.value = _state.value.copy(submitting = false, loggedIn = true, offlineNotice = offline)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError(), offlineNotice = offline)
            }
        }
    }

    fun resetLoggedIn() {
        _state.value = _state.value.copy(loggedIn = false)
    }
}
