package me.amermahsoub.bfm.features.reports

import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.reports.ClientReport
import me.amermahsoub.bfm.shared.data.reports.ExpenseCategoryBreakdown
import me.amermahsoub.bfm.shared.data.reports.ExpenseReport
import me.amermahsoub.bfm.shared.data.reports.ProfitReport
import me.amermahsoub.bfm.shared.data.reports.ReportsRepository
import me.amermahsoub.bfm.shared.data.reports.SalesReport
import me.amermahsoub.bfm.shared.data.reports.TopProductReport
import me.amermahsoub.bfm.shared.domain.common.AppError

enum class ReportPeriod { TODAY, WEEK, MONTH, YEAR }

data class ReportsUiState(
    val loading: Boolean = true,
    val period: ReportPeriod = ReportPeriod.MONTH,
    val sales: SalesReport? = null,
    val profit: ProfitReport? = null,
    val expenses: ExpenseReport? = null,
    val clients: ClientReport? = null,
    val topProducts: List<TopProductReport> = emptyList(),
    val error: AppError? = null,
)

class ReportsViewModel(private val repo: ReportsRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(ReportsUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun selectPeriod(period: ReportPeriod) {
        _state.value = _state.value.copy(period = period)
        load()
    }

    fun refresh() = load()

    private fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val (from, to) = dateRange(_state.value.period)
                coroutineScope {
                    val salesD = async { runCatching { repo.salesReport(from, to) }.getOrNull() }
                    val profitD = async { runCatching { repo.profitReport(from, to) }.getOrNull() }
                    val expensesD = async { runCatching { repo.expenseReport(from, to) }.getOrNull() }
                    val clientsD = async { runCatching { repo.clientReport(from, to) }.getOrNull() }
                    val topD = async { runCatching { repo.topProducts(from, to) }.getOrNull().orEmpty() }

                    _state.value = _state.value.copy(
                        loading = false,
                        sales = salesD.await(),
                        profit = profitD.await(),
                        expenses = expensesD.await(),
                        clients = clientsD.await(),
                        topProducts = topD.await(),
                    )
                }
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

private fun dateRange(period: ReportPeriod): Pair<String?, String?> {
    return when (period) {
        ReportPeriod.TODAY -> null to null
        ReportPeriod.WEEK -> null to null
        ReportPeriod.MONTH -> null to null
        ReportPeriod.YEAR -> null to null
    }
}
