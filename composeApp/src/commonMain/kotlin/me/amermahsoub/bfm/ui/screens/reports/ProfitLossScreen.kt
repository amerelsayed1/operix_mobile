package me.amermahsoub.bfm.ui.screens.reports

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
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
import compose.icons.feathericons.ChevronDown
import compose.icons.feathericons.ChevronRight
import me.amermahsoub.bfm.shared.data.models.ProfitLossReport
import me.amermahsoub.bfm.shared.data.models.ReportLine
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSuccess
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.reports.ReportViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfitLossScreen(onBack: () -> Unit) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ReportViewModel(api = koin.get(), sessionStore = koin.get<SessionStore>())
    }

    val plState by viewModel.plState.collectAsState()
    val fromDate by viewModel.fromDate.collectAsState()
    val toDate by viewModel.toDate.collectAsState()

    var localFrom by remember { mutableStateOf(fromDate) }
    var localTo by remember { mutableStateOf(toDate) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Profit & Loss", fontWeight = FontWeight.SemiBold) },
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
        Column(Modifier.fillMaxSize().padding(padding)) {
            // Date range picker
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                OutlinedTextField(
                    value = localFrom,
                    onValueChange = { localFrom = it },
                    modifier = Modifier.weight(1f),
                    label = { Text("From", fontSize = 12.sp) },
                    singleLine = true,
                    shape = RoundedCornerShape(10.dp),
                )
                OutlinedTextField(
                    value = localTo,
                    onValueChange = { localTo = it },
                    modifier = Modifier.weight(1f),
                    label = { Text("To", fontSize = 12.sp) },
                    singleLine = true,
                    shape = RoundedCornerShape(10.dp),
                )
                Button(
                    onClick = {
                        viewModel.setDateRange(localFrom, localTo)
                        viewModel.loadProfitLoss()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
                    shape = RoundedCornerShape(10.dp),
                ) {
                    Text("Load")
                }
            }

            Divider()

            when (plState) {
                is Result.Loading -> LoadingScreen()
                is Result.Error -> ErrorView(
                    message = (plState as Result.Error).message,
                    onRetry = { viewModel.loadProfitLoss() },
                )
                is Result.Success -> {
                    ProfitLossContent(report = (plState as Result.Success<ProfitLossReport>).data)
                }
            }
        }
    }
}

@Composable
private fun ProfitLossContent(report: ProfitLossReport) {
    var revenueExpanded by remember { mutableStateOf(false) }
    var expenseExpanded by remember { mutableStateOf(false) }

    LazyColumn(Modifier.fillMaxSize().padding(horizontal = 16.dp)) {
        // Revenue
        item {
            Spacer(Modifier.height(12.dp))
            ExpandableSectionHeader(
                title = "Revenue",
                amount = report.revenue,
                positive = true,
                expanded = revenueExpanded,
                onClick = { revenueExpanded = !revenueExpanded },
            )
        }
        if (revenueExpanded) {
            items(report.revenueBreakdown) { line ->
                BreakdownRow(line)
            }
        }

        // COGS
        item {
            Spacer(Modifier.height(4.dp))
            SummaryRow("Cost of Goods Sold", report.cogs, positive = false)
            Spacer(Modifier.height(4.dp))
            Divider()
        }

        // Gross profit
        item {
            SummaryRow("Gross Profit", report.grossProfit, positive = (report.grossProfit.toDoubleOrNull() ?: 0.0) >= 0)
            Spacer(Modifier.height(4.dp))
            Divider()
        }

        // Expenses
        item {
            Spacer(Modifier.height(4.dp))
            ExpandableSectionHeader(
                title = "Total Expenses",
                amount = report.totalExpenses,
                positive = false,
                expanded = expenseExpanded,
                onClick = { expenseExpanded = !expenseExpanded },
            )
        }
        if (expenseExpanded) {
            items(report.expenseBreakdown) { line ->
                BreakdownRow(line)
            }
        }

        // Net profit
        item {
            Spacer(Modifier.height(8.dp))
            Divider()
            Spacer(Modifier.height(8.dp))
            val net = report.netProfit.toDoubleOrNull() ?: 0.0
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = if (net >= 0) Color(0xFFDCFCE7) else Color(0xFFFEE2E2),
                ),
                shape = RoundedCornerShape(12.dp),
            ) {
                Row(
                    Modifier.fillMaxWidth().padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Net Profit", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                    Text(
                        report.netProfit,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 20.sp,
                        color = if (net >= 0) Color(0xFF166534) else OperixError,
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
private fun ExpandableSectionHeader(
    title: String,
    amount: String,
    positive: Boolean,
    expanded: Boolean,
    onClick: () -> Unit,
) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(
                imageVector = if (expanded) FeatherIcons.ChevronDown else FeatherIcons.ChevronRight,
                contentDescription = null,
                tint = OperixTextSecondary,
                modifier = Modifier.size(16.dp),
            )
            Text(title, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
        }
        Text(
            amount,
            fontWeight = FontWeight.SemiBold,
            color = if (positive) OperixSuccess else OperixError,
            fontSize = 15.sp,
        )
    }
}

@Composable
private fun SummaryRow(label: String, amount: String, positive: Boolean) {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 10.dp, horizontal = 22.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, fontSize = 14.sp, color = OperixTextSecondary)
        Text(
            amount,
            fontWeight = FontWeight.Medium,
            color = if (positive) OperixSuccess else OperixError,
            fontSize = 14.sp,
        )
    }
}

@Composable
private fun BreakdownRow(line: ReportLine) {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 6.dp, horizontal = 32.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(line.label, fontSize = 13.sp, color = OperixTextSecondary, modifier = Modifier.weight(1f))
        Text(line.amount, fontSize = 13.sp, fontWeight = FontWeight.Medium)
    }
}
