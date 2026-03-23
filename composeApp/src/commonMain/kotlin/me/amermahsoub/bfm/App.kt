package me.amermahsoub.bfm

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.tenant.ConfigStore
import me.amermahsoub.bfm.shared.data.tenant.SessionBootstrap
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.shared.data.tenant.TenantContext
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.shared.data.tenant.isValidTenantSlug
import org.koin.core.context.GlobalContext

private enum class AppScreen { LOGIN, HOME }

private enum class HomeTab(
    val title: String,
    val requiredPermissions: Set<String>,
) {
    DASHBOARD("Dashboard", setOf("dashboard.view")),
    POS("POS", setOf("pos.view", "pos.create")),
    INVOICES("Invoices", setOf("sales.view", "sales.create", "purchases.view", "clients.view", "suppliers.view")),
    PRODUCTS("Products", setOf("products.view", "inventory.view")),
    MORE("More", emptySet()),
}

private data class StatCard(
    val label: String,
    val value: String,
    val tone: CardTone = CardTone.DEFAULT,
)

private data class ActionButton(
    val title: String,
    val note: String,
)

private data class FeedItem(
    val title: String,
    val subtitle: String,
    val trailing: String,
    val badge: String? = null,
)

private enum class CardTone { DEFAULT, PRIMARY, DANGER, SOFT }

