package me.amermahsoub.bfm.ui.screens.reports

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.ArrowLeft
import compose.icons.feathericons.ChevronDown
import me.amermahsoub.bfm.shared.data.models.Account
import me.amermahsoub.bfm.shared.data.models.AccountStatementEntry
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
fun AccountStatementScreen(onBack: () -> Unit) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ReportViewModel(api = koin.get(), sessionStore = koin.get<SessionStore>())
    }

    val statementState by viewModel.accountStatementState.collectAsState()
    val accounts by viewModel.accounts.collectAsState()
    val fromDate by viewModel.fromDate.collectAsState()
    val toDate by viewModel.toDate.collectAsState()

    var selectedAccount by remember { mutableStateOf<Account?>(null) }
    var accountExpanded by remember { mutableStateOf(false) }
    var localFrom by remember { mutableStateOf(fromDate) }
    var localTo by remember { mutableStateOf(toDate) }

    LaunchedEffect(Unit) {
        viewModel.loadAccounts()
    }

    // Pre-select first account when loaded
    if (selectedAccount == null && accounts.isNotEmpty()) {
        selectedAccount = accounts.first()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Account Statement", fontWeight = FontWeight.SemiBold) },
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
            // Account dropdown
            Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(10.dp))
                        .clickable { accountExpanded = true }
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    color = Color.White,
                    shape = RoundedCornerShape(10.dp),
                ) {
                    Row(
                        Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            selectedAccount?.name ?: "Select account",
                            fontSize = 14.sp,
                            modifier = Modifier.weight(1f),
                        )
                        Icon(FeatherIcons.ChevronDown, contentDescription = null, tint = OperixTextSecondary, modifier = Modifier.size(16.dp))
                    }
                }
                DropdownMenu(expanded = accountExpanded, onDismissRequest = { accountExpanded = false }) {
                    accounts.forEach { account ->
                        DropdownMenuItem(
                            text = {
                                Column {
                                    Text(account.name, fontWeight = FontWeight.Medium)
                                    Text(account.currentBalance, color = OperixTextSecondary, fontSize = 12.sp)
                                }
                            },
                            onClick = {
                                selectedAccount = account
                                accountExpanded = false
                            },
                        )
                    }
                }
            }

            // Date range
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
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
                        val acct = selectedAccount ?: return@Button
                        viewModel.setDateRange(localFrom, localTo)
                        viewModel.loadAccountStatement(acct.id)
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
                    shape = RoundedCornerShape(10.dp),
                ) {
                    Text("Load")
                }
            }

            Divider()

            when (statementState) {
                is Result.Loading -> LoadingScreen()
                is Result.Error -> ErrorView(
                    message = (statementState as Result.Error).message,
                    onRetry = {
                        selectedAccount?.let { viewModel.loadAccountStatement(it.id) }
                    },
                )
                is Result.Success -> {
                    val entries = (statementState as Result.Success<List<AccountStatementEntry>>).data
                    if (entries.isEmpty()) {
                        EmptyView("No transactions found for selected period")
                    } else {
                        StatementTable(entries)
                    }
                }
            }
        }
    }
}

@Composable
private fun StatementTable(entries: List<AccountStatementEntry>) {
    val scrollState = rememberScrollState()
    Column(Modifier.fillMaxSize().horizontalScroll(scrollState)) {
        // Header
        StatementRow(
            date = "Date",
            description = "Description",
            debit = "Debit",
            credit = "Credit",
            balance = "Balance",
            isHeader = true,
        )
        HorizontalDivider()

        LazyColumn(Modifier.weight(1f)) {
            items(entries) { entry ->
                StatementRow(
                    date = entry.date.take(10),
                    description = entry.description,
                    debit = entry.debitAmount ?: "-",
                    credit = entry.creditAmount ?: "-",
                    balance = entry.balance,
                    isHeader = false,
                )
                HorizontalDivider(color = Color(0xFFF1F5F9))
            }
        }
    }
}

@Composable
private fun StatementRow(
    date: String,
    description: String,
    debit: String,
    credit: String,
    balance: String,
    isHeader: Boolean,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(if (isHeader) Color(0xFFF8FAFC) else Color.White)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            date,
            modifier = Modifier.width(90.dp),
            fontSize = if (isHeader) 12.sp else 12.sp,
            fontWeight = if (isHeader) FontWeight.Bold else FontWeight.Normal,
            color = if (isHeader) OperixTextSecondary else MaterialTheme.colorScheme.onSurface,
            maxLines = 1,
        )
        Text(
            description,
            modifier = Modifier.width(160.dp),
            fontSize = if (isHeader) 12.sp else 13.sp,
            fontWeight = if (isHeader) FontWeight.Bold else FontWeight.Normal,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            debit,
            modifier = Modifier.width(80.dp),
            fontSize = if (isHeader) 12.sp else 13.sp,
            fontWeight = if (isHeader) FontWeight.Bold else FontWeight.Normal,
            color = if (isHeader) OperixTextSecondary else if (debit != "-") OperixError else OperixTextSecondary,
        )
        Text(
            credit,
            modifier = Modifier.width(80.dp),
            fontSize = if (isHeader) 12.sp else 13.sp,
            fontWeight = if (isHeader) FontWeight.Bold else FontWeight.Normal,
            color = if (isHeader) OperixTextSecondary else if (credit != "-") OperixSuccess else OperixTextSecondary,
        )
        val bal = balance.toDoubleOrNull() ?: 0.0
        Text(
            balance,
            modifier = Modifier.width(90.dp),
            fontSize = if (isHeader) 12.sp else 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = when {
                isHeader -> OperixTextSecondary
                bal > 0 -> OperixSuccess
                bal < 0 -> OperixError
                else -> MaterialTheme.colorScheme.onSurface
            },
        )
    }
}
