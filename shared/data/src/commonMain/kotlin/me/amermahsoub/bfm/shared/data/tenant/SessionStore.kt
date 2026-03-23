package me.amermahsoub.bfm.shared.data.tenant

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class SessionStore {
    private val _session = MutableStateFlow<SessionBootstrap?>(null)
    val session: StateFlow<SessionBootstrap?> = _session.asStateFlow()

    val token: String?
        get() = _session.value?.login?.token

    fun update(session: SessionBootstrap) {
        _session.value = session
    }

    fun clear() {
        _session.value = null
    }
}
