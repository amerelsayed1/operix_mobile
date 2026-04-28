package me.amermahsoub.bfm.ui.screens.clients

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
import compose.icons.FeatherIcons
import compose.icons.feathericons.Plus
import compose.icons.feathericons.Search
import compose.icons.feathericons.X
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.debounce
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.Client
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.ListItem
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.clients.ClientViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class, FlowPreview::class)
@Composable
fun ClientListScreen(
    onNavigateToDetail: (Int) -> Unit,
    onNavigateToCreate: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ClientViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val clientsState by viewModel.clientsState.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()
    var localSearch by remember { mutableStateOf(searchQuery) }

    LaunchedEffect(Unit) {
        snapshotFlow { localSearch }
            .debounce(350)
            .collect { query ->
                viewModel.loadClients(query.ifBlank { null }, 1)
            }
    }

    LaunchedEffect(Unit) {
        viewModel.loadClients()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Clients", fontWeight = FontWeight.Bold) },
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
                Icon(FeatherIcons.Plus, contentDescription = "New Client")
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
                placeholder = { Text("Search clients…") },
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

            when (val state = clientsState) {
                is Result.Loading -> LoadingScreen()
                is Result.Error -> ErrorView(state.message, onRetry = { viewModel.loadClients(localSearch.ifBlank { null }) })
                is Result.Success -> {
                    val clients = state.data.data
                    if (clients.isEmpty()) {
                        EmptyView("No clients found")
                    } else {
                        val meta = state.data.meta
                        LazyColumn {
                            items(clients, key = { it.id }) { client ->
                                ClientRow(client = client, onClick = { onNavigateToDetail(client.id) })
                                Divider()
                            }
                            if (meta != null && viewModel.currentPage < meta.lastPage) {
                                item {
                                    Box(
                                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                                        contentAlignment = Alignment.Center,
                                    ) {
                                        TextButton(onClick = {
                                            viewModel.loadClients(localSearch.ifBlank { null }, viewModel.currentPage + 1)
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
private fun ClientRow(client: Client, onClick: () -> Unit) {
    ListItem(
        title = client.name,
        subtitle = buildString {
            if (!client.phone.isNullOrBlank()) append(client.phone)
            if (!client.email.isNullOrBlank()) {
                if (isNotEmpty()) append(" • ")
                append(client.email)
            }
        }.ifBlank { null },
        trailing = {
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                val balanceVal = client.balance.toDoubleOrNull() ?: 0.0
                AmountText(amount = client.balance, positive = balanceVal >= 0)
            }
        },
        onClick = onClick,
    )
}
