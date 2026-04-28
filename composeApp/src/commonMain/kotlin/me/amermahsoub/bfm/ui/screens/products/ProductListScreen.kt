package me.amermahsoub.bfm.ui.screens.products

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
import androidx.compose.foundation.lazy.rememberLazyListState
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
import me.amermahsoub.bfm.shared.data.models.Product
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.AmountText
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.products.ProductViewModel
import org.koin.core.context.GlobalContext

private enum class ActiveFilter(val label: String) {
    All("All"),
    Active("Active"),
    Inactive("Inactive"),
}

@OptIn(ExperimentalMaterial3Api::class, FlowPreview::class)
@Composable
fun ProductListScreen(
    onNavigateToDetail: (Int) -> Unit,
    onNavigateToCreate: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        ProductViewModel(
            api = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val productsState by viewModel.productsState.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()

    var localSearch by remember { mutableStateOf(searchQuery) }
    var activeFilter by remember { mutableStateOf(ActiveFilter.All) }

    // Debounce search input
    LaunchedEffect(Unit) {
        snapshotFlow { localSearch }
            .debounce(350)
            .collect { query ->
                val isActive = when (activeFilter) {
                    ActiveFilter.Active -> true
                    ActiveFilter.Inactive -> false
                    ActiveFilter.All -> null
                }
                viewModel.loadProducts(query.ifBlank { null }, null, isActive, 1)
            }
    }

    // Reload when filter changes
    LaunchedEffect(activeFilter) {
        val isActive = when (activeFilter) {
            ActiveFilter.Active -> true
            ActiveFilter.Inactive -> false
            ActiveFilter.All -> null
        }
        viewModel.loadProducts(localSearch.ifBlank { null }, null, isActive, 1)
    }

    // Initial load
    LaunchedEffect(Unit) {
        viewModel.loadProducts()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Products", fontWeight = FontWeight.Bold) },
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
                Icon(FeatherIcons.Plus, contentDescription = "Create Product")
            }
        },
        containerColor = OperixSurface,
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize(),
        ) {
            // Search bar
            OutlinedTextField(
                value = localSearch,
                onValueChange = { localSearch = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                placeholder = { Text("Search products, SKU, barcode…") },
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

            // Filter chips
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                ActiveFilter.entries.forEach { filter ->
                    FilterChip(
                        selected = activeFilter == filter,
                        onClick = { activeFilter = filter },
                        label = { Text(filter.label, fontSize = 13.sp) },
                    )
                }
            }

            // Content
            when (val state = productsState) {
                is Result.Loading -> LoadingScreen()
                is Result.Error -> ErrorView(state.message, onRetry = { viewModel.loadProducts(localSearch.ifBlank { null }) })
                is Result.Success -> {
                    val products = state.data.data
                    if (products.isEmpty()) {
                        EmptyView("No products found")
                    } else {
                        val listState = rememberLazyListState()
                        val meta = state.data.meta

                        LazyColumn(state = listState) {
                            items(products, key = { it.id }) { product ->
                                ProductRow(product = product, onClick = { onNavigateToDetail(product.id) })
                                Divider()
                            }
                            // Pagination footer
                            if (meta != null && viewModel.currentPage < meta.lastPage) {
                                item {
                                    Box(
                                        modifier = Modifier.fillMaxWidth().padding(16.dp),
                                        contentAlignment = Alignment.Center,
                                    ) {
                                        androidx.compose.material3.TextButton(onClick = {
                                            val isActive = when (activeFilter) {
                                                ActiveFilter.Active -> true
                                                ActiveFilter.Inactive -> false
                                                ActiveFilter.All -> null
                                            }
                                            viewModel.loadProducts(localSearch.ifBlank { null }, null, isActive, viewModel.currentPage + 1)
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
private fun ProductRow(product: Product, onClick: () -> Unit) {
    me.amermahsoub.bfm.ui.components.ListItem(
        title = product.name,
        subtitle = buildString {
            if (!product.sku.isNullOrBlank()) append("SKU: ${product.sku}")
            product.category?.let { cat ->
                if (isNotEmpty()) append(" • ")
                append(cat.displayName())
            }
        }.ifBlank { null },
        trailing = {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                AmountText(amount = product.sellingPrice)
                StatusBadge(if (product.isActive) "active" else "inactive")
            }
        },
        onClick = onClick,
    )
}
