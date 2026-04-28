package me.amermahsoub.bfm.ui.screens.accounts

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
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
import me.amermahsoub.bfm.shared.data.models.Account
import me.amermahsoub.bfm.shared.data.models.AccountingPeriod
import me.amermahsoub.bfm.shared.data.models.GlAccount
import me.amermahsoub.bfm.shared.data.models.JournalEntry
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSuccess
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.accounts.AccountsViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountsScreen(onBack: () -> Unit) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        AccountsViewModel(api = koin.get(), sessionStore = koin.get<SessionStore>())
    }

    val accountsState by viewModel.accountsState.collectAsState()
    val glAccountsState by viewModel.glAccountsState.collectAsState()
    val journalEntriesState by viewModel.journalEntriesState.collectAsState()
    val periodsState by viewModel.periodsState.collectAsState()

    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = listOf("Cash/Bank", "GL Accounts", "Journals", "Periods")

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Accounts", fontWeight = FontWeight.SemiBold) },
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
            TabRow(selectedTabIndex = selectedTab, containerColor = Color.White) {
                tabs.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        text = { Text(title, fontSize = 12.sp) },
                    )
                }
            }

            when (selectedTab) {
                0 -> CashAccountsTab(accountsState) { viewModel.loadAccounts() }
                1 -> GlAccountsTab(glAccountsState) { viewModel.loadGlAccounts() }
                2 -> JournalEntriesTab(journalEntriesState) { viewModel.loadJournalEntries() }
                3 -> PeriodsTab(periodsState) { viewModel.loadPeriods() }
            }
        }
    }
}

// ── Cash / Bank Accounts Tab ──────────────────────────────────────────────────

@Composable
private fun CashAccountsTab(
    state: Result<List<Account>>,
    onRetry: () -> Unit,
) {
    when (state) {
        is Result.Loading -> LoadingScreen()
        is Result.Error -> ErrorView(state.message, onRetry)
        is Result.Success -> {
            val accounts = state.data
            if (accounts.isEmpty()) {
                EmptyView("No accounts found")
            } else {
                LazyColumn(Modifier.fillMaxSize()) {
                    items(accounts) { account ->
                        CashAccountRow(account)
                        Divider()
                    }
                }
            }
        }
    }
}

@Composable
private fun CashAccountRow(account: Account) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(account.name, fontWeight = FontWeight.Medium, fontSize = 14.sp)
                if (account.isDefault) {
                    Surface(
                        color = Color(0xFFDBEAFE),
                        shape = RoundedCornerShape(10.dp),
                    ) {
                        Text("Default", color = OperixPrimary, fontSize = 10.sp, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                    }
                }
                if (account.isDrawer) {
                    Surface(
                        color = Color(0xFFFEF9C3),
                        shape = RoundedCornerShape(10.dp),
                    ) {
                        Text("Drawer", color = Color(0xFF713F12), fontSize = 10.sp, modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                    }
                }
            }
            val accountType = account.type
            if (!accountType.isNullOrBlank()) {
                Spacer(Modifier.height(2.dp))
                Text(accountType, color = OperixTextSecondary, fontSize = 12.sp)
            }
        }
        val balance = account.currentBalance.toDoubleOrNull() ?: 0.0
        Text(
            account.currentBalance,
            fontWeight = FontWeight.SemiBold,
            color = if (balance >= 0) OperixSuccess else OperixError,
            fontSize = 15.sp,
        )
    }
}

// ── GL Accounts Tab ───────────────────────────────────────────────────────────

@Composable
private fun GlAccountsTab(
    state: Result<List<GlAccount>>,
    onRetry: () -> Unit,
) {
    when (state) {
        is Result.Loading -> LoadingScreen()
        is Result.Error -> ErrorView(state.message, onRetry)
        is Result.Success -> {
            val accounts = state.data
            if (accounts.isEmpty()) {
                EmptyView("No GL accounts found")
            } else {
                LazyColumn(Modifier.fillMaxSize()) {
                    items(accounts) { account ->
                        GlAccountRow(account, indent = 0)
                    }
                }
            }
        }
    }
}

