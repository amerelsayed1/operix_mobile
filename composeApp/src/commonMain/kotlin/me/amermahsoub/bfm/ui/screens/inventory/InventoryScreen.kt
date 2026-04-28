package me.amermahsoub.bfm.ui.screens.inventory

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
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
import compose.icons.feathericons.AlertTriangle
import compose.icons.feathericons.ArrowLeft
import compose.icons.feathericons.Search
import me.amermahsoub.bfm.shared.data.models.Inventory
import me.amermahsoub.bfm.shared.data.models.InventoryProduct
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.StockMovement
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.ui.theme.OperixWarning
import me.amermahsoub.bfm.viewmodel.inventory.InventoryViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InventoryScreen(onBack: () -> Unit) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        InventoryViewModel(
            api = koin.get(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val inventoriesState by viewModel.inventoriesState.collectAsState()
    val selectedInventory by viewModel.selectedInventory.collectAsState()
    val stockState by viewModel.stockState.collectAsState()
    val movementsState by viewModel.movementsState.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()
    val showLowStockOnly by viewModel.showLowStockOnly.collectAsState()

    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = listOf("Stock Levels", "Movements")

    // Date/type filters for movements tab
    var movementTypeFilter by remember { mutableStateOf<String?>(null) }
    var movementFromDate by remember { mutableStateOf("") }
    var movementToDate by remember { mutableStateOf("") }

    LaunchedEffect(selectedTab) {
        if (selectedTab == 1) {
            viewModel.loadMovements(type = movementTypeFilter, fromDate = movementFromDate.takeIf { it.isNotBlank() }, toDate = movementToDate.takeIf { it.isNotBlank() })
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Inventory", fontWeight = FontWeight.SemiBold) },
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
                        text = { Text(title) },
                    )
                }
            }

            when (selectedTab) {
                0 -> StockLevelsTab(
                    inventoriesState = inventoriesState,
                    selectedInventory = selectedInventory,
                    stockState = stockState,
                    searchQuery = searchQuery,
                    showLowStockOnly = showLowStockOnly,
                    onSelectInventory = { viewModel.selectInventory(it) },
                    onSearchChange = { q ->
                        viewModel.setSearchQuery(q)
                        viewModel.loadStock(search = q.takeIf { it.isNotBlank() })
                    },
                    onLowStockToggle = { enabled ->
                        viewModel.setLowStockFilter(enabled)
                        viewModel.loadStock(lowStockOnly = enabled)
                    },
                )
                1 -> MovementsTab(
                    movementsState = movementsState,
                    typeFilter = movementTypeFilter,
                    fromDate = movementFromDate,
                    toDate = movementToDate,
                    onTypeFilter = { type ->
                        movementTypeFilter = type
                        viewModel.loadMovements(type = type, fromDate = movementFromDate.takeIf { it.isNotBlank() }, toDate = movementToDate.takeIf { it.isNotBlank() })
                    },
                    onFromDateChange = { movementFromDate = it },
                    onToDateChange = { movementToDate = it },
                    onApplyDateFilter = {
                        viewModel.loadMovements(
                            type = movementTypeFilter,
                            fromDate = movementFromDate.takeIf { it.isNotBlank() },
                            toDate = movementToDate.takeIf { it.isNotBlank() },
                        )
                    },
                )
            }
        }
    }
}

