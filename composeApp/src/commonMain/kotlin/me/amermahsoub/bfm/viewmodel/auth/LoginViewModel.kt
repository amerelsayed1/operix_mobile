package me.amermahsoub.bfm.viewmodel.auth

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.shared.data.tenant.TenantContext
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class LoginViewModel(
    private val repository: TenantRepository,
    private val tenantContext: TenantContext,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val _email = MutableStateFlow("")
    val email: StateFlow<String> = _email.asStateFlow()

    private val _password = MutableStateFlow("")
    val password: StateFlow<String> = _password.asStateFlow()

    private val _tenantSlug = MutableStateFlow("")
    val tenantSlug: StateFlow<String> = _tenantSlug.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    fun onEmailChange(value: String) {
        _email.value = value
        _error.value = null
    }

    fun onPasswordChange(value: String) {
        _password.value = value
        _error.value = null
    }

    fun onSlugChange(value: String) {
        _tenantSlug.value = value.trim().lowercase()
        _error.value = null
    }

    fun login(onSuccess: () -> Unit) {
        val slug = _tenantSlug.value.trim()
        val emailValue = _email.value.trim()
        val passwordValue = _password.value

        if (slug.isBlank()) {
            _error.value = "Company code is required."
            return
        }
        if (emailValue.isBlank()) {
            _error.value = "Email is required."
            return
        }
        if (passwordValue.isBlank()) {
            _error.value = "Password is required."
            return
        }

        _isLoading.value = true
        _error.value = null

        launch {
            try {
                repository.loginAndBootstrapSession(slug, emailValue, passwordValue)
                tenantContext.setTenantSlug(slug)
                _isLoading.value = false
                onSuccess()
            } catch (e: Exception) {
                _isLoading.value = false
                _error.value = e.message ?: "Login failed. Please check your credentials."
            }
        }
    }
}
