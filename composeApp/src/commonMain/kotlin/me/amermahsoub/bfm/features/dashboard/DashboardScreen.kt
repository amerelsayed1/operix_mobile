package me.amermahsoub.bfm.features.dashboard

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.permission.IfPermitted
import me.amermahsoub.bfm.app.ui.BadgeChip
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.StatCard
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.dashboard.DashboardRepository
import org.koin.core.context.GlobalContext

@Composable
fun DashboardScreen(
    onStartSale: () -> Unit = {},
    onRecordPayment: () -> Unit = {},
    onAddExpense: () -> Unit = {},
    onOrderClicked: (Long) -> Unit = {},
) {
    val repo = remember { GlobalContext.get().get<DashboardRepository>() }
    val vm = rememberFeatureViewModel { DashboardViewModel(repo) }
    val state by vm.state.collectAsState()
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
                ScreenTitle(strings.dashboardTitle)

                val summary = data?.summary
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Column(modifier = Modifier.weight(1f)) {
                        StatCard(
                            label = strings.totalSales,
                            value = summary?.totalRevenue ?: "—",
                        )
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        StatCard(
                            label = strings.totalExpenses,
                            value = summary?.totalExpenses ?: "—",
                            accent = MaterialTheme.colorScheme.error,
                        )
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Column(modifier = Modifier.weight(1f)) {
                        StatCard(
                            label = strings.netProfit,
                            value = summary?.netProfit ?: "—",
                            accent = MaterialTheme.colorScheme.tertiary,
                        )
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        StatCard(
                            label = strings.totalBalance,
                            value = summary?.totalBalance ?: "—",
                        )
                    }
                }

                SectionTitle(strings.quickActions)
                IfPermitted("pos.create", "sales.create") {
                    PrimaryButton(text = strings.startSale, onClick = onStartSale)
                }
                IfPermitted("clients.payments", "sales.pay") {
                    PrimaryButton(text = strings.recordPayment, onClick = onRecordPayment)
                }
                IfPermitted("expenses.create") {
                    PrimaryButton(text = strings.addExpense, onClick = onAddExpense)
                }

                val lowStock = data?.lowStock.orEmpty()
                if (lowStock.isNotEmpty()) {
                    SectionTitle(strings.lowStockItems)
                    lowStock.take(5).forEach { item ->
                        ListRow(
                            title = item.name,
                            subtitle = item.sku?.let { "${strings.sku}: $it" },
                            trailing = item.availableQty?.let { "${it.format1()}" } ?: "—",
                            badge = strings.lowStock,
                        )
                    }
                }

                val recent = data?.recentOrders.orEmpty()
                if (recent.isNotEmpty()) {
                    SectionTitle(strings.recentOrders)
                    recent.take(5).forEach { order ->
                        ListRow(
                            title = "${strings.receiptNumber}${order.displayNumber}",
                            subtitle = order.customer ?: order.createdAt,
                            trailing = order.total ?: "",
                            badge = order.status,
                            onClick = order.id?.let { id -> { onOrderClicked(id) } },
                        )
                    }
                }

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

private fun Double.format1(): String {
    val rounded = (this * 10).toLong() / 10.0
    return if (rounded == rounded.toLong().toDouble()) rounded.toLong().toString() else rounded.toString()
}
