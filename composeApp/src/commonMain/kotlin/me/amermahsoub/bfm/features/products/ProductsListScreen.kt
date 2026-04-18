package me.amermahsoub.bfm.features.products

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
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
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.products.Product
import me.amermahsoub.bfm.shared.data.products.ProductsRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class ProductsListUiState(
    val loading: Boolean = true,
    val query: String = "",
    val items: List<Product> = emptyList(),
    val error: AppError? = null,
)

class ProductsListViewModel(private val repo: ProductsRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(ProductsListUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun updateQuery(q: String) {
        _state.value = _state.value.copy(query = q)
        scope.launch {
            try {
                val page = repo.list(search = q.ifBlank { null })
                _state.value = _state.value.copy(items = page.data)
            } catch (_: Throwable) {}
        }
    }

    fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val page = repo.list()
                _state.value = ProductsListUiState(loading = false, items = page.data)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun ProductsListScreen(onProduct: (Long) -> Unit) {
    val repo = remember { GlobalContext.get().get<ProductsRepository>() }
    val vm = rememberFeatureViewModel { ProductsListViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading && state.items.isEmpty() -> LoadingState()
        state.error != null && state.items.isEmpty() -> ErrorState(state.error!!, onRetry = vm::load)
        else -> Column(
            modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ScreenTitle(strings.productsTitle)
            OutlinedTextField(
                value = state.query,
                onValueChange = vm::updateQuery,
                label = { Text(strings.search) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            state.items.forEach { product ->
                ListRow(
                    title = product.name,
                    subtitle = product.sku ?: product.category?.name,
                    trailing = product.displayPrice,
                    badge = product.stockLabel,
                    onClick = { onProduct(product.id) },
                )
            }
        }
    }
}
