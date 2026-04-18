package me.amermahsoub.bfm.features.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.nav.LocalAppNavigator
import me.amermahsoub.bfm.app.nav.Route
import me.amermahsoub.bfm.app.permission.LocalPermissionGuard
import me.amermahsoub.bfm.features.clients.ClientsListScreen
import me.amermahsoub.bfm.features.dashboard.DashboardScreen
import me.amermahsoub.bfm.features.more.MoreScreen
import me.amermahsoub.bfm.features.pos.PosCartScreen
import me.amermahsoub.bfm.features.products.ProductsListScreen

enum class HomeTab(val permissions: List<String>) {
    DASHBOARD(listOf("dashboard.view", "pos.view")),
    POS(listOf("pos.view", "pos.create")),
    CLIENTS(listOf("clients.view")),
    PRODUCTS(listOf("products.view", "inventory.view")),
    MORE(emptyList()),
}

@Composable
fun HomeScreen(onLogout: () -> Unit) {
    val guard = LocalPermissionGuard.current
    val nav = LocalAppNavigator.current
    val strings = appStrings()

    val visibleTabs = remember(guard) {
        HomeTab.entries.filter { tab ->
            tab.permissions.isEmpty() || guard.hasAny(*tab.permissions.toTypedArray())
        }.ifEmpty { listOf(HomeTab.MORE) }
    }

    var selected by rememberSaveable { mutableStateOf(visibleTabs.first().name) }
    val currentTab = visibleTabs.firstOrNull { it.name == selected } ?: visibleTabs.first()

    Column(modifier = Modifier.fillMaxSize()) {
        Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
            when (currentTab) {
                HomeTab.DASHBOARD -> DashboardScreen(
                    onStartSale = { selected = HomeTab.POS.name },
                    onRecordPayment = { nav.push(Route.ClientsList) },
                    onAddExpense = { nav.push(Route.ExpenseForm()) },
                    onOrderClicked = { id -> nav.push(Route.PosOrderDetail(id)) },
                    onClients = {
                        if (visibleTabs.contains(HomeTab.CLIENTS)) selected = HomeTab.CLIENTS.name
                        else nav.push(Route.ClientsList)
                    },
                    onProducts = {
                        if (visibleTabs.contains(HomeTab.PRODUCTS)) selected = HomeTab.PRODUCTS.name
                        else nav.push(Route.ProductsList)
                    },
                    onInventory = { nav.push(Route.InventoryList) },
                    onAccounts = { nav.push(Route.AccountsList) },
                    onExpenses = { nav.push(Route.ExpensesList) },
                )
                HomeTab.POS -> {
                    val scannedBarcode = nav.consumeResult<String>("barcode")
                    PosCartScreen(
                        onOpenShift = { nav.push(Route.OpenShift) },
                        onCloseShift = { nav.push(Route.CloseShift) },
                        onOrderPlaced = { id -> nav.push(Route.PosOrderDetail(id)) },
                        onViewOrders = { nav.push(Route.PosOrders) },
                        onScanBarcode = { nav.push(Route.BarcodeScanner) },
                        scannedBarcode = scannedBarcode,
                    )
                }
                HomeTab.CLIENTS -> ClientsListScreen(
                    onClient = { id -> nav.push(Route.ClientDetail(id)) },
                    onAddClient = { nav.push(Route.ClientForm()) },
                )
                HomeTab.PRODUCTS -> ProductsListScreen(
                    onProduct = { id -> nav.push(Route.ProductDetail(id)) },
                )
                HomeTab.MORE -> MoreScreen(
                    onInventories = { nav.push(Route.InventoryList) },
                    onExpenses = { nav.push(Route.ExpensesList) },
                    onAccounts = { nav.push(Route.AccountsList) },
                    onShiftHistory = { nav.push(Route.ShiftHistory) },
                    onCashMovement = { nav.push(Route.CashMovement) },
                    onProfile = { nav.push(Route.Profile) },
                    onSettings = { nav.push(Route.Settings) },
                    onLogout = onLogout,
                )
            }
        }
        NavigationBar {
            visibleTabs.forEach { tab ->
                NavigationBarItem(
                    selected = tab == currentTab,
                    onClick = { selected = tab.name },
                    icon = { Text(iconFor(tab), style = MaterialTheme.typography.titleLarge) },
                    label = { Text(labelFor(tab, strings)) },
                )
            }
        }
    }
}

private fun labelFor(tab: HomeTab, strings: me.amermahsoub.bfm.app.i18n.AppStrings) = when (tab) {
    HomeTab.DASHBOARD -> strings.tabDashboard
    HomeTab.POS -> strings.tabPos
    HomeTab.CLIENTS -> strings.tabClients
    HomeTab.PRODUCTS -> strings.tabProducts
    HomeTab.MORE -> strings.tabMore
}

private fun iconFor(tab: HomeTab): String = when (tab) {
    HomeTab.DASHBOARD -> "\uD83C\uDFE0" // 🏠
    HomeTab.POS -> "\uD83D\uDED2" // 🛒
    HomeTab.CLIENTS -> "\uD83D\uDC65" // 👥
    HomeTab.PRODUCTS -> "\uD83D\uDCE6" // 📦
    HomeTab.MORE -> "\u2630" // ☰
}
