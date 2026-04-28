package me.amermahsoub.bfm

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Inventory
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.PointOfSale
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.savedstate.read
import me.amermahsoub.bfm.navigation.NavRoutes
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.ListItem
import me.amermahsoub.bfm.ui.components.SectionHeader
import me.amermahsoub.bfm.ui.screens.accounts.AccountsScreen
import me.amermahsoub.bfm.ui.screens.auth.LoginScreen
import me.amermahsoub.bfm.ui.screens.clients.ClientDetailScreen
import me.amermahsoub.bfm.ui.screens.clients.ClientFormScreen
import me.amermahsoub.bfm.ui.screens.clients.ClientListScreen
import me.amermahsoub.bfm.ui.screens.dashboard.DashboardScreen
import me.amermahsoub.bfm.ui.screens.expenses.ExpenseFormScreen
import me.amermahsoub.bfm.ui.screens.expenses.ExpenseListScreen
import me.amermahsoub.bfm.ui.screens.inventory.InventoryScreen
import me.amermahsoub.bfm.ui.screens.invoices.purchases.PurchaseInvoiceDetailScreen
import me.amermahsoub.bfm.ui.screens.invoices.purchases.PurchaseInvoiceFormScreen
import me.amermahsoub.bfm.ui.screens.invoices.purchases.PurchaseInvoiceListScreen
import me.amermahsoub.bfm.ui.screens.invoices.sales.SalesInvoiceDetailScreen
import me.amermahsoub.bfm.ui.screens.invoices.sales.SalesInvoiceFormScreen
import me.amermahsoub.bfm.ui.screens.invoices.sales.SalesInvoiceListScreen
import me.amermahsoub.bfm.ui.screens.pos.PosReceiptScreen
import me.amermahsoub.bfm.ui.screens.pos.PosScreen
import me.amermahsoub.bfm.ui.screens.pos.PosTerminalScreen
import me.amermahsoub.bfm.ui.screens.pos.ShiftSummaryScreen
import me.amermahsoub.bfm.ui.screens.products.ProductDetailScreen
import me.amermahsoub.bfm.ui.screens.products.ProductFormScreen
import me.amermahsoub.bfm.ui.screens.products.ProductListScreen
import me.amermahsoub.bfm.ui.screens.reports.AccountStatementScreen
import me.amermahsoub.bfm.ui.screens.reports.ProfitLossScreen
import me.amermahsoub.bfm.ui.screens.reports.ReportsScreen
import me.amermahsoub.bfm.ui.screens.reports.TrialBalanceScreen
import me.amermahsoub.bfm.ui.screens.settings.SettingsScreen
import me.amermahsoub.bfm.ui.screens.suppliers.SupplierDetailScreen
import me.amermahsoub.bfm.ui.screens.suppliers.SupplierFormScreen
import me.amermahsoub.bfm.ui.screens.suppliers.SupplierListScreen
import me.amermahsoub.bfm.ui.theme.OperixTheme
import org.koin.compose.koinInject

