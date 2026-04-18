package me.amermahsoub.bfm.features.invoices

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
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
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.invoices.Invoice
import me.amermahsoub.bfm.shared.data.invoices.InvoicesRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class InvoicesListUiState(
    val loading: Boolean = true,
    val items: List<Invoice> = emptyList(),
    val filter: String? = null,
    val error: AppError? = null,
)

class InvoicesListViewModel(private val repo: InvoicesRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(InvoicesListUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun setFilter(status: String?) {
        _state.value = _state.value.copy(filter = status)
        load()
    }

    fun refresh() = load()

    private fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val result = repo.list(status = _state.value.filter)
                _state.value = _state.value.copy(loading = false, items = result.data)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun InvoicesListScreen(onInvoice: (Long) -> Unit) {
    val repo = remember { GlobalContext.get().get<InvoicesRepository>() }
    val vm = rememberFeatureViewModel { InvoicesListViewModel(repo) }
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
                ScreenTitle(strings.invoicesTitle)

                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = state.filter == null,
                        onClick = { vm.setFilter(null) },
                        label = { Text(strings.all) },
                    )
                    listOf("paid", "unpaid", "partial", "overdue").forEach { status ->
                        FilterChip(
                            selected = state.filter == status,
                            onClick = { vm.setFilter(status) },
                            label = { Text(invoiceStatusLabel(status, strings)) },
                        )
                    }
                }

                if (state.items.isEmpty()) {
                    EmptyState()
                } else {
                    state.items.forEach { inv ->
                        ListRow(
                            title = inv.invoiceNumber ?: "#${inv.id}",
                            subtitle = inv.clientName ?: inv.issueDate,
                            trailing = inv.total ?: "",
                            badge = inv.status,
                            badgeTone = invoiceTone(inv.status),
                            onClick = { onInvoice(inv.id) },
                        )
                    }
                }
            }
        }
    }
}

private fun invoiceTone(status: String?): BadgeTone = when (status?.lowercase()) {
    "paid" -> BadgeTone.SUCCESS
    "partial" -> BadgeTone.WARNING
    "overdue" -> BadgeTone.ERROR
    "unpaid" -> BadgeTone.WARNING
    else -> BadgeTone.NEUTRAL
}

private fun invoiceStatusLabel(status: String, strings: me.amermahsoub.bfm.app.i18n.AppStrings): String = when (status) {
    "paid" -> strings.paid
    "unpaid" -> strings.unpaid
    "partial" -> strings.partial
    "overdue" -> strings.overdue
    else -> status
}
