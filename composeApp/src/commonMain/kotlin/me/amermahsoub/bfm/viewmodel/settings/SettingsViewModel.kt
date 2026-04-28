package me.amermahsoub.bfm.viewmodel.settings

import kotlinx.coroutines.flow.StateFlow
import me.amermahsoub.bfm.shared.data.tenant.SessionBootstrap
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class SettingsViewModel(
    private val repository: TenantRepository,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    val userSession: StateFlow<SessionBootstrap?> = sessionStore.session

    fun logout(onLoggedOut: () -> Unit) {
        launch {
            repository.logout()
            onLoggedOut()
        }
    }
}
