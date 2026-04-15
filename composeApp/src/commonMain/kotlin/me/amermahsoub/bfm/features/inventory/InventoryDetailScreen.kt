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
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.inventory.Inventory
import me.amermahsoub.bfm.shared.data.inventory.InventoryProduct
import me.amermahsoub.bfm.shared.data.inventory.InventoryRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class InventoryDetailUiState(
    val loading: Boolean = true,
    val inventory: Inventory? = null,
    val products: List<InventoryProduct> = emptyList(),
    val error: AppError? = null,
)

class InventoryDetailViewModel(private val repo: InventoryRepository, private val id: Long) : FeatureViewModel() {
    private val _state = MutableStateFlow(InventoryDetailUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val inv = repo.get(id)
                val products = runCatching { repo.products(id).data }.getOrElse { emptyList() }
                _state.value = InventoryDetailUiState(loading = false, inventory = inv, products = products)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun InventoryDetailScreen(id: Long) {
    val repo = remember { GlobalContext.get().get<InventoryRepository>() }
    val vm = rememberFeatureViewModel { InventoryDetailViewModel(repo, id) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null && state.inventory == null -> ErrorState(state.error!!, onRetry = vm::load)
        state.inventory != null -> {
            val inv = state.inventory!!
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ScreenTitle(inv.name)
                SectionTitle(strings.productsTitle)
                state.products.forEach { item ->
                    ListRow(
                        title = item.productName ?: "Product ${item.productId}",
                        subtitle = item.sku,
                        trailing = item.quantity.toString(),
                        badge = if (item.isLowStock) strings.lowStock else null,
                    )
                }
            }
        }
    }
}
