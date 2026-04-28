package me.amermahsoub.bfm.ui.screens.pos

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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.ArrowLeft
import compose.icons.feathericons.Calendar
import compose.icons.feathericons.CreditCard
import compose.icons.feathericons.DollarSign
import compose.icons.feathericons.RefreshCw
import compose.icons.feathericons.ShoppingBag
import compose.icons.feathericons.XCircle
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.models.PaymentBreakdown
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Shift
import me.amermahsoub.bfm.shared.data.models.ShiftSummary
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSuccess
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.ui.theme.OperixWarning
import me.amermahsoub.bfm.viewmodel.pos.PosViewModel
import me.amermahsoub.bfm.viewmodel.pos.ShiftSummaryViewModel
import org.koin.compose.koinInject

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShiftSummaryScreen(
    shiftId: Int,
    onShiftClosed: () -> Unit,
    onBack: () -> Unit,
) {
    val summaryViewModel: ShiftSummaryViewModel = koinInject()
    val posViewModel: PosViewModel = koinInject()

    val summaryState by summaryViewModel.summaryState.collectAsState()

    var showCloseDialog by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(shiftId) {
        summaryViewModel.loadSummary()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Shift Summary", fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(FeatherIcons.ArrowLeft, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { summaryViewModel.loadSummary() }) {
                        Icon(FeatherIcons.RefreshCw, contentDescription = "Refresh", modifier = Modifier.size(18.dp))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { paddingValues ->
        when (val state = summaryState) {
            is Result.Loading -> LoadingScreen("Loading shift summary…")
            is Result.Error -> ErrorView(state.message, onRetry = { summaryViewModel.loadSummary() })
            is Result.Success -> {
                val summary = state.data
                val shift = summary.shift

                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .padding(horizontal = 16.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Spacer(Modifier.height(8.dp))

                    // Shift info
                    ShiftInfoCard(shift)

                    // Key metrics
                    MetricsCard(summary)

                    // Payment breakdown
                    if (summary.paymentBreakdown.isNotEmpty()) {
                        PaymentBreakdownCard(summary.paymentBreakdown)
                    }

                    // Cash reconciliation
                    CashReconciliationCard(summary)

                    // Close shift button (only if shift is still open)
                    if (shift.isOpen) {
                        Button(
                            onClick = { showCloseDialog = true },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(containerColor = OperixError),
                        ) {
                            Icon(FeatherIcons.XCircle, contentDescription = null, modifier = Modifier.size(18.dp))
                            Text("Close Shift", modifier = Modifier.padding(start = 8.dp), fontWeight = FontWeight.SemiBold)
                        }
                    }

                    Spacer(Modifier.height(16.dp))
                }
            }
        }
    }

    if (showCloseDialog) {
        CloseShiftDialog(
            expectedCash = (summaryState as? Result.Success)?.data?.expectedCash ?: "0.00",
            onConfirm = { closingCash, notes ->
                showCloseDialog = false
                scope.launch {
                    posViewModel.closeShift(closingCash, notes)
                    onShiftClosed()
                }
            },
            onDismiss = { showCloseDialog = false },
        )
    }
}

@Composable
private fun ShiftInfoCard(shift: Shift) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Shift Details", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                ShiftStatusBadge(shift.status)
            }
            HorizontalDivider()
            shift.terminal?.let { terminal ->
                InfoRow(label = "Terminal", value = "${terminal.name} (Slot #${terminal.slotNumber})")
            }
            shift.openedAt?.let { InfoRow("Opened At", it.take(16)) }
            shift.closedAt?.let { InfoRow("Closed At", it.take(16)) }
            InfoRow("Opening Cash", shift.openingCash)
            shift.closingCash?.let { InfoRow("Closing Cash", it) }
        }
    }
}

@Composable
private fun MetricsCard(summary: ShiftSummary) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text("Sales Summary", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
            HorizontalDivider()

            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                MetricTile(
                    icon = { Icon(FeatherIcons.ShoppingBag, null, tint = OperixPrimary, modifier = Modifier.size(20.dp)) },
                    label = "Total Orders",
                    value = summary.totalOrders.toString(),
                    modifier = Modifier.weight(1f),
                )
                MetricTile(
                    icon = { Icon(FeatherIcons.DollarSign, null, tint = OperixSuccess, modifier = Modifier.size(20.dp)) },
                    label = "Total Sales",
                    value = summary.totalSales,
                    modifier = Modifier.weight(1f),
                )
            }

            if (summary.totalRefunds != "0.00") {
                InfoRow("Total Refunds", summary.totalRefunds, valueColor = OperixError)
            }
            InfoRow("Cash Sales", summary.totalCashSales)
            InfoRow("Card Sales", summary.totalCardSales)
        }
    }
}

