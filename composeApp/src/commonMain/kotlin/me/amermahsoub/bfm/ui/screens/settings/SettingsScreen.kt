package me.amermahsoub.bfm.ui.screens.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.BookOpen
import compose.icons.feathericons.Briefcase
import compose.icons.feathericons.Calendar
import compose.icons.feathericons.ChevronRight
import compose.icons.feathericons.CreditCard
import compose.icons.feathericons.LogOut
import compose.icons.feathericons.Users
import me.amermahsoub.bfm.navigation.NavRoutes
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.ui.components.Divider
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.settings.SettingsViewModel
import org.koin.core.context.GlobalContext

private data class SettingsMenuItem(
    val label: String,
    val subtitle: String,
    val icon: ImageVector,
    val route: String,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigate: (String) -> Unit,
    onLogout: () -> Unit,
) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        SettingsViewModel(
            repository = koin.get<TenantRepository>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val session by viewModel.userSession.collectAsState()
    val user = session?.login?.user
    val tenant = session?.login?.tenant

    val menuItems = remember {
        listOf(
            SettingsMenuItem(
                label = "Users & Employees",
                subtitle = "Manage team members and roles",
                icon = FeatherIcons.Users,
                route = NavRoutes.Users.route,
            ),
            SettingsMenuItem(
                label = "Payment Methods",
                subtitle = "Configure payment options",
                icon = FeatherIcons.CreditCard,
                route = "settings/payment-methods",
            ),
            SettingsMenuItem(
                label = "Accounting Periods",
                subtitle = "Manage fiscal periods",
                icon = FeatherIcons.Calendar,
                route = "settings/accounting-periods",
            ),
            SettingsMenuItem(
                label = "GL Accounts",
                subtitle = "Chart of accounts",
                icon = FeatherIcons.BookOpen,
                route = NavRoutes.Accounts.route,
            ),
            SettingsMenuItem(
                label = "Branches",
                subtitle = "Manage business locations",
                icon = FeatherIcons.Briefcase,
                route = "settings/branches",
            ),
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Settings",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White,
                ),
            )
        },
        containerColor = OperixSurface,
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState()),
        ) {
            Spacer(Modifier.height(16.dp))

            // User info card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                shape = RoundedCornerShape(16.dp),
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    // Avatar
                    val initial = user?.name?.firstOrNull()?.uppercase() ?: "U"
                    Box(
                        modifier = Modifier
                            .size(52.dp)
                            .clip(CircleShape)
                            .background(OperixPrimary),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = initial,
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            fontSize = 22.sp,
                        )
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = user?.name ?: "User",
                            fontWeight = FontWeight.SemiBold,
                            style = MaterialTheme.typography.bodyLarge,
                        )
                        val userEmail = user?.email
                        if (userEmail != null) {
                            Text(
                                text = userEmail,
                                color = OperixTextSecondary,
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                        val userRole = user?.role
                        if (userRole != null) {
                            Spacer(Modifier.height(4.dp))
                            Box(
                                modifier = Modifier
                                    .background(
                                        color = Color(0xFFDBEAFE),
                                        shape = RoundedCornerShape(20.dp),
                                    )
                                    .padding(horizontal = 8.dp, vertical = 2.dp),
                            ) {
                                Text(
                                    text = userRole,
                                    color = OperixPrimary,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Medium,
                                )
                            }
                        }
                    }
                }
                if (tenant != null) {
                    Divider(modifier = Modifier.padding(horizontal = 20.dp))
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Text(
                            text = "Company",
                            color = OperixTextSecondary,
                            style = MaterialTheme.typography.bodySmall,
                        )
                        Text(
                            text = tenant.name ?: tenant.slug,
                            fontWeight = FontWeight.Medium,
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                }
            }

            Spacer(Modifier.height(24.dp))

            // Menu section
            Text(
                text = "CONFIGURATION",
                color = OperixTextSecondary,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 1.sp,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
            )
            Spacer(Modifier.height(4.dp))

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                shape = RoundedCornerShape(16.dp),
            ) {
                menuItems.forEachIndexed { index, item ->
                    SettingsMenuRow(
                        item = item,
                        onClick = { onNavigate(item.route) },
                    )
                    if (index < menuItems.lastIndex) {
                        Divider(modifier = Modifier.padding(horizontal = 16.dp))
                    }
                }
            }

            Spacer(Modifier.height(32.dp))

            // Logout button
            Button(
                onClick = { viewModel.logout(onLoggedOut = onLogout) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .height(52.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFFFEE2E2),
                    contentColor = OperixError,
                ),
                shape = RoundedCornerShape(12.dp),
            ) {
                Icon(
                    imageVector = FeatherIcons.LogOut,
                    contentDescription = "Logout",
                    modifier = Modifier.size(18.dp),
                )
                Spacer(Modifier.width(8.dp))
                Text(
                    text = "Logout",
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp,
                )
            }

            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun SettingsMenuRow(
    item: SettingsMenuItem,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .background(Color(0xFFF1F5F9), shape = RoundedCornerShape(10.dp)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = item.icon,
                    contentDescription = item.label,
                    tint = OperixPrimary,
                    modifier = Modifier.size(18.dp),
                )
            }
            Column {
                Text(
                    text = item.label,
                    fontWeight = FontWeight.Medium,
                    style = MaterialTheme.typography.bodyMedium,
                )
                Text(
                    text = item.subtitle,
                    color = OperixTextSecondary,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
        Icon(
            imageVector = FeatherIcons.ChevronRight,
            contentDescription = null,
            tint = OperixTextSecondary,
            modifier = Modifier.size(16.dp),
        )
        Spacer(Modifier.width(16.dp))
    }
}
