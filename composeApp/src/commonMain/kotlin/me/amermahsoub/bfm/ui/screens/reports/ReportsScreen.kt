package me.amermahsoub.bfm.ui.screens.reports

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import compose.icons.FeatherIcons
import compose.icons.feathericons.ArrowLeft
import compose.icons.feathericons.BarChart2
import compose.icons.feathericons.BookOpen
import compose.icons.feathericons.CreditCard
import compose.icons.feathericons.List
import compose.icons.feathericons.Package
import compose.icons.feathericons.TrendingUp
import me.amermahsoub.bfm.navigation.NavRoutes
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.components.ListItem
import me.amermahsoub.bfm.ui.theme.OperixSurface

data class ReportMenuItem(
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val route: String,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReportsScreen(onNavigate: (String) -> Unit) {
    val items = listOf(
        ReportMenuItem(
            title = "Profit & Loss",
            subtitle = "Revenue, COGS and net profit overview",
            icon = FeatherIcons.TrendingUp,
            route = NavRoutes.ProfitLoss.route,
        ),
        ReportMenuItem(
            title = "Trial Balance",
            subtitle = "Debit and credit totals per account",
            icon = FeatherIcons.BarChart2,
            route = NavRoutes.TrialBalance.route,
        ),
        ReportMenuItem(
            title = "Account Statement",
            subtitle = "Transaction history for a specific account",
            icon = FeatherIcons.BookOpen,
            route = NavRoutes.AccountStatement.route,
        ),
        ReportMenuItem(
            title = "Inventory Valuation",
            subtitle = "Current stock value by product",
            icon = FeatherIcons.Package,
            route = "reports/inventory-valuation",
        ),
        ReportMenuItem(
            title = "Receivables",
            subtitle = "Outstanding amounts owed by clients",
            icon = FeatherIcons.CreditCard,
            route = "reports/receivables",
        ),
        ReportMenuItem(
            title = "Payables",
            subtitle = "Outstanding amounts owed to suppliers",
            icon = FeatherIcons.List,
            route = "reports/payables",
        ),
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Reports", fontWeight = FontWeight.SemiBold) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                ),
            )
        },
        containerColor = OperixSurface,
    ) { padding ->
        LazyColumn(Modifier.fillMaxSize().padding(padding)) {
            items(items) { item ->
                ListItem(
                    title = item.title,
                    subtitle = item.subtitle,
                    trailing = {
                        Icon(
                            imageVector = item.icon,
                            contentDescription = null,
                            modifier = Modifier.size(22.dp),
                        )
                    },
                    onClick = { onNavigate(item.route) },
                )
                Divider()
            }
        }
    }
}
