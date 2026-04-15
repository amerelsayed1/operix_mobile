package me.amermahsoub.bfm.features.auth

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import org.koin.core.context.GlobalContext

@Composable
fun LoginScreen(
    initialTenantSlug: String?,
    tenantName: String?,
    primaryColorHex: String? = null,
    onAuthenticated: () -> Unit,
) {
    val tenantRepository = remember { GlobalContext.get().get<TenantRepository>() }
    val vm = rememberFeatureViewModel { LoginViewModel(tenantRepository, initialTenantSlug) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.loggedIn) {
        if (state.loggedIn) {
            vm.resetLoggedIn()
            onAuthenticated()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        ElevatedCard(modifier = Modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier.padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
                horizontalAlignment = Alignment.Start,
            ) {
                Text(strings.appName, style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.ExtraBold)
                Text(strings.loginTitle, style = MaterialTheme.typography.titleLarge)
                Text(strings.loginSubtitle, style = MaterialTheme.typography.bodyMedium)
                if (tenantName != null) {
                    Spacer(Modifier.height(4.dp))
                    Text("Tenant: $tenantName", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
                }
            }
        }

        ElevatedCard(modifier = Modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedTextField(
                    value = state.tenantSlug,
                    onValueChange = vm::updateSlug,
                    label = { Text(strings.companyCode) },
                    placeholder = { Text(strings.companyCodeHint) },
                    singleLine = true,
                    enabled = !state.submitting,
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = state.identity,
                    onValueChange = vm::updateIdentity,
                    label = { Text(strings.username) },
                    placeholder = { Text(strings.usernameHint) },
                    singleLine = true,
                    enabled = !state.submitting,
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = state.password,
                    onValueChange = vm::updatePassword,
                    label = { Text(strings.password) },
                    singleLine = true,
                    visualTransformation = PasswordVisualTransformation(),
                    enabled = !state.submitting,
                    modifier = Modifier.fillMaxWidth(),
                )

                state.error?.let { err ->
                    Text(err.message, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium)
                }

                if (state.offlineNotice) {
                    Text(
                        strings.offlineBanner,
                        color = MaterialTheme.colorScheme.tertiary,
                        style = MaterialTheme.typography.bodySmall,
                    )
                }

                PrimaryButton(
                    text = if (state.submitting) strings.loading else strings.accessPortal,
                    onClick = { vm.submit() },
                    enabled = !state.submitting,
                )
            }
        }
    }
}