@Composable
fun App() {
    val koin = GlobalContext.get()
    val tenantRepository = remember { koin.get<TenantRepository>() }
    val tenantContext = remember { koin.get<TenantContext>() }
    val configStore = remember { koin.get<ConfigStore>() }
    val sessionStore = remember { koin.get<SessionStore>() }

    val selectedSlug by tenantRepository.getSelectedTenantSlug().collectAsState(initial = null)
    val tenantConfig by configStore.config.collectAsState()
    val session by sessionStore.session.collectAsState()

    val scope = rememberCoroutineScope()
    val snackbar = remember { SnackbarHostState() }
    var screen by remember(session) { mutableStateOf(if (session != null) AppScreen.HOME else AppScreen.LOGIN) }

    LaunchedEffect(selectedSlug) {
        tenantContext.setTenantSlug(selectedSlug)
    }

    MaterialTheme {
        Scaffold(snackbarHost = { SnackbarHost(snackbar) }) { padding ->
            Column(
                modifier = Modifier
                    .padding(padding)
                    .safeContentPadding()
                    .fillMaxSize()
                    .padding(16.dp),
            ) {
                when (screen) {
                    AppScreen.LOGIN -> LoginScreen(
                        tenantName = tenantConfig?.name,
                        initialTenantSlug = selectedSlug,
                        onLogin = { slug, username, password ->
                            scope.launch {
                                if (!isValidTenantSlug(slug)) {
                                    snackbar.showSnackbar("Invalid company code / tenant slug.")
                                    return@launch
                                }

                                val previousSlug = selectedSlug
                                try {
                                    tenantRepository.refreshConfig(slug)
                                    tenantRepository.selectTenant(slug)
                                    if (!previousSlug.isNullOrBlank() && previousSlug != slug) {
                                        tenantRepository.clearTenantData(previousSlug)
                                    }
                                } catch (e: Throwable) {
                                    val cached = tenantRepository.getCachedConfigOnce(slug)
                                    if (cached != null) {
                                        tenantRepository.selectTenant(slug)
                                        snackbar.showSnackbar("Offline mode: using cached tenant config for '$slug'.")
                                    } else {
                                        snackbar.showSnackbar(e.message ?: "Unable to fetch tenant configuration.")
                                        return@launch
                                    }
                                }

                                try {
                                    tenantRepository.loginAndBootstrapSession(slug, username, password)
                                    screen = AppScreen.HOME
                                    snackbar.showSnackbar("Session loaded for $slug.")
                                } catch (e: Throwable) {
                                    snackbar.showSnackbar(e.message ?: "Login failed")
                                }
                            }
                        },
                    )

                    AppScreen.HOME -> HomeScreen(
                        tenantName = tenantConfig?.name ?: session?.login?.tenant?.name ?: "Operix",
                        tenantSlug = selectedSlug.orEmpty(),
                        session = session,
                        onLogout = {
                            scope.launch {
                                tenantRepository.logout()
                                screen = AppScreen.LOGIN
                            }
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun LoginScreen(
    tenantName: String?,
    initialTenantSlug: String?,
    onLogin: (String, String, String) -> Unit,
) {
    var tenantSlug by remember(initialTenantSlug) { mutableStateOf(initialTenantSlug.orEmpty()) }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Column(
        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)) {
            Column(modifier = Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Operix", style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Bold)
                Text("The Financial Architect", style = MaterialTheme.typography.titleMedium)
                Text("Tenant: ${tenantName ?: "Operix"}")
                Text("Sign in with company code, identity, and security key.")
            }
        }

        Card {
            Column(modifier = Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text("Access Portal", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                Text("This screen now follows the provided mockups: no separate tenant setup step.")
                OutlinedTextField(
                    value = tenantSlug,
                    onValueChange = { tenantSlug = it.trim().lowercase() },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Company Code") },
                    placeholder = { Text("e.g. global-corp") },
                )
                OutlinedTextField(
                    username,
                    { username = it },
                    label = { Text("Identity") },
                    placeholder = { Text("Email or phone number") },
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    password,
                    { password = it },
                    label = { Text("Security Key") },
                    modifier = Modifier.fillMaxWidth(),
                    visualTransformation = PasswordVisualTransformation(),
                )
                Button(onClick = { onLogin(tenantSlug, username, password) }, modifier = Modifier.fillMaxWidth()) {
                    Text("Access Portal")
                }
            }
        }
    }
}

@Composable
private fun HomeScreen(
    tenantName: String,
    tenantSlug: String,
    session: SessionBootstrap?,
    onLogout: () -> Unit,
) {
    val tabs = remember(session?.permissions) { availableTabsFor(session) }
    var selectedTab by rememberSaveable(tabs) { mutableStateOf(tabs.first()) }

    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        HomeTopBar(tenantName = tenantName, tenantSlug = tenantSlug, session = session)

        Column(
            modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            when (selectedTab) {
                HomeTab.DASHBOARD -> DashboardScreen()
                HomeTab.POS -> PosScreen(session)
                HomeTab.INVOICES -> InvoicesScreen(session)
                HomeTab.PRODUCTS -> ProductsScreen(session)
                HomeTab.MORE -> MoreScreen(session, onLogout)
            }
        }

        BottomTabBar(tabs = tabs, selectedTab = selectedTab, onSelected = { selectedTab = it })
    }
}

@Composable
private fun HomeTopBar(
    tenantName: String,
    tenantSlug: String,
    session: SessionBootstrap?,
) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(tenantName, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                Text("Tenant: $tenantSlug")
                Text("${session?.me?.name ?: "User"} • ${session?.me?.role ?: "Active session"}")
            }
            Text("🔔", style = MaterialTheme.typography.headlineMedium)
        }
    }
}

@Composable
private fun DashboardScreen() {
    val quickActions = listOf(
        ActionButton("New Sale", "Start POS checkout quickly."),
        ActionButton("Record Payment", "Capture invoice or client payment."),
        ActionButton("Add Expense", "Log mobile expense with account context."),
    )
    val products = listOf(
        FeedItem("Apple iPhone 15 Pro", "14 sold • Electronics", "$13,986.00"),
        FeedItem("Samsung Galaxy S24", "9 sold • Electronics", "$8,091.00"),
    )
    val timeline = listOf(
        FeedItem("Payment received from Sarah Jenkins", "24 minutes ago • Invoices", "Invoice #INV-2024-082 • $450.00"),
        FeedItem("New sale recorded by Mike R.", "1 hour ago • POS", "$124.50"),
        FeedItem("Stock updated: MacBook Air M3", "3 hours ago • Inventory", "5 low stock items"),
    )

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        StatsRow(
            StatCard("Today's Sales total", "$1,450.00", CardTone.PRIMARY),
            StatCard("Due invoices count", "8", CardTone.SOFT),
        )
        StatBanner("Critical", "5 Low stock items require immediate attention.", CardTone.DANGER)
        Section("Quick actions") {
            quickActions.forEach { action -> PrimaryActionCard(action, fullWidth = true) }
        }
        Section("Top selling products") {
            products.forEach { item -> FeedCard(item) }
        }
        Section("Recent activity") {
            timeline.forEach { item -> FeedCard(item) }
        }
    }
}

@Composable
private fun PosScreen(session: SessionBootstrap?) {
    val cart = listOf(
        FeedItem("Foundation / Blue", "Qty 1", "$25.00"),
        FeedItem("Accent / Silver", "Qty 1", "$15.00"),
        FeedItem("Apple Cream", "Qty 1", "$5.00"),
    )

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        SearchCard("Search products or scan barcode")
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Active Cart", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Text("${cart.size} items")
        }
        cart.forEach { item -> FeedCard(item) }
        Card(colors = toneColors(CardTone.SOFT)) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Payment Method", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("Cash", "Card", "Transfer").forEach { method ->
                        Button(onClick = {}, modifier = Modifier.width(110.dp)) { Text(method) }
                    }
                }
                Text("Drawer account: ${session?.me?.drawerAccount?.name ?: "Not assigned"}")
                Text("Total Amount", style = MaterialTheme.typography.titleMedium)
                Text("$45.00", style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Bold)
                Button(onClick = {}, modifier = Modifier.fillMaxWidth()) { Text("Complete Sale") }
            }
        }
    }
}

