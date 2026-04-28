package me.amermahsoub.bfm.viewmodel

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
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
            } catch (e: Exception) {
                Result.Error(e.message ?: "An error occurred")
            }
        }
    }

    protected fun launch(block: suspend CoroutineScope.() -> kotlin.Unit) {
        scope.launch(block = block)
    }
}
