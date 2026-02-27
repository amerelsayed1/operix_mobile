package me.amermahsoub.bfm

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.TextButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.tenant.ConfigStore
import me.amermahsoub.bfm.shared.data.tenant.TenantApiService
import me.amermahsoub.bfm.shared.data.tenant.TenantContext
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.shared.printing.TestReceiptFactory
import org.koin.core.context.GlobalContext

private enum class AppScreen { TENANT_SLUG, LOGIN, POS }

@Composable
fun App() {
    val koin = GlobalContext.get()
    val tenantRepository = remember { koin.get<TenantRepository>() }
    val tenantContext = remember { koin.get<TenantContext>() }
    val configStore = remember { koin.get<ConfigStore>() }
    val apiService = remember { koin.get<TenantApiService>() }

    val selectedSlug by tenantRepository.getSelectedTenantSlug().collectAsState(initial = null)
    val tenantConfig by configStore.config.collectAsState()

    val scope = rememberCoroutineScope()
    val snackbar = remember { SnackbarHostState() }
    val tenantSlugStateHolder = remember { TenantSlugStateHolder(tenantRepository, tenantContext, scope) }
    val tenantSlugUiState by tenantSlugStateHolder.state.collectAsState()
    var screen by remember(selectedSlug, tenantConfig) {
        mutableStateOf(
            if (!selectedSlug.isNullOrBlank() && tenantConfig != null) AppScreen.LOGIN else AppScreen.TENANT_SLUG
        )
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
                    AppScreen.TENANT_SLUG -> TenantSlugScreen(
                        state = tenantSlugUiState,
                        onSlugChange = tenantSlugStateHolder::onSlugChange,
                        onContinue = {
                            tenantSlugStateHolder.loadTenantAndContinue {
                                screen = AppScreen.LOGIN
                            }
                        },
                    )

                    AppScreen.LOGIN -> LoginScreen(
                        tenantName = tenantConfig?.name,
                        tenantSlug = selectedSlug,
                        currency = tenantConfig?.currency,
                        enabled = !selectedSlug.isNullOrBlank() && tenantConfig != null,
                        onChangeTenant = {
                            tenantSlugStateHolder.resetTenant {
                                screen = AppScreen.TENANT_SLUG
                            }
                        },
                        onLogin = { username, password ->
                            scope.launch {
                                if (tenantConfig == null) {
                                    snackbar.showSnackbar("Tenant config unavailable. Connect tenant first.")
                                    return@launch
                                }
                                try {
                                    apiService.login(username, password)
                                    screen = AppScreen.POS
                                } catch (e: Throwable) {
                                    snackbar.showSnackbar(e.message ?: "Login failed")
                                }
                            }
                        },
                    )

                    AppScreen.POS -> PosScreen(
                        currency = tenantConfig?.currency ?: "",
                        taxIncluded = tenantConfig?.pos?.taxIncluded ?: false,
                        receiptCharsPerLine = tenantConfig?.pos?.receiptCharsPerLine ?: 42,
                        onSwitchTenant = {
                            tenantSlugStateHolder.resetTenant {
                                screen = AppScreen.TENANT_SLUG
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
    tenantSlug: String?,
    currency: String?,
    enabled: Boolean,
    onChangeTenant: () -> Unit,
    onLogin: (String, String) -> Unit,
) {
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(Color(0xFF5B7BE8), Color(0xFF6B3FB3)),
                ),
            ),
        contentAlignment = Alignment.Center,
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .widthIn(max = 420.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFFF5F7FB)),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        brush = Brush.linearGradient(
                            colors = listOf(Color(0xFF5B7BE8), Color(0xFF6B3FB3)),
                        ),
                    )
                    .padding(vertical = 24.dp),
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = tenantName ?: "X Soft",
                        color = Color.White,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                    )
                    Spacer(Modifier.height(6.dp))
                    Text(
                        text = tenantSlug ?: "x-soft",
                        color = Color(0xFFDCE6FF),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }

            Column(
                modifier = Modifier.padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text("Login", style = MaterialTheme.typography.headlineSmall, modifier = Modifier.align(Alignment.CenterHorizontally))
                OutlinedTextField(
                    value = username,
                    onValueChange = { username = it },
                    label = { Text("Email Address") },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = enabled,
                    singleLine = true,
                )
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Password") },
                    modifier = Modifier.fillMaxWidth(),
                    visualTransformation = PasswordVisualTransformation(),
                    enabled = enabled,
                    singleLine = true,
                )
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    TextButton(onClick = onChangeTenant) { Text("Change organization") }
                    TextButton(onClick = {}, enabled = false) { Text("Remember me") }
                }
                Button(onClick = { onLogin(username, password) }, enabled = enabled, modifier = Modifier.fillMaxWidth()) {
                    Text("Login")
                }
                if (!enabled) {
                    Text("Login is disabled until tenant config is available.")
                }
            }
        }
    }
}

@Composable
private fun PosScreen(
    currency: String,
    taxIncluded: Boolean,
    receiptCharsPerLine: Int,
    onSwitchTenant: () -> Unit,
) {
    val sampleTotalCents = TestReceiptFactory.create().totalCents
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("POS", style = MaterialTheme.typography.headlineSmall)
        Text("Total preview: $currency ${sampleTotalCents / 100}.${(sampleTotalCents % 100).toString().padStart(2, '0')}")
        Text("Tax included: $taxIncluded")
        Text("Receipt width: $receiptCharsPerLine chars/line")
        Button(onClick = onSwitchTenant) { Text("Switch Tenant") }
    }
}
