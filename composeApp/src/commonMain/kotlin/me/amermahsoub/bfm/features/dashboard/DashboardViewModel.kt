package me.amermahsoub.bfm.features.dashboard

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.dashboard.DashboardData
import me.amermahsoub.bfm.shared.data.dashboard.DashboardRepository
import me.amermahsoub.bfm.shared.domain.common.AppError

data class DashboardUiState(
    val loading: Boolean = true,
    val data: DashboardData? = null,
    val error: AppError? = null,
)

class DashboardViewModel(
    private val repository: DashboardRepository,
) : FeatureViewModel() {

    private val _state = MutableStateFlow(DashboardUiState())
    val state = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val data = repository.load()
                _state.value = DashboardUiState(loading = false, data = data, error = data.error)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}
