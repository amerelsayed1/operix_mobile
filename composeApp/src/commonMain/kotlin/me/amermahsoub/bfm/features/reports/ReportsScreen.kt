package me.amermahsoub.bfm.features.reports

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilterChip
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.StatCard
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.reports.ExpenseCategoryBreakdown
import me.amermahsoub.bfm.shared.data.reports.ReportsRepository
import org.koin.core.context.GlobalContext

@Composable
fun ReportsScreen() {
    val repo = remember { GlobalContext.get().get<ReportsRepository>() }
    val vm = rememberFeatureViewModel { ReportsViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading && state.sales == null -> LoadingState()
        state.error != null && state.sales == null -> ErrorState(state.error!!, onRetry = vm::refresh)
        else -> {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                ScreenTitle(strings.reportsTitle)

                // Period filter
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    ReportPeriod.entries.forEach { period ->
                        FilterChip(
                            selected = state.period == period,
                            onClick = { vm.selectPeriod(period) },
                            label = { Text(periodLabel(period, strings)) },
                        )
                    }
                }

                // Sales KPIs
                state.sales?.let { sales ->
                    SectionTitle(strings.salesReport)
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(strings.totalSales, sales.totalSales ?: "0.00")
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(strings.totalOrders, sales.totalOrders.toString())
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(strings.averageOrder, sales.averageOrder ?: "0.00")
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(strings.netSales, sales.netSales ?: "0.00", accent = Color(0xFF16A34A))
                        }
                    }
                }

                // Profit summary
                state.profit?.let { profit ->
                    SectionTitle(strings.profitReport)
                    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            ReportRow(strings.totalSales, profit.totalRevenue ?: "0.00")
                            ReportRow(strings.totalExpenses, profit.totalExpenses ?: "0.00", valueColor = MaterialTheme.colorScheme.error)
                            Spacer(Modifier.height(4.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                            ) {
                                Text(strings.netProfit, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                                Text(
                                    profit.netProfit ?: "0.00",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF16A34A),
                                )
                            }
                            profit.profitMargin?.let { margin ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                ) {
                                    Text(strings.profitMargin, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Text("${String.format("%.1f", margin)}%", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.SemiBold)
                                }
                            }
                        }
                    }
                }

                // Expense breakdown
                state.expenses?.let { expenses ->
                    SectionTitle(strings.expenseReport)
                    StatCard(strings.totalExpenses, expenses.totalExpenses ?: "0.00", accent = MaterialTheme.colorScheme.error)
                    if (expenses.byCategory.isNotEmpty()) {
                        ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                expenses.byCategory.forEach { cat ->
                                    CategoryBar(cat)
                                }
                            }
                        }
                    }
                }

                // Client stats
                state.clients?.let { clients ->
                    SectionTitle(strings.clientReport)
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(strings.clientsTitle, clients.totalClients.toString(), accent = Color(0xFF2196F3))
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(strings.newClients, clients.newClients.toString(), accent = Color(0xFF16A34A))
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(strings.totalReceivables, clients.totalReceivables ?: "0.00", accent = MaterialTheme.colorScheme.error)
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            StatCard(strings.totalCollected, clients.totalCollected ?: "0.00", accent = Color(0xFF16A34A))
                        }
                    }
                }

                // Top products
                if (state.topProducts.isNotEmpty()) {
                    SectionTitle(strings.topSelling)
                    state.topProducts.forEachIndexed { i, product ->
                        ListRow(
                            title = "${i + 1}. ${product.name}",
                            subtitle = product.category,
                            trailing = product.revenue ?: "${product.unitsSold}",
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ReportRow(label: String, value: String, valueColor: Color = MaterialTheme.colorScheme.onSurface) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = valueColor)
    }
}

@Composable
private fun CategoryBar(cat: ExpenseCategoryBreakdown) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(cat.category, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
            Text(cat.total ?: "0.00", style = MaterialTheme.typography.bodyMedium)
        }
        Spacer(Modifier.height(4.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(fraction = (cat.percentage / 100.0).toFloat().coerceIn(0f, 1f))
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(MaterialTheme.colorScheme.primary),
            )
        }
        Text(
            "${String.format("%.1f", cat.percentage)}%",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private fun periodLabel(period: ReportPeriod, strings: me.amermahsoub.bfm.app.i18n.AppStrings): String = when (period) {
    ReportPeriod.TODAY -> strings.today
    ReportPeriod.WEEK -> strings.thisWeek
    ReportPeriod.MONTH -> strings.thisMonth
    ReportPeriod.YEAR -> strings.thisYear
}
