package me.amermahsoub.bfm.features.suppliers

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
import me.amermahsoub.bfm.app.ui.BadgeTone
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.StatusBadge
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.suppliers.PurchaseOrder
import me.amermahsoub.bfm.shared.data.suppliers.Supplier
import me.amermahsoub.bfm.shared.data.suppliers.SuppliersRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class SupplierDetailUiState(
    val loading: Boolean = true,
    val supplier: Supplier? = null,
    val purchaseOrders: List<PurchaseOrder> = emptyList(),
    val error: AppError? = null,
)

class SupplierDetailViewModel(private val repo: SuppliersRepository, private val id: Long) : FeatureViewModel() {
    private val _state = MutableStateFlow(SupplierDetailUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun refresh() = load()

    private fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val supplier = repo.get(id)
                val orders = runCatching { repo.purchaseOrders().data }.getOrElse { emptyList() }
                _state.value = _state.value.copy(
                    loading = false,
                    supplier = supplier,
                    purchaseOrders = orders.filter { it.supplierId == id },
                )
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun SupplierDetailScreen(id: Long, onEdit: () -> Unit) {
    val repo = remember { GlobalContext.get().get<SuppliersRepository>() }
    val vm = rememberFeatureViewModel { SupplierDetailViewModel(repo, id) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null && state.supplier == null -> ErrorState(state.error!!, onRetry = vm::refresh)
        else -> {
            val s = state.supplier ?: return
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ScreenTitle(s.name)

                ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        StatusBadge(
                            if (s.isActive) strings.active else strings.inactive,
                            if (s.isActive) BadgeTone.SUCCESS else BadgeTone.WARNING,
                        )
                        s.contactPerson?.let { InfoRow(strings.contactPerson, it) }
                        s.phone?.let { InfoRow(strings.phone, it) }
                        s.email?.let { InfoRow(strings.email, it) }
                        s.address?.let { InfoRow(strings.address, it) }
                        s.taxNumber?.let { InfoRow(strings.taxNumber, it) }
                        s.balance?.let { InfoRow(strings.balance, it) }
                    }
                }

                if (state.purchaseOrders.isNotEmpty()) {
                    SectionTitle(strings.purchaseOrders)
                    state.purchaseOrders.forEach { po ->
                        ListRow(
                            title = po.purchaseOrderNumber ?: "#${po.id}",
                            subtitle = po.date,
                            trailing = po.total,
                            badge = po.status,
                            badgeTone = poTone(po.status),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
    }
}

private fun poTone(status: String?): BadgeTone = when (status?.lowercase()) {
    "received", "completed" -> BadgeTone.SUCCESS
    "pending", "draft" -> BadgeTone.WARNING
    "cancelled" -> BadgeTone.ERROR
    else -> BadgeTone.NEUTRAL
}