@Composable
private fun GlAccountRow(account: GlAccount, indent: Int) {
    Column {
        Row(
            Modifier.fillMaxWidth().padding(start = (16 + indent * 16).dp, end = 16.dp, top = 10.dp, bottom = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(account.code, fontSize = 11.sp, color = OperixTextSecondary, fontWeight = FontWeight.Medium)
                    Text(account.name, fontWeight = if (account.children.isNotEmpty()) FontWeight.SemiBold else FontWeight.Normal, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
                Text(account.accountType.replace("_", " ").replaceFirstChar { it.uppercase() }, color = OperixTextSecondary, fontSize = 11.sp)
            }
            val bal = account.balance.toDoubleOrNull() ?: 0.0
            Text(
                account.balance,
                fontWeight = FontWeight.Medium,
                color = if (bal >= 0) OperixSuccess else OperixError,
                fontSize = 13.sp,
            )
        }
        Divider()
        account.children.forEach { child ->
            GlAccountRow(child, indent + 1)
        }
    }
}

// ── Journal Entries Tab ───────────────────────────────────────────────────────

@Composable
private fun JournalEntriesTab(
    state: Result<me.amermahsoub.bfm.shared.data.models.PaginatedResponse<JournalEntry>>,
    onRetry: () -> Unit,
) {
    when (state) {
        is Result.Loading -> LoadingScreen()
        is Result.Error -> ErrorView(state.message, onRetry)
        is Result.Success -> {
            val entries = state.data.data
            if (entries.isEmpty()) {
                EmptyView("No journal entries found")
            } else {
                LazyColumn(Modifier.fillMaxSize()) {
                    items(entries) { entry ->
                        JournalEntryRow(entry)
                        Divider()
                    }
                }
            }
        }
    }
}

@Composable
private fun JournalEntryRow(entry: JournalEntry) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                val entryReference = entry.reference
                if (!entryReference.isNullOrBlank()) {
                    Text(entryReference, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                }
                StatusBadge(entry.status)
            }
            Spacer(Modifier.height(2.dp))
            val entryDescription = entry.description
            if (!entryDescription.isNullOrBlank()) {
                Text(entryDescription, color = OperixTextSecondary, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            Text(entry.entryDate.take(10), color = OperixTextSecondary, fontSize = 11.sp)
        }
        Column(horizontalAlignment = Alignment.End) {
            Text("Dr ${entry.totalDebits}", fontSize = 12.sp, color = OperixError, fontWeight = FontWeight.Medium)
            Text("Cr ${entry.totalCredits}", fontSize = 12.sp, color = OperixSuccess, fontWeight = FontWeight.Medium)
        }
    }
}

// ── Periods Tab ───────────────────────────────────────────────────────────────

@Composable
private fun PeriodsTab(
    state: Result<List<AccountingPeriod>>,
    onRetry: () -> Unit,
) {
    when (state) {
        is Result.Loading -> LoadingScreen()
        is Result.Error -> ErrorView(state.message, onRetry)
        is Result.Success -> {
            val periods = state.data
            if (periods.isEmpty()) {
                EmptyView("No accounting periods found")
            } else {
                LazyColumn(Modifier.fillMaxSize()) {
                    items(periods) { period ->
                        PeriodRow(period)
                        Divider()
                    }
                }
            }
        }
    }
}

@Composable
private fun PeriodRow(period: AccountingPeriod) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(period.name, fontWeight = FontWeight.Medium, fontSize = 14.sp)
            Spacer(Modifier.height(2.dp))
            Text(
                "${period.startDate.take(10)}  →  ${period.endDate.take(10)}",
                color = OperixTextSecondary,
                fontSize = 12.sp,
            )
        }
        StatusBadge(period.status)
    }
}
