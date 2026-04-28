package me.amermahsoub.bfm.viewmodel.pos

// Koin module dependency chain (register in your appModule or posModule):
//   single { ShiftSummaryViewModel(get(), get()) }
// where the two dependencies are OperixApiService and SessionStore.

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.ShiftSummary
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class ShiftSummaryViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    private val _summaryState = MutableStateFlow<Result<ShiftSummary>>(Result.Loading)
    val summaryState: StateFlow<Result<ShiftSummary>> = _summaryState.asStateFlow()

    fun loadSummary(shiftId: Int) {
        _summaryState.load { api.getShiftSummary(slug, shiftId) }
    }
}
