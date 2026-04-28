package me.amermahsoub.bfm.ui.screens.clients

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
import me.amermahsoub.bfm.shared.data.models.Client
import me.amermahsoub.bfm.shared.data.models.ClientStatementEntry
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.SectionHeader
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.clients.ClientViewModel
import org.koin.core.context.GlobalContext
import kotlinx.datetime.*
import kotlin.time.Clock

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ClientDetailScreen(
    clientId: Int,
    onBack: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ClientViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val clientDetailState by viewModel.clientDetail.collectAsState()
    val statementState by viewModel.statementState.collectAsState()

    // Date range state — default last 30 days
    var fromDate by remember { mutableStateOf(defaultFromDate()) }
    var toDate by remember { mutableStateOf(defaultToDate()) }
    var showDatePicker by remember { mutableStateOf(false) }

    LaunchedEffect(clientId) {
        viewModel.loadClient(clientId)
        viewModel.loadStatement(clientId, fromDate, toDate)
    }

    val dateRangeState = rememberDateRangePickerState()

    if (showDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    val startMs = dateRangeState.selectedStartDateMillis
                    val endMs = dateRangeState.selectedEndDateMillis
                    if (startMs != null && endMs != null) {
                        fromDate = millisToDateString(startMs)
                        toDate = millisToDateString(endMs)
                        viewModel.loadStatement(clientId, fromDate, toDate)
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
                title = { Text("Client Detail", fontWeight = FontWeight.Bold) },
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
        when (val state = clientDetailState) {
            is Result.Loading -> LoadingScreen()
            is Result.Error -> ErrorView(state.message, onRetry = { viewModel.loadClient(clientId) })
            is Result.Success -> {
                val client = state.data
                Column(
                    modifier = Modifier
                        .padding(padding)
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState()),
                ) {
                    // Client info card
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
                                Text(client.name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                                StatusBadge(if (client.isActive) "active" else "inactive")
                            }
                            Spacer(Modifier.height(12.dp))
                            Divider()
                            Spacer(Modifier.height(12.dp))

                            ClientInfoRow("Phone", client.phone ?: "—")
                            Spacer(Modifier.height(6.dp))
                            ClientInfoRow("Email", client.email ?: "—")
                            Spacer(Modifier.height(6.dp))
                            ClientInfoRow("Address", client.address ?: "—")
                            val clientTaxNumber = client.taxNumber
                            if (!clientTaxNumber.isNullOrBlank()) {
                                Spacer(Modifier.height(6.dp))
                                ClientInfoRow("Tax Number", clientTaxNumber)
                            }
                            Spacer(Modifier.height(12.dp))
                            Divider()
                            Spacer(Modifier.height(12.dp))

                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                                Column {
                                    Text("Balance", color = OperixTextSecondary, fontSize = 12.sp)
                                    Spacer(Modifier.height(4.dp))
                                    val bal = client.balance.toDoubleOrNull() ?: 0.0
                                    AmountText(amount = client.balance, positive = bal >= 0, large = true)
                                }
                                Column {
                                    Text("Credit Limit", color = OperixTextSecondary, fontSize = 12.sp)
                                    Spacer(Modifier.height(4.dp))
                                    AmountText(amount = client.creditLimit, positive = true)
                                }
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
                                viewModel.loadStatement(clientId, fromDate, toDate)
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
                                    // Header row
                                    StatementHeaderRow()
                                    Divider()
                                    entries.forEach { entry ->
                                        StatementEntryRow(entry)
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
private fun StatementHeaderRow() {
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
private fun StatementEntryRow(entry: ClientStatementEntry) {
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
private fun ClientInfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = OperixTextSecondary, fontSize = 13.sp)
        Text(value, fontWeight = FontWeight.Medium, fontSize = 13.sp)
    }
}

// Helpers for default date range (last 30 days)
private fun defaultFromDate(): String {
    // Simple ISO date string 30 days ago — using epoch math for KMP compatibility
    val now = Clock.System.now()
    val from = now.minus(DateTimePeriod(days = 30), TimeZone.UTC)
    val localFrom = from.toLocalDateTime(TimeZone.UTC).date
    return localFrom.toString()
}

private fun defaultToDate(): String {
    val now = Clock.System.now()
    val local = now.toLocalDateTime(TimeZone.UTC).date
    return local.toString()
}

private fun millisToDateString(millis: Long): String {
    val instant = Instant.fromEpochMilliseconds(millis)
    val local = instant.toLocalDateTime(TimeZone.UTC).date
    return local.toString()
}
