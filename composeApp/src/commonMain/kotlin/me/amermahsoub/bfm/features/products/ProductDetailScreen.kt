package me.amermahsoub.bfm.features.products

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.BadgeChip
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.products.Product
import me.amermahsoub.bfm.shared.data.products.ProductTransaction
import me.amermahsoub.bfm.shared.data.products.ProductsRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class ProductDetailUiState(
    val loading: Boolean = true,
    val product: Product? = null,
    val transactions: List<ProductTransaction> = emptyList(),
    val error: AppError? = null,
)

class ProductDetailViewModel(private val repo: ProductsRepository, private val id: Long) : FeatureViewModel() {
    private val _state = MutableStateFlow(ProductDetailUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val product = repo.get(id)
                val tx = runCatching { repo.transactions(id) }.getOrElse { emptyList() }
                _state.value = ProductDetailUiState(loading = false, product = product, transactions = tx)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun ProductDetailScreen(id: Long) {
    val repo = remember { GlobalContext.get().get<ProductsRepository>() }
    val vm = rememberFeatureViewModel { ProductDetailViewModel(repo, id) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null && state.product == null -> ErrorState(state.error!!, onRetry = vm::load)
        state.product != null -> {
            val p = state.product!!
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ScreenTitle(p.name)
                BadgeChip(p.stockLabel)

                ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        KeyVal(strings.sku, p.sku)
                        KeyVal(strings.barcode, p.barcode)
                        KeyVal(strings.category, p.category?.name)
                        KeyVal(strings.price, p.sellingPrice)
                        KeyVal("Cost", p.costPrice)
                        KeyVal(strings.inStock, p.currentStock?.toString())
                    }
                }

                if (state.transactions.isNotEmpty()) {
                    SectionTitle("Transactions")
                    state.transactions.forEach { tx ->
                        ListRow(
                            title = tx.type,
                            subtitle = tx.reference ?: tx.createdAt,
                            trailing = tx.quantity.toString(),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun KeyVal(label: String, value: String?) {
    if (value.isNullOrBlank()) return
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, fontWeight = FontWeight.SemiBold)
    }
}
