package me.amermahsoub.bfm.ui.screens.suppliers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DateRangePicker
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDateRangePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.ArrowLeft
import compose.icons.feathericons.Calendar
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.ClientStatementEntry
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Supplier
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.SectionHeader
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.suppliers.SupplierViewModel
import org.koin.core.context.GlobalContext
import kotlinx.datetime.*
import kotlin.time.Clock

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SupplierDetailScreen(
    supplierId: Int,
    onBack: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        SupplierViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val supplierDetailState by viewModel.supplierDetail.collectAsState()
    val statementState by viewModel.statementState.collectAsState()

    var fromDate by remember { mutableStateOf(defaultSupplierFromDate()) }
    var toDate by remember { mutableStateOf(defaultSupplierToDate()) }
    var showDatePicker by remember { mutableStateOf(false) }

    val dateRangeState = rememberDateRangePickerState()

    LaunchedEffect(supplierId) {
        viewModel.loadSupplier(supplierId)
        viewModel.loadStatement(supplierId, fromDate, toDate)
    }

    if (showDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    val startMs = dateRangeState.selectedStartDateMillis
                    val endMs = dateRangeState.selectedEndDateMillis
                    if (startMs != null && endMs != null) {
                        fromDate = supplierMillisToDate(startMs)
                        toDate = supplierMillisToDate(endMs)
                        viewModel.loadStatement(supplierId, fromDate, toDate)
                    }
                    showDatePicker = false
                }) { Text("Apply") }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) { Text("Cancel") }
            },
        ) {
            DateRangePicker(state = dateRangeState)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Supplier Detail", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(FeatherIcons.ArrowLeft, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                ),
            )
        },
        containerColor = OperixSurface,
    ) { padding ->
        when (val state = supplierDetailState) {
            is Result.Loading -> LoadingScreen()
            is Result.Error -> ErrorView(state.message, onRetry = { viewModel.loadSupplier(supplierId) })
            is Result.Success -> {
                val supplier = state.data
                Column(
                    modifier = Modifier
                        .padding(padding)
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState()),
                ) {
                    // Supplier info card
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(supplier.companyName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                                    val supplierContactName = supplier.contactName
                                    if (!supplierContactName.isNullOrBlank()) {
                                        Text(supplierContactName, color = OperixTextSecondary, fontSize = 13.sp)
                                    }
                                }
                                StatusBadge(if (supplier.isActive) "active" else "inactive")
                            }

                            Spacer(Modifier.height(12.dp))
                            Divider()
                            Spacer(Modifier.height(12.dp))

                            SupplierInfoRow("Phone", supplier.phone ?: "—")
                            Spacer(Modifier.height(6.dp))
                            SupplierInfoRow("Email", supplier.email ?: "—")
                            Spacer(Modifier.height(6.dp))
                            SupplierInfoRow("Address", supplier.address ?: "—")
                            val supplierTaxNumber = supplier.taxNumber
                            if (!supplierTaxNumber.isNullOrBlank()) {
                                Spacer(Modifier.height(6.dp))
                                SupplierInfoRow("Tax Number", supplierTaxNumber)
                            }
                            if (supplier.paymentTerms != null) {
                                Spacer(Modifier.height(6.dp))
                                SupplierInfoRow("Payment Terms", "${supplier.paymentTerms} days")
                            }

                            Spacer(Modifier.height(12.dp))
                            Divider()
                            Spacer(Modifier.height(12.dp))

                            Column {
                                Text("Payable Balance", color = OperixTextSecondary, fontSize = 12.sp)
                                Spacer(Modifier.height(4.dp))
                                val payable = supplier.payableBalance.toDoubleOrNull() ?: 0.0
                                AmountText(amount = supplier.payableBalance, positive = payable <= 0, large = true)
                            }
                        }
                    }

                    // Statement section
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        SectionHeader(
                            title = "Statement",
                            actionLabel = "$fromDate → $toDate",
                            onAction = { showDatePicker = true },
                        )

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 4.dp),
                        ) {
                            Button(
                                onClick = { showDatePicker = true },
                                modifier = Modifier.fillMaxWidth(),
                            ) {
                                Icon(FeatherIcons.Calendar, contentDescription = null, modifier = Modifier.size(16.dp))
                                Text("  Change Date Range", fontSize = 14.sp)
                            }
                        }

                        Spacer(Modifier.height(4.dp))

                        when (val stateS = statementState) {
                            is Result.Loading -> LoadingScreen()
                            is Result.Error -> ErrorView(stateS.message, onRetry = {
                                viewModel.loadStatement(supplierId, fromDate, toDate)
                            })
                            is Result.Success -> {
                                val entries = stateS.data
                                if (entries.isEmpty()) {
                                    Column(
                                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                    ) {
                                        Text("No statement entries for this period.", color = OperixTextSecondary)
                                    }
                                } else {
                                    SupplierStatementHeader()
                                    Divider()
                                    entries.forEach { entry ->
                                        SupplierStatementEntryRow(entry)
                                        Divider()
                                    }
                                }
                            }
                        }

                        Spacer(Modifier.height(8.dp))
                    }

                    Spacer(Modifier.height(24.dp))
                }
            }
        }
    }
}

@Composable
private fun SupplierStatementHeader() {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text("Date", fontWeight = FontWeight.SemiBold, fontSize = 12.sp, modifier = Modifier.weight(1.5f))
        Text("Type", fontWeight = FontWeight.SemiBold, fontSize = 12.sp, modifier = Modifier.weight(1f))
        Text("Amount", fontWeight = FontWeight.SemiBold, fontSize = 12.sp, modifier = Modifier.weight(1f))
        Text("Balance", fontWeight = FontWeight.SemiBold, fontSize = 12.sp, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun SupplierStatementEntryRow(entry: ClientStatementEntry) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(entry.date, fontSize = 12.sp, modifier = Modifier.weight(1.5f))
        Text(entry.type.replaceFirstChar { it.uppercase() }, fontSize = 12.sp, modifier = Modifier.weight(1f))
        Column(modifier = Modifier.weight(1f)) {
            val amt = entry.amount.toDoubleOrNull() ?: 0.0
            AmountText(amount = entry.amount, positive = amt >= 0)
        }
        Column(modifier = Modifier.weight(1f)) {
            val bal = entry.balance.toDoubleOrNull() ?: 0.0
            AmountText(amount = entry.balance, positive = bal >= 0)
        }
    }
}

@Composable
private fun SupplierInfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = OperixTextSecondary, fontSize = 13.sp)
        Text(value, fontWeight = FontWeight.Medium, fontSize = 13.sp)
    }
}

private fun defaultSupplierFromDate(): String {
    val now = Clock.System.now()
    val from = now.minus(DateTimePeriod(days = 30), TimeZone.UTC)
    return from.toLocalDateTime(TimeZone.UTC).date.toString()
}

private fun defaultSupplierToDate(): String {
    val now = Clock.System.now()
    return now.toLocalDateTime(TimeZone.UTC).date.toString()
}

private fun supplierMillisToDate(millis: Long): String {
    val instant = Instant.fromEpochMilliseconds(millis)
    return instant.toLocalDateTime(TimeZone.UTC).date.toString()
}
