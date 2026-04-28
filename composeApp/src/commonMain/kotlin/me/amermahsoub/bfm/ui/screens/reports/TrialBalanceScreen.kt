package me.amermahsoub.bfm.ui.screens.reports

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.ArrowLeft
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.TrialBalanceRow
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
fun TrialBalanceScreen(onBack: () -> Unit) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ReportViewModel(api = koin.get(), sessionStore = koin.get<SessionStore>())
    }

    val trialState by viewModel.trialBalanceState.collectAsState()
    val fromDate by viewModel.fromDate.collectAsState()
    val toDate by viewModel.toDate.collectAsState()

    var localFrom by remember { mutableStateOf(fromDate) }
    var localTo by remember { mutableStateOf(toDate) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Trial Balance", fontWeight = FontWeight.SemiBold) },
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
            // Date picker
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
                        viewModel.loadTrialBalance()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
                    shape = RoundedCornerShape(10.dp),
                ) {
                    Text("Load")
                }
            }

            Divider()

            when (trialState) {
                is Result.Loading -> LoadingScreen()
                is Result.Error -> ErrorView(
                    message = (trialState as Result.Error).message,
                    onRetry = { viewModel.loadTrialBalance() },
                )
                is Result.Success -> {
                    val rows = (trialState as Result.Success<List<TrialBalanceRow>>).data
                    if (rows.isEmpty()) {
                        EmptyView("No data found for selected period")
                    } else {
                        TrialBalanceTable(rows)
                    }
                }
            }
        }
    }
}

@Composable
private fun TrialBalanceTable(rows: List<TrialBalanceRow>) {
    val totalDebits = rows.sumOf { it.totalDebits.toDoubleOrNull() ?: 0.0 }
    val totalCredits = rows.sumOf { it.totalCredits.toDoubleOrNull() ?: 0.0 }
    val totalBalance = rows.sumOf { it.netBalance.toDoubleOrNull() ?: 0.0 }

    val scrollState = rememberScrollState()

    Column(Modifier.fillMaxSize().horizontalScroll(scrollState)) {
        // Header
        TableRow(
            code = "Code",
            name = "Account",
            debits = "Debits",
            credits = "Credits",
            balance = "Balance",
            isHeader = true,
        )
        HorizontalDivider()

        LazyColumn(Modifier.weight(1f)) {
            items(rows) { row ->
                TableRow(
                    code = row.code,
                    name = row.name,
                    debits = row.totalDebits,
                    credits = row.totalCredits,
                    balance = row.netBalance,
                    isHeader = false,
                )
                HorizontalDivider(color = Color(0xFFF1F5F9))
            }
        }

        // Summary / totals row
        HorizontalDivider(thickness = 2.dp)
        TableRow(
            code = "",
            name = "TOTAL",
            debits = "%.2f".format(totalDebits),
            credits = "%.2f".format(totalCredits),
            balance = "%.2f".format(totalBalance),
            isHeader = true,
        )
    }
}

@Composable
private fun TableRow(
    code: String,
    name: String,
    debits: String,
    credits: String,
    balance: String,
    isHeader: Boolean,
) {
    val netBalance = balance.toDoubleOrNull() ?: 0.0
    Row(
        Modifier
            .fillMaxWidth()
            .background(if (isHeader) Color(0xFFF8FAFC) else Color.White)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            code,
            modifier = Modifier.width(60.dp),
            fontSize = if (isHeader) 12.sp else 13.sp,
            fontWeight = if (isHeader) FontWeight.Bold else FontWeight.Normal,
            color = if (isHeader) OperixTextSecondary else MaterialTheme.colorScheme.onSurface,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            name,
            modifier = Modifier.width(160.dp),
            fontSize = if (isHeader) 12.sp else 13.sp,
            fontWeight = if (isHeader) FontWeight.Bold else FontWeight.Normal,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            debits,
            modifier = Modifier.width(90.dp),
            fontSize = if (isHeader) 12.sp else 13.sp,
            fontWeight = if (isHeader) FontWeight.Bold else FontWeight.Normal,
            color = if (isHeader) OperixTextSecondary else OperixError,
        )
        Text(
            credits,
            modifier = Modifier.width(90.dp),
            fontSize = if (isHeader) 12.sp else 13.sp,
            fontWeight = if (isHeader) FontWeight.Bold else FontWeight.Normal,
            color = if (isHeader) OperixTextSecondary else OperixSuccess,
        )
        Text(
            balance,
            modifier = Modifier.width(90.dp),
            fontSize = if (isHeader) 12.sp else 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = when {
                isHeader -> OperixTextSecondary
                netBalance > 0 -> OperixSuccess
                netBalance < 0 -> OperixError
                else -> MaterialTheme.colorScheme.onSurface
            },
        )
    }
}
