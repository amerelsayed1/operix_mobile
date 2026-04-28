package me.amermahsoub.bfm.ui.screens.expenses

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
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
import compose.icons.feathericons.Plus
import me.amermahsoub.bfm.shared.data.models.Expense
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.expenses.ExpenseViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExpenseListScreen(onNavigateToCreate: () -> Unit) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ExpenseViewModel(
            api = koin.get(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val expensesState by viewModel.expensesState.collectAsState()
    val categories by viewModel.categories.collectAsState()
    val categoryFilter by viewModel.categoryFilter.collectAsState()
    val dateFrom by viewModel.dateFrom.collectAsState()
    val dateTo by viewModel.dateTo.collectAsState()

    var showDateFilter by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Expenses", fontWeight = FontWeight.SemiBold) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                ),
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = onNavigateToCreate,
                containerColor = OperixPrimary,
                contentColor = Color.White,
                shape = CircleShape,
            ) {
                Icon(FeatherIcons.Plus, contentDescription = "Add expense")
            }
        },
        containerColor = OperixSurface,
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {

            // Category filter chips
            if (categories.isNotEmpty()) {
                LazyRow(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    item {
                        FilterChip(
                            selected = categoryFilter == null,
                            onClick = { viewModel.setCategoryFilter(null) },
                            label = { Text("All") },
                        )
                    }
                    items(categories) { cat ->
                        FilterChip(
                            selected = categoryFilter == cat.id,
                            onClick = { viewModel.setCategoryFilter(if (categoryFilter == cat.id) null else cat.id) },
                            label = { Text(cat.displayName()) },
                        )
                    }
                }
            }

            // Date range filter toggle
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Filter by date", fontSize = 13.sp, color = OperixTextSecondary)
                TextButton(onClick = { showDateFilter = !showDateFilter }) {
                    Text(if (showDateFilter) "Hide" else "Show", fontSize = 13.sp)
                }
            }

            if (showDateFilter) {
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    OutlinedTextField(
                        value = dateFrom,
                        onValueChange = { viewModel.setDateFrom(it) },
                        modifier = Modifier.weight(1f),
                        label = { Text("From", fontSize = 12.sp) },
                        placeholder = { Text("YYYY-MM-DD", fontSize = 12.sp) },
                        singleLine = true,
                        shape = RoundedCornerShape(10.dp),
                    )
                    OutlinedTextField(
                        value = dateTo,
                        onValueChange = { viewModel.setDateTo(it) },
                        modifier = Modifier.weight(1f),
                        label = { Text("To", fontSize = 12.sp) },
                        placeholder = { Text("YYYY-MM-DD", fontSize = 12.sp) },
                        singleLine = true,
                        shape = RoundedCornerShape(10.dp),
                    )
                    TextButton(onClick = { viewModel.applyDateFilter() }) {
                        Text("Apply", fontSize = 13.sp)
                    }
                }
            }

            Divider()

            when (expensesState) {
                is Result.Loading -> LoadingScreen()
                is Result.Error -> ErrorView(
                    message = (expensesState as Result.Error).message,
                    onRetry = { viewModel.loadExpenses() },
                )
                is Result.Success -> {
                    val items = (expensesState as Result.Success).data.data
                    if (items.isEmpty()) {
                        EmptyView("No expenses found")
                    } else {
                        LazyColumn(Modifier.fillMaxSize()) {
                            items(items) { expense ->
                                ExpenseRow(expense)
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ExpenseRow(expense: Expense) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier.weight(1f),
        ) {
            val expenseCategory = expense.category
            if (expenseCategory != null) {
                StatusBadge(expenseCategory.displayName())
            }
            Column(Modifier.weight(1f)) {
                Text(expense.description, fontWeight = FontWeight.Medium, fontSize = 14.sp, maxLines = 1)
                Spacer(Modifier.height(2.dp))
                Text(expense.expenseDate, color = OperixTextSecondary, fontSize = 12.sp)
            }
        }
        Text(
            expense.amount,
            fontWeight = FontWeight.SemiBold,
            color = OperixError,
            fontSize = 15.sp,
        )
    }
}