@Composable
fun App() {
    OperixTheme {
        val sessionStore: SessionStore = koinInject()
        val session by sessionStore.session.collectAsState()

        val navController = rememberNavController()
        val startDestination = if (session != null) NavRoutes.Dashboard.route else NavRoutes.Login.route

        NavHost(navController = navController, startDestination = startDestination) {

            // ── Auth ───────────────────────────────────────────────────────
            composable(NavRoutes.Login.route) {
                LoginScreen(
                    onLoginSuccess = {
                        navController.navigate(NavRoutes.Dashboard.route) {
                            popUpTo(NavRoutes.Login.route) { inclusive = true }
                        }
                    },
                )
            }

            // ── Main shell (bottom nav) ────────────────────────────────────
            composable(NavRoutes.Dashboard.route) {
                MainShell(rootNav = navController)
            }

            // ── POS full-screen flows ──────────────────────────────────────
            composable(NavRoutes.PosActiveShift.route) {
                PosScreen(
                    shiftId = -1,
                    onOrderCompleted = { orderId -> navController.navigate(NavRoutes.PosReceipt.build(orderId)) },
                    onCloseShift = { navController.popBackStack().let {} },
                )
            }
            composable(NavRoutes.PosReceipt.route) { backStack ->
                val orderId = backStack.arguments?.read { getStringOrNull("orderId") }?.toIntOrNull() ?: return@composable
                PosReceiptScreen(
                    orderId = orderId,
                    onNewSale = {
                        navController.navigate(NavRoutes.PosActiveShift.route) {
                            popUpTo(NavRoutes.PosActiveShift.route) { inclusive = true }
                        }
                    },
                )
            }
            composable(NavRoutes.ShiftSummary.route) { backStack ->
                val shiftId = backStack.arguments?.read { getStringOrNull("shiftId") }?.toIntOrNull() ?: return@composable
                ShiftSummaryScreen(
                    shiftId = shiftId,
                    onShiftClosed = { navController.popBackStack().let {} },
                    onBack = { navController.popBackStack().let {} },
                )
            }

            // ── Products ───────────────────────────────────────────────────
            composable(NavRoutes.ProductList.route) {
                ProductListScreen(
                    onNavigateToDetail = { navController.navigate(NavRoutes.ProductDetail.build(it)) },
                    onNavigateToCreate = { navController.navigate(NavRoutes.ProductCreate.route) },
                )
            }
            composable(NavRoutes.ProductDetail.route) { backStack ->
                val id = backStack.arguments?.read { getStringOrNull("productId") }?.toIntOrNull() ?: return@composable
                ProductDetailScreen(productId = id, onNavigateToEdit = { navController.navigate(NavRoutes.ProductEdit.build(it)) }, onBack = { navController.popBackStack().let {} })
            }
            composable(NavRoutes.ProductCreate.route) {
                ProductFormScreen(productId = null, onSaved = { navController.popBackStack().let {} }, onBack = { navController.popBackStack().let {} })
            }
            composable(NavRoutes.ProductEdit.route) { backStack ->
                val id = backStack.arguments?.read { getStringOrNull("productId") }?.toIntOrNull() ?: return@composable
                ProductFormScreen(productId = id, onSaved = { navController.popBackStack().let {} }, onBack = { navController.popBackStack().let {} })
            }

            // ── Sales Invoices ─────────────────────────────────────────────
            composable(NavRoutes.SalesInvoiceList.route) {
                SalesInvoiceListScreen(
                    onNavigateToDetail = { navController.navigate(NavRoutes.SalesInvoiceDetail.build(it)) },
                    onNavigateToCreate = { navController.navigate(NavRoutes.SalesInvoiceCreate.route) },
                )
            }
            composable(NavRoutes.SalesInvoiceDetail.route) { backStack ->
                val id = backStack.arguments?.read { getStringOrNull("invoiceId") }?.toIntOrNull() ?: return@composable
                SalesInvoiceDetailScreen(invoiceId = id, onBack = { navController.popBackStack().let {} })
            }
            composable(NavRoutes.SalesInvoiceCreate.route) {
                SalesInvoiceFormScreen(onSaved = { navController.popBackStack().let {} }, onBack = { navController.popBackStack().let {} })
            }

            // ── Purchase Invoices ──────────────────────────────────────────
            composable(NavRoutes.PurchaseInvoiceList.route) {
                PurchaseInvoiceListScreen(
                    onNavigateToDetail = { navController.navigate(NavRoutes.PurchaseInvoiceDetail.build(it)) },
                    onNavigateToCreate = { navController.navigate(NavRoutes.PurchaseInvoiceCreate.route) },
                )
            }
            composable(NavRoutes.PurchaseInvoiceDetail.route) { backStack ->
                val id = backStack.arguments?.read { getStringOrNull("invoiceId") }?.toIntOrNull() ?: return@composable
                PurchaseInvoiceDetailScreen(invoiceId = id, onBack = { navController.popBackStack().let {} })
            }
            composable(NavRoutes.PurchaseInvoiceCreate.route) {
                PurchaseInvoiceFormScreen(onSaved = { navController.popBackStack().let {} }, onBack = { navController.popBackStack().let {} })
            }

            // ── Clients ────────────────────────────────────────────────────
            composable(NavRoutes.ClientList.route) {
                ClientListScreen(
                    onNavigateToDetail = { navController.navigate(NavRoutes.ClientDetail.build(it)) },
                    onNavigateToCreate = { navController.navigate(NavRoutes.ClientCreate.route) },
                )
            }
            composable(NavRoutes.ClientDetail.route) { backStack ->
                val id = backStack.arguments?.read { getStringOrNull("clientId") }?.toIntOrNull() ?: return@composable
                ClientDetailScreen(clientId = id, onBack = { navController.popBackStack().let {} })
            }
            composable(NavRoutes.ClientCreate.route) {
                ClientFormScreen(clientId = null, onSaved = { navController.popBackStack().let {} }, onBack = { navController.popBackStack().let {} })
            }

            // ── Suppliers ──────────────────────────────────────────────────
            composable(NavRoutes.SupplierList.route) {
                SupplierListScreen(
                    onNavigateToDetail = { navController.navigate(NavRoutes.SupplierDetail.build(it)) },
                    onNavigateToCreate = { navController.navigate(NavRoutes.SupplierCreate.route) },
                )
            }
            composable(NavRoutes.SupplierDetail.route) { backStack ->
                val id = backStack.arguments?.read { getStringOrNull("supplierId") }?.toIntOrNull() ?: return@composable
                SupplierDetailScreen(supplierId = id, onBack = { navController.popBackStack().let {} })
            }
            composable(NavRoutes.SupplierCreate.route) {
                SupplierFormScreen(supplierId = null, onSaved = { navController.popBackStack().let {} }, onBack = { navController.popBackStack().let {} })
            }

            // ── Inventory ──────────────────────────────────────────────────
            composable(NavRoutes.InventoryList.route) {
                InventoryScreen(onBack = { navController.popBackStack().let {} })
            }

            // ── Expenses ───────────────────────────────────────────────────
            composable(NavRoutes.ExpenseList.route) {
                ExpenseListScreen(onNavigateToCreate = { navController.navigate(NavRoutes.ExpenseCreate.route) })
            }
            composable(NavRoutes.ExpenseCreate.route) {
                ExpenseFormScreen(onSaved = { navController.popBackStack().let {} }, onBack = { navController.popBackStack().let {} })
            }

            // ── Reports ────────────────────────────────────────────────────
            composable(NavRoutes.Reports.route) {
                ReportsScreen(onNavigate = { navController.navigate(it) })
            }
            composable(NavRoutes.ProfitLoss.route) {
                ProfitLossScreen(onBack = { navController.popBackStack().let {} })
            }
            composable(NavRoutes.TrialBalance.route) {
                TrialBalanceScreen(onBack = { navController.popBackStack().let {} })
            }
            composable(NavRoutes.AccountStatement.route) {
                AccountStatementScreen(onBack = { navController.popBackStack().let {} })
            }

            // ── Accounts & GL ──────────────────────────────────────────────
            composable(NavRoutes.Accounts.route) {
                AccountsScreen(onBack = { navController.popBackStack().let {} })
            }

            // ── Settings ───────────────────────────────────────────────────
            composable(NavRoutes.Settings.route) {
                SettingsScreen(
                    onNavigate = { navController.navigate(it) },
                    onLogout = {
                        navController.navigate(NavRoutes.Login.route) {
                            popUpTo(0) { inclusive = true }
                        }
                    },
                )
            }
        }
    }
}

