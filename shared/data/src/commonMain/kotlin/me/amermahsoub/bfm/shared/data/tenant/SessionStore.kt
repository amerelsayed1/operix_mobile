package me.amermahsoub.bfm.shared.data.tenant

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow

class SessionStore {
    private val _session = MutableStateFlow<SessionBootstrap?>(null)
    val session: StateFlow<SessionBootstrap?> = _session.asStateFlow()

    private val _tokenExpired = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val tokenExpired: SharedFlow<Unit> = _tokenExpired.asSharedFlow()

    val token: String?
        get() = _session.value?.login?.token

    fun update(session: SessionBootstrap) {
        _session.value = session
    }

    fun clear() {
        _session.value = null
    }

    fun notifyTokenExpired() {
        if (_session.value != null) {
            _tokenExpired.tryEmit(Unit)
        }
    }
}
