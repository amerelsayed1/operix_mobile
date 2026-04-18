package me.amermahsoub.bfm.features.pos

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
import me.amermahsoub.bfm.app.ui.EmptyState
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.pos.PosOrder
import me.amermahsoub.bfm.shared.data.pos.PosRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class PosOrdersUiState(
    val loading: Boolean = true,
    val orders: List<PosOrder> = emptyList(),
    val error: AppError? = null,
)

class PosOrdersViewModel(private val repo: PosRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(PosOrdersUiState())
    val state = _state.asStateFlow()

    init { refresh() }

    fun refresh() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val page = repo.listOrders()
                _state.value = PosOrdersUiState(loading = false, orders = page.data)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun PosOrdersScreen(onOrderClick: (Long) -> Unit) {
    val repo = remember { GlobalContext.get().get<PosRepository>() }
    val vm = rememberFeatureViewModel { PosOrdersViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null -> ErrorState(state.error!!, onRetry = vm::refresh)
        state.orders.isEmpty() -> EmptyState()
        else -> {
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                ScreenTitle(strings.orders)
                state.orders.forEach { order ->
                    ListRow(
                        title = "${strings.receiptNumber}${order.receiptNumber ?: order.id}",
                        subtitle = order.clientName ?: order.createdAt,
                        trailing = order.grandTotal ?: "",
                        badge = order.paymentStatus ?: order.status,
                        onClick = { onOrderClick(order.id) },
                    )
                }
            }
        }
    }
}