@Composable
private fun InvoicesScreen(session: SessionBootstrap?) {
    val invoices = listOf(
        FeedItem("Sarah Jenkins", "#INV-2024-082 • Sent Aug 24, 2024", "$450.00", "PAID"),
        FeedItem("Mike R.", "#INV-2024-083 • Sent Aug 22, 2024", "$125.00", "DUE"),
        FeedItem("Aura Minimalist", "#INV-2024-084 • 5 days overdue", "$980.00", "OVERDUE"),
    )
    val focusActions = listOf(
        ActionButton("Sales invoices", "Create, post, print, and record payment on sales invoices."),
        ActionButton("Purchase invoices", "Handle supplier purchases, returns, and payment posting."),
        ActionButton("Clients & Suppliers", "Review balances, collections, and payable follow-up."),
    )

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Invoices", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        SearchCard("Search by invoice # or client")
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("All", "Unpaid", "Paid", "Drafts").forEach { filter ->
                Button(onClick = {}) { Text(filter) }
            }
        }
        StatsRow(
            StatCard("Total Receivables", "$1,555.00", CardTone.PRIMARY),
            StatCard("Overdue", "$980.00", CardTone.DANGER),
        )
        Section("Recent Activity") {
            invoices.forEach { item -> FeedCard(item) }
        }
        Section("Start with these flows") {
            focusActions.forEach { action -> PrimaryActionCard(action, fullWidth = true) }
        }
        Text("Permissions loaded: ${session?.permissions?.size ?: 0}")
    }
}

@Composable
private fun ProductsScreen(session: SessionBootstrap?) {
    val products = listOf(
        FeedItem("QuantumBeat Pro", "84 in stock", "$299.00"),
        FeedItem("Aura Minimalist Watch", "3 remaining", "$185.50", "LOW"),
        FeedItem("Nexus Controller G5", "12 in stock", "$79.99"),
        FeedItem("Voyager Leather Bag", "24 in stock", "$340.00"),
        FeedItem("Dash Sneakers Neon", "Out of stock", "$120.00", "OUT"),
    )

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Products", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        SearchCard("Search products, SKUs, barcodes")
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("All Items", "Low Stock", "Electronics").forEach { filter ->
                Button(onClick = {}) { Text(filter) }
            }
        }
        products.forEach { item -> FeedCard(item) }
        PrimaryActionCard(
            ActionButton(
                "View Transactions",
                "Open product detail, barcode, pricing, reorder point, and movement history.",
            ),
            fullWidth = true,
        )
        Text("Inventory permission: ${hasPermission(session, "inventory.view")}")
    }
}

