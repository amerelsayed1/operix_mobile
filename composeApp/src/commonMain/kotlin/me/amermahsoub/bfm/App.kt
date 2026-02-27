package me.amermahsoub.bfm

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.shared.data.tenant.ConfigStore
import me.amermahsoub.bfm.shared.data.tenant.TenantApiService
import me.amermahsoub.bfm.shared.data.tenant.TenantContext
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.shared.data.tenant.isValidTenantSlug
import me.amermahsoub.bfm.shared.printing.TestReceiptFactory
import org.koin.core.context.GlobalContext

private enum class AppScreen { TENANT_SETUP, LOGIN, POS }

@Composable
fun App() {
    val koin = GlobalContext.get().koin
    val tenantRepository = remember { koin.get<TenantRepository>() }
    val tenantContext = remember { koin.get<TenantContext>() }
    val configStore = remember { koin.get<ConfigStore>() }
    val apiService = remember { koin.get<TenantApiService>() }

    val selectedSlug by tenantRepository.getSelectedTenantSlug().collectAsState(initial = null)
    val tenantConfig by configStore.config.collectAsState()

    val scope = rememberCoroutineScope()
    val snackbar = remember { SnackbarHostState() }
    var screen by remember(selectedSlug) {
        mutableStateOf(if (selectedSlug.isNullOrBlank()) AppScreen.TENANT_SETUP else AppScreen.LOGIN)
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
                    AppScreen.TENANT_SETUP -> TenantSetupScreen(
                        initialBaseUrl = tenantContext.baseUrl.value,
                        onConnect = { slug, baseUrl ->
                            scope.launch {
                                if (!baseUrl.startsWith("http://") && !baseUrl.startsWith("https://")) {
                                    snackbar.showSnackbar("Base URL must start with http:// or https://")
                                    return@launch
                                }
                                val normalizedBaseUrl = normalizeBaseUrlForPlatform(baseUrl)
                                if (normalizedBaseUrl != baseUrl.trim().trimEnd('/')) {
                                    snackbar.showSnackbar("Using Android emulator loopback mapping: $normalizedBaseUrl")
                                }
                                tenantContext.setBaseUrl(normalizedBaseUrl)
                                if (!isValidTenantSlug(slug)) {
                                    snackbar.showSnackbar("Invalid slug format. Use lowercase letters, numbers and dashes (3-50 chars).")
                                    return@launch
                                }
                                val previousSlug = selectedSlug
                                try {
                                    tenantRepository.refreshConfig(slug)
                                    tenantRepository.selectTenant(slug)
                                    tenantContext.setTenantSlug(slug)
                                    if (!previousSlug.isNullOrBlank() && previousSlug != slug) {
                                        tenantRepository.clearTenantData(previousSlug)
                                    }
                                    screen = AppScreen.LOGIN
                                    snackbar.showSnackbar("Connected to tenant '$slug'.")
                                } catch (e: Throwable) {
                                    val cached = tenantRepository.getCachedConfigOnce(slug)
                                    if (cached != null) {
                                        tenantRepository.selectTenant(slug)
                                        tenantContext.setTenantSlug(slug)
                                        screen = AppScreen.LOGIN
                                        snackbar.showSnackbar("Offline mode: using cached tenant config for '$slug'.")
                                    } else {
                                        val reason = e.message ?: "Unknown error"
                                        snackbar.showSnackbar("Unable to fetch tenant config for '$slug'. $reason")
                                    }
                                }
                            }
                        },
                    )

                    AppScreen.LOGIN -> LoginScreen(
                        tenantName = tenantConfig?.name,
                        currency = tenantConfig?.currency,
                        enabled = !selectedSlug.isNullOrBlank() && tenantConfig != null,
                        onChangeTenant = { screen = AppScreen.TENANT_SETUP },
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
                        onSwitchTenant = { screen = AppScreen.TENANT_SETUP },
                    )
                }
            }
        }
    }
}

private fun normalizeBaseUrlForPlatform(input: String): String {
    val trimmed = input.trim().trimEnd('/')
    val platformName = getPlatform().name.lowercase()
    if (!platformName.contains("android")) return trimmed

    return trimmed
        .replace("http://127.0.0.1", "http://10.0.2.2")
        .replace("https://127.0.0.1", "https://10.0.2.2")
        .replace("http://localhost", "http://10.0.2.2")
        .replace("https://localhost", "https://10.0.2.2")
}

@Composable
private fun TenantSetupScreen(
    initialBaseUrl: String,
    onConnect: (String, String) -> Unit,
) {
    var slug by remember { mutableStateOf("") }
    var baseUrl by remember(initialBaseUrl) { mutableStateOf(initialBaseUrl) }
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Tenant Setup", style = MaterialTheme.typography.headlineSmall)
        OutlinedTextField(
            value = baseUrl,
            onValueChange = { baseUrl = it.trim() },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("API Base URL") },
            supportingText = { Text("Example: http://127.0.0.1:8000 (Desktop). Android localhost is auto-mapped to 10.0.2.2") },
        )
        OutlinedTextField(
            value = slug,
            onValueChange = { slug = it.trim().lowercase() },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Tenant Slug") },
            supportingText = { Text("Format: lowercase letters, numbers, dash (3-50)") },
        )
        Button(onClick = { onConnect(slug, baseUrl) }) {
            Text("Connect")
        }
    }
}

@Composable
private fun LoginScreen(
    tenantName: String?,
    currency: String?,
    enabled: Boolean,
    onChangeTenant: () -> Unit,
    onLogin: (String, String) -> Unit,
) {
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Login", style = MaterialTheme.typography.headlineSmall)
        Text("Tenant: ${tenantName ?: "Not selected"}")
        Text("Currency: ${currency ?: "-"}")
        Text("Logo: [placeholder]")
        OutlinedTextField(username, { username = it }, label = { Text("Username") }, modifier = Modifier.fillMaxWidth(), enabled = enabled)
        OutlinedTextField(
            password,
            { password = it },
            label = { Text("Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = PasswordVisualTransformation(),
            enabled = enabled,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = onChangeTenant) { Text("Change tenant") }
            Button(onClick = { onLogin(username, password) }, enabled = enabled) { Text("Login") }
        }
        if (!enabled) {
            Text("Login is disabled until tenant config is available.")
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
