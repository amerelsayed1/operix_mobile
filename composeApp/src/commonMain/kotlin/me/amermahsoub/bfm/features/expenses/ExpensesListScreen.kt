package me.amermahsoub.bfm.features.expenses

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.EmptyState
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.expenses.Expense
import me.amermahsoub.bfm.shared.data.expenses.ExpensesRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class ExpensesListUiState(
    val loading: Boolean = true,
    val items: List<Expense> = emptyList(),
    val error: AppError? = null,
)

class ExpensesListViewModel(private val repo: ExpensesRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(ExpensesListUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val page = repo.list()
                _state.value = ExpensesListUiState(loading = false, items = page.data)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun ExpensesListScreen(onAdd: () -> Unit, onEdit: (Long) -> Unit) {
    val repo = remember { GlobalContext.get().get<ExpensesRepository>() }
    val vm = rememberFeatureViewModel { ExpensesListViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null && state.items.isEmpty() -> ErrorState(state.error!!, onRetry = vm::load)
        else -> Column(
            modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ScreenTitle(strings.expensesTitle)
            PrimaryButton(text = strings.addExpenseTitle, onClick = onAdd)
            if (state.items.isEmpty()) {
                EmptyState()
            } else {
                state.items.forEach { exp ->
                    ListRow(
                        title = exp.description ?: exp.categoryName ?: "Expense #${exp.id}",
                        subtitle = "${exp.categoryName ?: ""} • ${exp.date ?: ""}",
                        trailing = exp.amount,
                        badge = exp.accountName,
                        onClick = { onEdit(exp.id) },
                    )
                }
            }
        }
    }
}