@Composable
private fun StockLevelsTab(
    inventoriesState: Result<List<Inventory>>,
    selectedInventory: Inventory?,
    stockState: Result<me.amermahsoub.bfm.shared.data.models.PaginatedResponse<InventoryProduct>>,
    searchQuery: String,
    showLowStockOnly: Boolean,
    onSelectInventory: (Inventory) -> Unit,
    onSearchChange: (String) -> Unit,
    onLowStockToggle: (Boolean) -> Unit,
) {
    Column(Modifier.fillMaxSize()) {
        // Inventory selector
        if (inventoriesState is Result.Success) {
            val inventories = inventoriesState.data
            LazyRow(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(inventories) { inv ->
                    val isSelected = inv.id == selectedInventory?.id
                    Box(
                        modifier = Modifier
                            .background(
                                if (isSelected) OperixPrimary else Color.White,
                                shape = RoundedCornerShape(20.dp),
                            )
                            .border(1.dp, if (isSelected) OperixPrimary else Color(0xFFE2E8F0), RoundedCornerShape(20.dp))
                            .clickable { onSelectInventory(inv) }
                            .padding(horizontal = 14.dp, vertical = 6.dp),
                    ) {
                        Text(
                            inv.name,
                            color = if (isSelected) Color.White else OperixTextSecondary,
                            fontSize = 13.sp,
                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                        )
                    }
                }
            }
        }

        // Search + low-stock toggle
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = onSearchChange,
                modifier = Modifier.weight(1f),
                placeholder = { Text("Search products…", fontSize = 13.sp) },
                leadingIcon = { Icon(FeatherIcons.Search, contentDescription = null, modifier = Modifier.size(18.dp)) },
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )
        }

        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text("Low stock only", fontSize = 13.sp, color = OperixTextSecondary)
            Switch(checked = showLowStockOnly, onCheckedChange = onLowStockToggle)
        }

        Divider()

        when (stockState) {
            is Result.Loading -> LoadingScreen()
            is Result.Error -> ErrorView(stockState.message)
            is Result.Success -> {
                val items = stockState.data.data
                if (items.isEmpty()) {
                    EmptyView("No products found")
                } else {
                    LazyColumn(Modifier.fillMaxSize()) {
                        items(items) { item ->
                            InventoryProductRow(item)
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun InventoryProductRow(item: InventoryProduct) {
    val qty = item.quantity.toDoubleOrNull() ?: 0.0
    val minAlert = item.product?.minimumStockAlert ?: 0
    val isLow = minAlert > 0 && qty <= minAlert

    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(item.product?.name ?: "Product #${item.productId}", fontWeight = FontWeight.Medium)
            Spacer(Modifier.height(2.dp))
            Text(item.product?.sku ?: "", color = OperixTextSecondary, fontSize = 12.sp)
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            if (isLow) {
                Icon(FeatherIcons.AlertTriangle, contentDescription = "Low stock", tint = OperixWarning, modifier = Modifier.size(16.dp))
            }
            Text(
                item.quantity,
                fontWeight = FontWeight.SemiBold,
                color = if (isLow) OperixWarning else MaterialTheme.colorScheme.onSurface,
                fontSize = 15.sp,
            )
        }
    }
}

@Composable
private fun MovementsTab(
    movementsState: Result<me.amermahsoub.bfm.shared.data.models.PaginatedResponse<StockMovement>>,
    typeFilter: String?,
    fromDate: String,
    toDate: String,
    onTypeFilter: (String?) -> Unit,
    onFromDateChange: (String) -> Unit,
    onToDateChange: (String) -> Unit,
    onApplyDateFilter: () -> Unit,
) {
    val movementTypes = listOf("in", "out", "adjustment", "transfer")

    Column(Modifier.fillMaxSize()) {
        // Type filter chips
        LazyRow(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item {
                FilterChip(
                    selected = typeFilter == null,
                    onClick = { onTypeFilter(null) },
                    label = { Text("All") },
                )
            }
            items(movementTypes) { type ->
                FilterChip(
                    selected = typeFilter == type,
                    onClick = { onTypeFilter(if (typeFilter == type) null else type) },
                    label = { Text(type.replaceFirstChar { it.uppercase() }) },
                )
            }
        }

        // Date range
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedTextField(
                value = fromDate,
                onValueChange = onFromDateChange,
                modifier = Modifier.weight(1f),
                label = { Text("From", fontSize = 12.sp) },
                placeholder = { Text("YYYY-MM-DD", fontSize = 12.sp) },
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )
            OutlinedTextField(
                value = toDate,
                onValueChange = onToDateChange,
                modifier = Modifier.weight(1f),
                label = { Text("To", fontSize = 12.sp) },
                placeholder = { Text("YYYY-MM-DD", fontSize = 12.sp) },
                singleLine = true,
                shape = RoundedCornerShape(10.dp),
            )
        }

        Divider()

        when (movementsState) {
            is Result.Loading -> LoadingScreen()
            is Result.Error -> ErrorView(movementsState.message)
            is Result.Success -> {
                val items = movementsState.data.data
                if (items.isEmpty()) {
                    EmptyView("No movements found")
                } else {
                    LazyColumn(Modifier.fillMaxSize()) {
                        items(items) { movement ->
                            StockMovementRow(movement)
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun StockMovementRow(movement: StockMovement) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            StatusBadge(movement.type)
            Column {
                Text(movement.product?.name ?: "Product #${movement.productId}", fontWeight = FontWeight.Medium, fontSize = 14.sp)
                val movementReferenceType = movement.referenceType
                if (!movementReferenceType.isNullOrBlank()) {
                    Spacer(Modifier.height(2.dp))
                    Text(movementReferenceType, color = OperixTextSecondary, fontSize = 12.sp)
                }
            }
        }
        Column(horizontalAlignment = Alignment.End) {
            val isIn = movement.type.lowercase() in listOf("in", "purchase", "adjustment_increase")
            Text(
                "${if (isIn) "+" else "-"}${movement.quantity}",
                fontWeight = FontWeight.SemiBold,
                color = if (isIn) me.amermahsoub.bfm.ui.theme.OperixSuccess else me.amermahsoub.bfm.ui.theme.OperixError,
                fontSize = 14.sp,
            )
            val movementCreatedAt = movement.createdAt
            if (!movementCreatedAt.isNullOrBlank()) {
                Text(movementCreatedAt.take(10), color = OperixTextSecondary, fontSize = 11.sp)
            }
        }
    }
}