@Composable
private fun MoreScreen(
    session: SessionBootstrap?,
    onLogout: () -> Unit,
) {
    val recent = listOf(
        FeedItem("Sale #8492", "02:14 PM", "$124.50"),
        FeedItem("Cash Drop", "11:05 AM", "-$200.00"),
    )

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Shift Management", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        StatsRow(
            StatCard("Shift Status", "OPEN", CardTone.SOFT),
            StatCard("Live", "08:30 AM", CardTone.DEFAULT),
        )
        StatsRow(
            StatCard("Total Sales", "$1,450.00", CardTone.DEFAULT),
            StatCard("Total Orders", "42", CardTone.DEFAULT),
        )
        Section("Recent Activity") { recent.forEach { item -> FeedCard(item) } }
        Button(onClick = {}, modifier = Modifier.fillMaxWidth()) { Text("Close Shift") }
        Button(onClick = {}, modifier = Modifier.fillMaxWidth()) { Text("Print Shift Report") }
        Button(onClick = onLogout, modifier = Modifier.fillMaxWidth()) { Text("Logout") }
        Text("Reports access: ${hasPermission(session, "reports.view")}")
    }
}

@Composable
private fun BottomTabBar(
    tabs: List<HomeTab>,
    selectedTab: HomeTab,
    onSelected: (HomeTab) -> Unit,
) {
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)) {
        FlowRow(
            modifier = Modifier.fillMaxWidth().padding(8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            tabs.forEach { tab ->
                Button(onClick = { onSelected(tab) }) {
                    Text(if (tab == selectedTab) "• ${tab.title}" else tab.title)
                }
            }
        }
    }
}

@Composable
private fun SearchCard(placeholder: String) {
    Card(colors = toneColors(CardTone.SOFT)) {
        Text(
            placeholder,
            modifier = Modifier.fillMaxWidth().padding(18.dp),
            style = MaterialTheme.typography.titleMedium,
        )
    }
}

@Composable
private fun StatsRow(first: StatCard, second: StatCard) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        StatCardView(first)
        StatCardView(second)
    }
}

@Composable
private fun StatCardView(card: StatCard) {
    Card(colors = toneColors(card.tone)) {
        Column(modifier = Modifier.width(160.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(card.label, style = MaterialTheme.typography.titleMedium)
            Text(card.value, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun StatBanner(title: String, message: String, tone: CardTone) {
    Card(colors = toneColors(tone)) {
        Column(modifier = Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, fontWeight = FontWeight.Bold)
            Text(message)
        }
    }
}

@Composable
private fun Section(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        content()
    }
}

@Composable
private fun PrimaryActionCard(action: ActionButton, fullWidth: Boolean = false) {
    Card(colors = toneColors(CardTone.PRIMARY)) {
        Column(
            modifier = Modifier
                .then(if (fullWidth) Modifier.fillMaxWidth() else Modifier)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(action.title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(action.note)
        }
    }
}

@Composable
private fun FeedCard(item: FeedItem) {
    Card(colors = toneColors(CardTone.DEFAULT)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(item.title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                Text(item.subtitle)
                if (item.badge != null) Text(item.badge, color = MaterialTheme.colorScheme.primary)
            }
            Text(item.trailing, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun toneColors(tone: CardTone) = when (tone) {
    CardTone.DEFAULT -> CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    CardTone.PRIMARY -> CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
    CardTone.DANGER -> CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
    CardTone.SOFT -> CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
}

private fun availableTabsFor(session: SessionBootstrap?): List<HomeTab> {
    val permissions = session?.permissions.orEmpty().toSet()
    val tabs = HomeTab.entries.filter { tab ->
        tab.requiredPermissions.isEmpty() || tab.requiredPermissions.any { it in permissions }
    }
    return if (tabs.isEmpty()) listOf(HomeTab.MORE) else tabs
}

private fun hasPermission(session: SessionBootstrap?, permission: String): Boolean =
    permission in session?.permissions.orEmpty()
