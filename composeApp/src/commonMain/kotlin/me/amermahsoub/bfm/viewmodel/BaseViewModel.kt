package me.amermahsoub.bfm.viewmodel

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.api.ApiException
import me.amermahsoub.bfm.shared.data.models.Result

abstract class BaseViewModel {
    protected val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    fun onCleared() {
        scope.cancel()
    }

    protected fun <T> MutableStateFlow<Result<T>>.load(block: suspend () -> T) {
        value = Result.Loading
        scope.launch {
            value = try {
                Result.Success(block())
            } catch (e: ApiException) {
                Result.Error(e.displayMessage, e.httpCode())
            } catch (e: Exception) {
                val msg = e.message ?: "An error occurred"
                val isNetwork = msg.contains("connect", ignoreCase = true) ||
                    msg.contains("timeout", ignoreCase = true) ||
                    msg.contains("unreachable", ignoreCase = true)
                if (isNetwork) Result.Error(ApiException.Network(msg).displayMessage, 0)
                else Result.Error(msg)
            }
        }
    }

    protected fun launch(block: suspend CoroutineScope.() -> kotlin.Unit) {
        scope.launch(block = block)
    }
}

private fun ApiException.httpCode(): Int = when (this) {
    is ApiException.Validation -> 422
    is ApiException.Auth       -> 401
    is ApiException.NotFound   -> 404
    is ApiException.Server     -> this.code
    is ApiException.Network    -> 0
}
