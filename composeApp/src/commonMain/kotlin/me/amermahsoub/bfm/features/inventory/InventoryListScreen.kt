package me.amermahsoub.bfm.features.inventory

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
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.inventory.Inventory
import me.amermahsoub.bfm.shared.data.inventory.InventoryRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class InventoryListUiState(
    val loading: Boolean = true,
    val items: List<Inventory> = emptyList(),
    val error: AppError? = null,
)

class InventoryListViewModel(private val repo: InventoryRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(InventoryListUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val items = repo.list()
                _state.value = InventoryListUiState(loading = false, items = items)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun InventoryListScreen(onInventory: (Long) -> Unit) {
    val repo = remember { GlobalContext.get().get<InventoryRepository>() }
    val vm = rememberFeatureViewModel { InventoryListViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null -> ErrorState(state.error!!, onRetry = vm::load)
        state.items.isEmpty() -> EmptyState()
        else -> Column(
            modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ScreenTitle(strings.inventoryTitle)
            state.items.forEach { inv ->
                ListRow(
                    title = inv.name,
                    subtitle = inv.location ?: (inv.productCount?.let { "$it products" }),
                    trailing = inv.totalStock?.toString() ?: "",
                    badge = if (inv.isDefault) strings.defaultInventory else null,
                    onClick = { onInventory(inv.id) },
                )
            }
        }
    }
}