// ── Bottom-nav main shell ──────────────────────────────────────────────────

private data class BottomTab(val label: String, val icon: ImageVector, val route: String)

private val bottomTabs = listOf(
    BottomTab("Dashboard", Icons.Filled.Dashboard, NavRoutes.Dashboard.route),
    BottomTab("POS", Icons.Filled.PointOfSale, NavRoutes.PosTerminals.route),
    BottomTab("Invoices", Icons.Filled.Description, NavRoutes.SalesInvoiceList.route),
    BottomTab("Products", Icons.Filled.Inventory, NavRoutes.ProductList.route),
    BottomTab("More", Icons.Filled.Menu, NavRoutes.More.route),
)

@Composable
private fun MainShell(rootNav: NavHostController) {
    val innerNav = rememberNavController()
    val backStackEntry by innerNav.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar {
                bottomTabs.forEach { tab ->
                    NavigationBarItem(
                        selected = currentRoute == tab.route,
                        onClick = {
                            innerNav.navigate(tab.route) {
                                popUpTo(innerNav.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) },
                    )
                }
            }
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            NavHost(innerNav, startDestination = NavRoutes.Dashboard.route) {
                composable(NavRoutes.Dashboard.route) { DashboardScreen() }
                composable(NavRoutes.PosTerminals.route) {
                    PosTerminalScreen(
                        onShiftOpened = { _ -> rootNav.navigate(NavRoutes.PosActiveShift.route) },
                        onBack = {},
                    )
                }
                composable(NavRoutes.SalesInvoiceList.route) {
                    SalesInvoiceListScreen(
                        onNavigateToDetail = { rootNav.navigate(NavRoutes.SalesInvoiceDetail.build(it)) },
                        onNavigateToCreate = { rootNav.navigate(NavRoutes.SalesInvoiceCreate.route) },
                    )
                }
                composable(NavRoutes.ProductList.route) {
                    ProductListScreen(
                        onNavigateToDetail = { rootNav.navigate(NavRoutes.ProductDetail.build(it)) },
                        onNavigateToCreate = { rootNav.navigate(NavRoutes.ProductCreate.route) },
                    )
                }
                composable(NavRoutes.More.route) { MoreScreen(onNavigate = { rootNav.navigate(it) }) }
            }
        }
    }
}

@Composable
private fun MoreScreen(onNavigate: (String) -> Unit) {
    val menuItems = listOf(
        "Clients" to NavRoutes.ClientList.route,
        "Suppliers" to NavRoutes.SupplierList.route,
        "Purchase Invoices" to NavRoutes.PurchaseInvoiceList.route,
        "Inventory" to NavRoutes.InventoryList.route,
        "Expenses" to NavRoutes.ExpenseList.route,
        "Reports" to NavRoutes.Reports.route,
        "Accounts & GL" to NavRoutes.Accounts.route,
        "Settings" to NavRoutes.Settings.route,
    )
    LazyColumn(Modifier.fillMaxSize()) {
        item { SectionHeader("More") }
        items(menuItems) { (label, route) ->
            ListItem(title = label, onClick = { onNavigate(route) })
            Divider()
        }
    }
}
