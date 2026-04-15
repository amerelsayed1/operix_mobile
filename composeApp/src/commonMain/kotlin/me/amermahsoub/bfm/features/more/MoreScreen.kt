package me.amermahsoub.bfm.features.more

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.permission.IfPermitted
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.SecondaryButton
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import org.koin.core.context.GlobalContext

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
    val sessionStore = remember { GlobalContext.get().get<SessionStore>() }
    val session by sessionStore.session.collectAsState()
    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.tabMore)

        session?.me?.let { user ->
            UserHeaderCard(
                name = user.name,
                email = user.email,
                roleName = user.roleName,
                businessName = user.businessName ?: session?.login?.tenant?.name,
            )
            Spacer(Modifier.height(4.dp))
        }

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

@Composable
private fun UserHeaderCard(
    name: String,
    email: String?,
    roleName: String?,
    businessName: String?,
) {
    ElevatedCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            val initials = name.trim().split(" ")
                .mapNotNull { it.firstOrNull()?.toString() }
                .take(2)
                .joinToString("")
                .uppercase()
                .ifBlank { "?" }
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    initials,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimary,
                )
            }
            Spacer(Modifier.size(12.dp))
            Column(modifier = Modifier) {
                Text(name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                val subtitle = listOfNotNull(roleName, businessName).joinToString(" • ")
                if (subtitle.isNotBlank()) {
                    Text(
                        subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                    )
                }
                if (!email.isNullOrBlank()) {
                    Text(
                        email,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}
