package me.amermahsoub.bfm.features.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.permission.LocalPermissionGuard
import me.amermahsoub.bfm.app.ui.BadgeChip
import me.amermahsoub.bfm.app.ui.BadgeTone
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ModuleCard
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.StatCard
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.dashboard.DashboardRepository
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import org.koin.core.context.GlobalContext

@Composable
fun DashboardScreen(
    onStartSale: () -> Unit = {},
    onRecordPayment: () -> Unit = {},
    onAddExpense: () -> Unit = {},
    onOrderClicked: (Long) -> Unit = {},
    onClients: () -> Unit = {},
    onProducts: () -> Unit = {},
    onInventory: () -> Unit = {},
    onAccounts: () -> Unit = {},
    onExpenses: () -> Unit = {},
    onReports: () -> Unit = {},
    onInvoices: () -> Unit = {},
    onSuppliers: () -> Unit = {},
    onNotifications: () -> Unit = {},
) {
    val repo = remember { GlobalContext.get().get<DashboardRepository>() }
    val sessionStore = remember { GlobalContext.get().get<SessionStore>() }
    val vm = rememberFeatureViewModel { DashboardViewModel(repo) }
    val state by vm.state.collectAsState()
    val session by sessionStore.session.collectAsState()
    val strings = appStrings()

    when {
        state.loading && state.data == null -> LoadingState()
        state.error != null && state.data == null -> ErrorState(state.error!!, onRetry = vm::refresh)
        else -> {
            val data = state.data
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                GreetingHero(
                    welcome = strings.welcomeBack,
                    name = session?.me?.name?.firstName(),
                    subtitle = session?.me?.businessName
                        ?: session?.login?.tenant?.name
                        ?: strings.dashboardTitle,
                )

                // ── Module grid (competitor-style 2×3 launcher cards) ──
                ModuleGrid(
                    strings = strings,
                    onStartSale = onStartSale,
                    onClients = onClients,
                    onProducts = onProducts,
                    onExpenses = onExpenses,
                    onAccounts = onAccounts,
                    onInventory = onInventory,
                    onReports = onReports,
                    onInvoices = onInvoices,
                    onSuppliers = onSuppliers,
                    onNotifications = onNotifications,
                )

                // ── KPI summary ──
                val summary = data?.summary
                if (summary != null) {
                    SectionTitle(strings.dashboardTitle)
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(
                                label = strings.totalSales,
                                value = summary.totalRevenue ?: "—",
                            )
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(
                                label = strings.totalExpenses,
                                value = summary.totalExpenses ?: "—",
                                accent = MaterialTheme.colorScheme.error,
                            )
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(
                                label = strings.netProfit,
                                value = summary.netProfit ?: "—",
                                accent = MaterialTheme.colorScheme.tertiary,
                            )
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(
                                label = strings.totalBalance,
                                value = summary.totalBalance ?: "—",
                            )
                        }
                    }
                }

                // ── Low stock ──
                val lowStock = data?.lowStock.orEmpty()
                if (lowStock.isNotEmpty()) {
                    SectionTitle(strings.lowStockItems)
                    lowStock.take(5).forEach { item ->
                        ListRow(
                            title = item.name,
                            subtitle = item.sku?.let { "${strings.sku}: $it" },
                            trailing = item.availableQty?.let { "${it.format1()}" } ?: "—",
                            badge = strings.lowStock,
                            badgeTone = BadgeTone.WARNING,
                        )
                    }
                }

                // ── Recent orders ──
                val recent = data?.recentOrders.orEmpty()
                if (recent.isNotEmpty()) {
                    SectionTitle(strings.recentOrders)
                    recent.take(5).forEach { order ->
                        val status = order.status?.takeIf { it.isNotBlank() }
                        ListRow(
                            title = "${strings.receiptNumber}${order.displayNumber}",
                            subtitle = order.customer ?: order.createdAt,
                            trailing = order.total ?: "",
                            badge = status,
                            badgeTone = status?.let { statusToneFor(it) } ?: BadgeTone.NEUTRAL,
                            onClick = order.id?.let { id -> { onOrderClicked(id) } },
                        )
                    }
                }

                // ── Top selling ──
                val top = data?.topProducts.orEmpty()
                if (top.isNotEmpty()) {
                    SectionTitle(strings.topSelling)
                    top.take(5).forEach { product ->
                        ListRow(
                            title = product.name,
                            subtitle = product.category,
                            trailing = product.revenue ?: product.unitsSold?.toString() ?: "",
                        )
                    }
                }

                // ── Empty fallback ──
                if (lowStock.isEmpty() && recent.isEmpty() && top.isEmpty() && summary == null) {
                    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                        Column(modifier = Modifier.padding(24.dp)) {
                            Text(strings.empty, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                            Spacer(Modifier.height(8.dp))
                            Text(
                                strings.loginSubtitle,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                }

                // ── Inline error ──
                if (state.error != null) {
                    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                        Row(
                            modifier = Modifier.padding(16.dp).fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(state.error!!.message, color = MaterialTheme.colorScheme.error)
                            BadgeChip(strings.retry)
                        }
                    }
                }
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────────────────
//  Private composables & helpers
// ──────────────────────────────────────────────────────────────────────────

private fun Double.format1(): String {
    val rounded = (this * 10).toLong() / 10.0
    return if (rounded == rounded.toLong().toDouble()) rounded.toLong().toString() else rounded.toString()
}

private fun String.firstName(): String =
    trim().split(" ").firstOrNull()?.takeIf { it.isNotBlank() } ?: this

@Composable
private fun GreetingHero(welcome: String, name: String?, subtitle: String) {
    val primary = MaterialTheme.colorScheme.primary
    val onPrimary = MaterialTheme.colorScheme.onPrimary
    val gradient = Brush.linearGradient(
        colors = listOf(primary, primary.copy(alpha = 0.80f)),
    )
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(gradient)
            .padding(horizontal = 20.dp, vertical = 20.dp),
    ) {
        Column {
            Text(
                text = if (name.isNullOrBlank()) "$welcome \uD83D\uDC4B" else "$welcome, $name \uD83D\uDC4B",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = onPrimary,
            )
            Spacer(Modifier.height(2.dp))
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = onPrimary.copy(alpha = 0.85f),
            )
        }
    }
}

private data class Module(
    val emoji: String,
    val label: String,
    val onClick: () -> Unit,
    val accent: Color,
)

/**
 * 2×3 grid of large icon cards matching the competitor screenshot — each
 * card has a large tinted circle with an emoji and a bold label below.
 */
@Composable
private fun ModuleGrid(
    strings: me.amermahsoub.bfm.app.i18n.AppStrings,
    onStartSale: () -> Unit,
    onClients: () -> Unit,
    onProducts: () -> Unit,
    onExpenses: () -> Unit,
    onAccounts: () -> Unit,
    onInventory: () -> Unit,
    onReports: () -> Unit,
    onInvoices: () -> Unit,
    onSuppliers: () -> Unit,
    onNotifications: () -> Unit,
) {
    val guard = LocalPermissionGuard.current
    val modules = mutableListOf<Module>()

    if (guard.hasAny("pos.view", "pos.create", "sales.create")) {
        modules += Module(
            emoji = "\uD83D\uDED2", // 🛒
            label = strings.posTitle,
            onClick = onStartSale,
            accent = Color(0xFFE91E63),
        )
    }
    if (guard.hasAny("clients.view")) {
        modules += Module(
            emoji = "\uD83D\uDC65", // 👥
            label = strings.clientsTitle,
            onClick = onClients,
            accent = Color(0xFF2196F3),
        )
    }
    if (guard.hasAny("products.view", "inventory.view")) {
        modules += Module(
            emoji = "\uD83D\uDCE6", // 📦
            label = strings.productsTitle,
            onClick = onProducts,
            accent = Color(0xFFFF9800),
        )
    }
    if (guard.hasAny("expenses.view", "expenses.create")) {
        modules += Module(
            emoji = "\uD83D\uDCB0", // 💰
            label = strings.expensesTitle,
            onClick = onExpenses,
            accent = Color(0xFF9C27B0),
        )
    }
    if (guard.hasAny("accounts.view")) {
        modules += Module(
            emoji = "\uD83C\uDFE6", // 🏦
            label = strings.accountsTitle,
            onClick = onAccounts,
            accent = Color(0xFF4CAF50),
        )
    }
    if (guard.hasAny("inventory.view")) {
        modules += Module(
            emoji = "\uD83D\uDDC4\uFE0F", // 🗄️
            label = strings.inventoryTitle,
            onClick = onInventory,
            accent = Color(0xFF00BCD4),
        )
    }
    if (guard.hasAny("reports.view", "dashboard.view")) {
        modules += Module(
            emoji = "\uD83D\uDCCA", // 📊
            label = strings.reportsTitle,
            onClick = onReports,
            accent = Color(0xFF3F51B5),
        )
    }
    if (guard.hasAny("invoices.view", "pos.view")) {
        modules += Module(
            emoji = "\uD83E\uDDFE", // 🧾
            label = strings.invoicesTitle,
            onClick = onInvoices,
            accent = Color(0xFF607D8B),
        )
    }
    if (guard.hasAny("suppliers.view")) {
        modules += Module(
            emoji = "\uD83D\uDE9A", // 🚚
            label = strings.suppliersTitle,
            onClick = onSuppliers,
            accent = Color(0xFF795548),
        )
    }
    modules += Module(
        emoji = "\uD83D\uDD14", // 🔔
        label = strings.notificationsTitle,
        onClick = onNotifications,
        accent = Color(0xFFFF5722),
    )

    // Always show at least POS + Clients as defaults if nothing is gated.
    if (modules.isEmpty()) {
        modules += Module("\uD83D\uDED2", strings.posTitle, onStartSale, Color(0xFFE91E63))
        modules += Module("\uD83D\uDC65", strings.clientsTitle, onClients, Color(0xFF2196F3))
    }

    modules.chunked(2).forEach { pair ->
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(modifier = Modifier.weight(1f)) {
                val m = pair[0]
                ModuleCard(emoji = m.emoji, label = m.label, onClick = m.onClick, accent = m.accent)
            }
            Box(modifier = Modifier.weight(1f)) {
                if (pair.size > 1) {
                    val m = pair[1]
                    ModuleCard(emoji = m.emoji, label = m.label, onClick = m.onClick, accent = m.accent)
                } else {
                    Spacer(Modifier.fillMaxWidth())
                }
            }
        }
    }
}

private fun statusToneFor(status: String): BadgeTone {
    val s = status.lowercase()
    return when {
        s.contains("paid") || s.contains("completed") || s.contains("closed") || s.contains("success") ->
            BadgeTone.SUCCESS
        s.contains("pending") || s.contains("partial") || s.contains("open") || s.contains("draft") ->
            BadgeTone.WARNING
        s.contains("refund") || s.contains("cancel") || s.contains("fail") || s.contains("void") ->
            BadgeTone.ERROR
        else -> BadgeTone.NEUTRAL
    }
}