@Composable
private fun PaymentBreakdownCard(breakdown: List<PaymentBreakdown>) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(FeatherIcons.CreditCard, contentDescription = null, tint = OperixPrimary, modifier = Modifier.size(18.dp))
                Text("Payment Breakdown", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
            }
            HorizontalDivider()
            breakdown.forEach { item ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Column {
                        Text(
                            item.paymentMethod.replaceFirstChar { it.uppercase() },
                            fontWeight = FontWeight.Medium,
                            fontSize = 14.sp,
                        )
                        Text(
                            "${item.count} transaction${if (item.count != 1) "s" else ""}",
                            color = OperixTextSecondary,
                            fontSize = 12.sp,
                        )
                    }
                    Text(item.total, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = OperixPrimary)
                }
            }
        }
    }
}

@Composable
private fun CashReconciliationCard(summary: ShiftSummary) {
    val variance = summary.cashVariance?.toDoubleOrNull() ?: 0.0
    val varianceColor = when {
        variance > 0.01 -> OperixSuccess
        variance < -0.01 -> OperixError
        else -> OperixTextSecondary
    }

    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(FeatherIcons.DollarSign, contentDescription = null, tint = OperixWarning, modifier = Modifier.size(18.dp))
                Text("Cash Reconciliation", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
            }
            HorizontalDivider()
            InfoRow("Expected Cash", summary.expectedCash)
            summary.countedCash?.let { InfoRow("Counted Cash", it) }
            summary.cashVariance?.let {
                InfoRow("Variance", it, valueColor = varianceColor)
            }
        }
    }
}

@Composable
private fun MetricTile(
    icon: @Composable () -> Unit,
    label: String,
    value: String,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(10.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.background),
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            icon()
            Text(value, fontWeight = FontWeight.Bold, fontSize = 18.sp)
            Text(label, color = OperixTextSecondary, fontSize = 12.sp)
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String, valueColor: Color = Color.Unspecified) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(label, color = OperixTextSecondary, fontSize = 13.sp)
        Text(
            value,
            fontWeight = FontWeight.Medium,
            fontSize = 13.sp,
            color = if (valueColor != Color.Unspecified) valueColor else MaterialTheme.colorScheme.onSurface,
        )
    }
}

@Composable
private fun ShiftStatusBadge(status: String) {
    val (bg, fg) = when (status.lowercase()) {
        "open" -> Color(0xFFDCFCE7) to Color(0xFF166534)
        "closed" -> Color(0xFFFEE2E2) to Color(0xFF991B1B)
        else -> Color(0xFFF1F5F9) to Color(0xFF475569)
    }
    androidx.compose.material3.Surface(
        shape = RoundedCornerShape(20.dp),
        color = bg,
    ) {
        Text(
            status.replaceFirstChar { it.uppercase() },
            color = fg,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
        )
    }
}

@Composable
private fun CloseShiftDialog(
    expectedCash: String,
    onConfirm: (closingCash: Double, notes: String?) -> Unit,
    onDismiss: () -> Unit,
) {
    var cashInput by remember { mutableStateOf(expectedCash) }
    var notesInput by remember { mutableStateOf("") }
    var inputError by remember { mutableStateOf<String?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Close Shift", fontWeight = FontWeight.SemiBold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    "Count the cash in the drawer and enter the closing amount. This action cannot be undone.",
                    color = OperixTextSecondary,
                    fontSize = 14.sp,
                )
                Text("Expected cash: $expectedCash", fontWeight = FontWeight.Medium, color = OperixPrimary, fontSize = 14.sp)
                OutlinedTextField(
                    value = cashInput,
                    onValueChange = {
                        cashInput = it
                        inputError = null
                    },
                    label = { Text("Counted Cash") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    isError = inputError != null,
                    supportingText = inputError?.let { { Text(it, color = MaterialTheme.colorScheme.error) } },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )
                OutlinedTextField(
                    value = notesInput,
                    onValueChange = { notesInput = it },
                    label = { Text("Closing Notes (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 3,
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val amount = cashInput.toDoubleOrNull()
                    if (amount == null || amount < 0) {
                        inputError = "Enter a valid cash amount"
                        return@Button
                    }
                    onConfirm(amount, notesInput.takeIf { it.isNotBlank() })
                },
                colors = ButtonDefaults.buttonColors(containerColor = OperixError),
            ) {
                Text("Close Shift")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        },
    )
}
