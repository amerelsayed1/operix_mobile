package me.amermahsoub.bfm.features.more

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.permission.IfPermitted
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.SecondaryButton

@Composable
fun MoreScreen(
    onInventories: () -> Unit,
    onExpenses: () -> Unit,
    onAccounts: () -> Unit,
    onShiftHistory: () -> Unit,
    onCashMovement: () -> Unit,
    onProfile: () -> Unit,
    onSettings: () -> Unit,
    onLogout: () -> Unit,
) {
    val strings = appStrings()
    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.tabMore)

        SectionTitle(strings.posTitle)
        IfPermitted("pos.shifts.view", "pos.view") {
            ListRow(title = strings.shiftSummary, subtitle = null, onClick = onShiftHistory)
        }
        IfPermitted("pos.cash_movements.create") {
            ListRow(title = "${strings.cashIn} / ${strings.cashOut}", subtitle = null, onClick = onCashMovement)
        }

        SectionTitle(strings.inventoryTitle)
        IfPermitted("inventory.view") {
            ListRow(title = strings.inventoryTitle, subtitle = null, onClick = onInventories)
        }

        SectionTitle(strings.accountsTitle)
        IfPermitted("accounts.view") {
            ListRow(title = strings.accountsTitle, subtitle = null, onClick = onAccounts)
        }
        IfPermitted("expenses.view", "expenses.create") {
            ListRow(title = strings.expensesTitle, subtitle = null, onClick = onExpenses)
        }

        SectionTitle(strings.profileTitle)
        ListRow(title = strings.profileTitle, subtitle = null, onClick = onProfile)
        ListRow(title = "Settings", subtitle = null, onClick = onSettings)

        SecondaryButton(strings.logout, onClick = onLogout)
    }
}
