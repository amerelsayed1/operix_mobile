package me.amermahsoub.bfm.ui.screens.suppliers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.Plus
import compose.icons.feathericons.Search
import compose.icons.feathericons.X
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.debounce
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Supplier
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.ListItem
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.suppliers.SupplierViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class, FlowPreview::class)
@Composable
fun SupplierListScreen(
    onNavigateToDetail: (Int) -> Unit,
    onNavigateToCreate: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        SupplierViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val suppliersState by viewModel.suppliersState.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()
    var localSearch by remember { mutableStateOf(searchQuery) }

    LaunchedEffect(Unit) {
        snapshotFlow { localSearch }
            .debounce(350)
            .collect { query ->
                viewModel.loadSuppliers(query.ifBlank { null }, 1)
            }
    }

    LaunchedEffect(Unit) {
        viewModel.loadSuppliers()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Suppliers", fontWeight = FontWeight.Bold) },
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
            ) {
                Icon(FeatherIcons.Plus, contentDescription = "New Supplier")
            }
        },
        containerColor = OperixSurface,
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize(),
        ) {
            OutlinedTextField(
                value = localSearch,
                onValueChange = { localSearch = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                placeholder = { Text("Search suppliers…") },
                leadingIcon = {
                    Icon(FeatherIcons.Search, contentDescription = null, tint = OperixTextSecondary, modifier = Modifier.size(18.dp))
                },
                trailingIcon = {
                    if (localSearch.isNotBlank()) {
                        IconButton(onClick = { localSearch = "" }) {
                            Icon(FeatherIcons.X, contentDescription = "Clear", tint = OperixTextSecondary, modifier = Modifier.size(16.dp))
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(12.dp),
            )

            when (val state = suppliersState) {
                is Result.Loading -> LoadingScreen()
                is Result.Error -> ErrorView(state.message, onRetry = { viewModel.loadSuppliers(localSearch.ifBlank { null }) })
                is Result.Success -> {
                    val suppliers = state.data.data
                    if (suppliers.isEmpty()) {
                        EmptyView("No suppliers found")
                    } else {
                        val meta = state.data.meta
                        LazyColumn {
                            items(suppliers, key = { it.id }) { supplier ->
                                SupplierRow(supplier = supplier, onClick = { onNavigateToDetail(supplier.id) })
                                Divider()
                            }
                            if (meta != null && viewModel.currentPage < meta.lastPage) {
                                item {
                                    Box(
                                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                                        contentAlignment = Alignment.Center,
                                    ) {
                                        TextButton(onClick = {
                                            viewModel.loadSuppliers(localSearch.ifBlank { null }, viewModel.currentPage + 1)
                                        }) {
                                            Text("Load more (${meta.total} total)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SupplierRow(supplier: Supplier, onClick: () -> Unit) {
    ListItem(
        title = supplier.companyName,
        subtitle = buildString {
            if (!supplier.contactName.isNullOrBlank()) append(supplier.contactName)
            if (!supplier.phone.isNullOrBlank()) {
                if (isNotEmpty()) append(" • ")
                append(supplier.phone)
            }
        }.ifBlank { null },
        trailing = {
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(horizontalAlignment = Alignment.End) {
                    val payable = supplier.payableBalance.toDoubleOrNull() ?: 0.0
                    Text("Payable", color = OperixTextSecondary, fontSize = 11.sp)
                    AmountText(amount = supplier.payableBalance, positive = payable <= 0, large = false)
                }
            }
        },
        onClick = onClick,
    )
}
