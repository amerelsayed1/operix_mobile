package me.amermahsoub.bfm.ui.screens.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.DashboardKpiItem
import me.amermahsoub.bfm.shared.data.tenant.LowStockItem
import me.amermahsoub.bfm.shared.data.tenant.RecentOrderItem
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.EmptyView
import me.amermahsoub.bfm.ui.components.ErrorView
import me.amermahsoub.bfm.ui.components.KpiCard
import me.amermahsoub.bfm.ui.components.LoadingScreen
import me.amermahsoub.bfm.ui.components.SectionHeader
import me.amermahsoub.bfm.ui.components.StatusBadge
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.dashboard.DashboardViewModel
import org.koin.core.context.GlobalContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen() {
    val koin = GlobalContext.get()
    val viewModel = remember {
        DashboardViewModel(
            apiService = koin.get<OperixApiService>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val sessionStore = remember { koin.get<SessionStore>() }
    val session by sessionStore.session.collectAsState()

    val dashboardState by viewModel.dashboardState.collectAsState()
    val recentOrdersState by viewModel.recentOrdersState.collectAsState()
    val lowStockState by viewModel.lowStockState.collectAsState()

    val scope = rememberCoroutineScope()
    val pullRefreshState = rememberPullToRefreshState()
    var isRefreshing by remember { mutableStateOf(false) }

    val userName = session?.login?.user?.name ?: "User"
    val tenantName = session?.login?.tenant?.name ?: "Operix"

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Dashboard",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                        )
                        Text(
                            text = tenantName,
                            style = MaterialTheme.typography.bodySmall,
                            color = OperixTextSecondary,
                        )
                    }
                },
                actions = {
                    UserAvatar(name = userName)
                    Spacer(Modifier.width(12.dp))
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                ),
            )
        },
        containerColor = OperixSurface,
    ) { paddingValues ->
        PullToRefreshBox(
            isRefreshing = isRefreshing,
            state = pullRefreshState,
            onRefresh = {
                isRefreshing = true
                scope.launch {
                    viewModel.refresh()
                    isRefreshing = false
                }
            },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
        ) {
            when (dashboardState) {
                is Result.Loading -> LoadingScreen()
                is Result.Error -> ErrorView(
                    message = (dashboardState as Result.Error).message,
                    onRetry = { viewModel.refresh() },
                )
                is Result.Success -> {
                    val kpiItems = (dashboardState as Result.Success<List<DashboardKpiItem>>).data
                    DashboardContent(
                        kpiItems = kpiItems,
                        recentOrdersState = recentOrdersState,
                        lowStockState = lowStockState,
                        onRetry = { viewModel.refresh() },
                    )
                }
            }
        }
    }
}

@Composable
private fun DashboardContent(
    kpiItems: List<DashboardKpiItem>,
    recentOrdersState: Result<List<RecentOrderItem>>,
    lowStockState: Result<List<LowStockItem>>,
    onRetry: () -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        // KPI grid
        if (kpiItems.isNotEmpty()) {
            item {
                SectionHeader(title = "Overview")
            }
            item {
                KpiGrid(items = kpiItems)
                Spacer(Modifier.height(8.dp))
            }
        } else {
            item {
                EmptyView(message = "No KPI data available")
            }
        }

        // Low Stock section
        item {
            Divider()
            SectionHeader(title = "Low Stock Alerts")
        }
        item {
            when (lowStockState) {
                is Result.Loading -> {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(80.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        androidx.compose.material3.CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = OperixPrimary,
                            strokeWidth = 2.dp,
                        )
                    }
                }
                is Result.Error -> {
                    Text(
                        text = "Failed to load low stock items",
                        color = OperixTextSecondary,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    )
                }
                is Result.Success -> {
                    val items = (lowStockState as Result.Success<List<LowStockItem>>).data
                    if (items.isEmpty()) {
                        Text(
                            text = "No low stock items",
                            color = OperixTextSecondary,
                            style = MaterialTheme.typography.bodySmall,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        )
                    } else {
                        Column {
                            items.forEach { item ->
                                LowStockRow(item = item)
                                Divider(modifier = Modifier.padding(horizontal = 16.dp))
                            }
                        }
                    }
                }
            }
        }

        // Recent Orders section
        item {
            Spacer(Modifier.height(8.dp))
            Divider()
            SectionHeader(title = "Recent Orders")
        }
        when (recentOrdersState) {
            is Result.Loading -> {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(80.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        androidx.compose.material3.CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = OperixPrimary,
                            strokeWidth = 2.dp,
                        )
                    }
                }
            }
            is Result.Error -> {
                item {
                    Text(
                        text = "Failed to load recent orders",
                        color = OperixTextSecondary,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    )
                }
            }
            is Result.Success -> {
                val orders = (recentOrdersState as Result.Success<List<RecentOrderItem>>).data
                if (orders.isEmpty()) {
                    item {
                        Text(
                            text = "No recent orders",
                            color = OperixTextSecondary,
                            style = MaterialTheme.typography.bodySmall,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        )
                    }
                } else {
                    items(orders) { order ->
                        RecentOrderRow(order = order)
                        Divider(modifier = Modifier.padding(horizontal = 16.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun KpiGrid(items: List<DashboardKpiItem>) {
    val chunked = items.chunked(2)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        chunked.forEach { rowItems ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                rowItems.forEach { item ->
                    KpiCard(
                        label = item.label,
                        value = item.value,
                        change = item.change,
                        modifier = Modifier.weight(1f),
                    )
                }
                // If odd number of items, fill the remaining space
                if (rowItems.size == 1) {
                    Spacer(Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun LowStockRow(item: LowStockItem) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.name,
                fontWeight = FontWeight.Medium,
                style = MaterialTheme.typography.bodyMedium,
            )
            if (item.sku != null) {
                Text(
                    text = "SKU: ${item.sku}",
                    color = OperixTextSecondary,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = "Qty: ${item.availableQty ?: 0}",
                fontWeight = FontWeight.SemiBold,
                fontSize = 13.sp,
            )
            if (item.minimumQty != null) {
                Text(
                    text = "Min: ${item.minimumQty}",
                    color = OperixTextSecondary,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
}

@Composable
private fun RecentOrderRow(order: RecentOrderItem) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = order.number ?: "Order #${order.id}",
                fontWeight = FontWeight.Medium,
                style = MaterialTheme.typography.bodyMedium,
            )
            val orderCustomer = order.customer
            if (orderCustomer != null) {
                Text(
                    text = orderCustomer,
                    color = OperixTextSecondary,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            val orderTotal = order.total
            if (orderTotal != null) {
                Text(
                    text = orderTotal,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                )
            }
            val orderStatus = order.status
            if (orderStatus != null) {
                StatusBadge(status = orderStatus)
            }
        }
    }
}

@Composable
private fun UserAvatar(name: String) {
    val initial = name.firstOrNull()?.uppercase() ?: "U"
    Box(
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(OperixPrimary),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = initial,
            color = Color.White,
            fontWeight = FontWeight.Bold,
            fontSize = 16.sp,
        )
    }
}
