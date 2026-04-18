package me.amermahsoub.bfm.features.suppliers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
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
import me.amermahsoub.bfm.app.ui.BadgeTone
import me.amermahsoub.bfm.app.ui.EmptyState
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.suppliers.Supplier
import me.amermahsoub.bfm.shared.data.suppliers.SuppliersRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class SuppliersListUiState(
    val loading: Boolean = true,
    val items: List<Supplier> = emptyList(),
    val searchQuery: String = "",
    val error: AppError? = null,
)

class SuppliersListViewModel(private val repo: SuppliersRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(SuppliersListUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun updateSearch(q: String) {
        _state.value = _state.value.copy(searchQuery = q)
        load()
    }

    fun refresh() = load()

    private fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val q = _state.value.searchQuery.ifBlank { null }
                val result = repo.list(search = q)
                _state.value = _state.value.copy(loading = false, items = result.data)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun SuppliersListScreen(
    onSupplier: (Long) -> Unit,
    onAdd: () -> Unit,
) {
    val repo = remember { GlobalContext.get().get<SuppliersRepository>() }
    val vm = rememberFeatureViewModel { SuppliersListViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading && state.items.isEmpty() -> LoadingState()
        state.error != null && state.items.isEmpty() -> ErrorState(state.error!!, onRetry = vm::refresh)
        else -> {
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ScreenTitle(strings.suppliersTitle)

                PrimaryButton(text = strings.addSupplier, onClick = onAdd)

                OutlinedTextField(
                    value = state.searchQuery,
                    onValueChange = vm::updateSearch,
                    label = { Text(strings.search) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )

                if (state.items.isEmpty()) {
                    EmptyState()
                } else {
                    state.items.forEach { supplier ->
                        ListRow(
                            title = supplier.name,
                            subtitle = supplier.contactPerson ?: supplier.phone,
                            trailing = supplier.balance,
                            badge = if (supplier.isActive) strings.active else strings.inactive,
                            badgeTone = if (supplier.isActive) BadgeTone.SUCCESS else BadgeTone.WARNING,
                            onClick = { onSupplier(supplier.id) },
                        )
                    }
                }
            }
        }
    }
}
