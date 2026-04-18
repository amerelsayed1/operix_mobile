package me.amermahsoub.bfm.features.invoices

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.HorizontalDivider
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
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.StatusBadge
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.invoices.Invoice
import me.amermahsoub.bfm.shared.data.invoices.InvoicesRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class InvoiceDetailUiState(
    val loading: Boolean = true,
    val invoice: Invoice? = null,
    val error: AppError? = null,
)

class InvoiceDetailViewModel(private val repo: InvoicesRepository, private val id: Long) : FeatureViewModel() {
    private val _state = MutableStateFlow(InvoiceDetailUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun refresh() = load()

    private fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val inv = repo.get(id)
                _state.value = _state.value.copy(loading = false, invoice = inv)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun InvoiceDetailScreen(id: Long) {
    val repo = remember { GlobalContext.get().get<InvoicesRepository>() }
    val vm = rememberFeatureViewModel { InvoiceDetailViewModel(repo, id) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null && state.invoice == null -> ErrorState(state.error!!, onRetry = vm::refresh)
        else -> {
            val inv = state.invoice ?: return
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ScreenTitle(inv.invoiceNumber ?: "#${inv.id}")

                // Status + dates
                ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        inv.status?.let {
                            val tone = when (it.lowercase()) {
                                "paid" -> BadgeTone.SUCCESS
                                "partial" -> BadgeTone.WARNING
                                "overdue" -> BadgeTone.ERROR
                                else -> BadgeTone.NEUTRAL
                            }
                            StatusBadge(it, tone)
                        }
                        inv.clientName?.let { DetailRow(strings.clientName, it) }
                        inv.issueDate?.let { DetailRow(strings.issueDate, it) }
                        inv.dueDate?.let { DetailRow(strings.dueDate, it) }
                    }
                }

                // Line items
                if (inv.items.isNotEmpty()) {
                    SectionTitle(strings.items)
                    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            inv.items.forEach { item ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            item.productName ?: strings.productsTitle,
                                            style = MaterialTheme.typography.bodyMedium,
                                            fontWeight = FontWeight.SemiBold,
                                        )
                                        Text(
                                            "${item.quantity.toInt()} × ${item.unitPrice ?: "0"}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        )
                                    }
                                    Text(
                                        item.total ?: "0.00",
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.SemiBold,
                                    )
                                }
                                HorizontalDivider()
                            }
                        }
                    }
                }

                // Totals
                ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        inv.subtotal?.let { DetailRow(strings.subtotal, it) }
                        inv.discount?.let { DetailRow(strings.discount, "-$it") }
                        inv.tax?.let { DetailRow(strings.tax, it) }
                        Spacer(Modifier.height(4.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(strings.grandTotal, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                            Text(inv.total ?: "0.00", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        }
                        HorizontalDivider()
                        inv.paidAmount?.let { DetailRow(strings.paid, it) }
                        inv.dueAmount?.let {
                            DetailRow(strings.dueAmount, it, valueColor = MaterialTheme.colorScheme.error)
                        }
                    }
                }

                inv.note?.takeIf { it.isNotBlank() }?.let {
                    SectionTitle(strings.notes)
                    Text(it, style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }
}

@Composable
private fun DetailRow(
    label: String,
    value: String,
    valueColor: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurface,
) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = valueColor)
    }
}
