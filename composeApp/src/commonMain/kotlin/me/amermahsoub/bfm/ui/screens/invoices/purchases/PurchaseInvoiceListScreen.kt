package me.amermahsoub.bfm.ui.screens.invoices.purchases

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.Plus
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.PurchaseInvoice
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.invoices.PurchaseInvoiceViewModel
import org.koin.core.context.GlobalContext

private val purchaseStatusFilters = listOf(
    null to "All",
    "draft" to "Draft",
    "posted" to "Posted",
    "partial" to "Partial",
    "paid" to "Paid",
    "cancelled" to "Cancelled",
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PurchaseInvoiceListScreen(
    onNavigateToDetail: (Int) -> Unit,
    onNavigateToCreate: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        PurchaseInvoiceViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val invoicesState by viewModel.invoicesState.collectAsState()
    val statusFilter by viewModel.statusFilter.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadInvoices()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Purchase Invoices", fontWeight = FontWeight.Bold) },
                actions = {
                    IconButton(onClick = onNavigateToCreate) {
                        Icon(
                            imageVector = FeatherIcons.Plus,
                            contentDescription = "Create Purchase Invoice",
                            tint = OperixPrimary,
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White),
            )
        },
        containerColor = OperixSurface,
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            // Filter chips
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(purchaseStatusFilters) { (status, label) ->
                    val selected = statusFilter == status
                    FilterChip(
                        selected = selected,
                        onClick = { viewModel.setStatusFilter(status) },
                        label = { Text(label, fontSize = 13.sp) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = OperixPrimary,
                            selectedLabelColor = Color.White,
                        ),
                    )
                }
            }

            Divider()

            when (val state = invoicesState) {
                is Result.Loading -> LoadingScreen()
                is Result.Error -> ErrorView(
                    message = state.message,
                    onRetry = { viewModel.loadInvoices(statusFilter) },
                )
                is Result.Success -> {
                    val invoices = state.data.data
                    if (invoices.isEmpty()) {
                        EmptyView("No purchase invoices found")
                    } else {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(vertical = 8.dp),
                        ) {
                            items(invoices, key = { it.id }) { invoice ->
                                PurchaseInvoiceRow(
                                    invoice = invoice,
                                    onClick = { onNavigateToDetail(invoice.id) },
                                )
                                Divider(modifier = Modifier.padding(horizontal = 16.dp))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PurchaseInvoiceRow(
    invoice: PurchaseInvoice,
    onClick: () -> Unit,
) {
    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = invoice.invoiceNumber,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                )
                StatusBadge(status = invoice.status)
            }
            Spacer(Modifier.height(6.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column {
                    Text(
                        text = invoice.supplier?.companyName ?: "—",
                        color = OperixTextSecondary,
                        fontSize = 13.sp,
                    )
                    Spacer(Modifier.height(2.dp))
                    Text(
                        text = invoice.invoiceDate,
                        color = OperixTextSecondary,
                        fontSize = 12.sp,
                    )
                    if (invoice.supplierInvoiceNumber != null) {
                        Text(
                            text = "Ref: ${invoice.supplierInvoiceNumber}",
                            color = OperixTextSecondary,
                            fontSize = 11.sp,
                        )
                    }
                }
                AmountText(amount = invoice.total, positive = true)
            }
        }
    }
}
