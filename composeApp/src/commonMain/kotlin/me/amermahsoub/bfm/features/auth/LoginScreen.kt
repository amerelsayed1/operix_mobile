package me.amermahsoub.bfm.features.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
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
    var passwordVisible by remember { mutableStateOf(false) }

    LaunchedEffect(state.loggedIn) {
        if (state.loggedIn) {
            vm.resetLoggedIn()
            onAuthenticated()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        val primary = MaterialTheme.colorScheme.primary
        val onPrimary = MaterialTheme.colorScheme.onPrimary
        val gradient = Brush.verticalGradient(
            colors = listOf(primary, primary.copy(alpha = 0.85f)),
        )
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(bottomStart = 28.dp, bottomEnd = 28.dp))
                .background(gradient)
                .padding(horizontal = 24.dp, vertical = 40.dp),
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(6.dp),
                horizontalAlignment = Alignment.Start,
            ) {
                Text(
                    strings.appName,
                    style = MaterialTheme.typography.displaySmall,
                    fontWeight = FontWeight.ExtraBold,
                    color = onPrimary,
                )
                Text(
                    strings.loginTitle,
                    style = MaterialTheme.typography.titleLarge,
                    color = onPrimary,
                )
                Text(
                    strings.loginSubtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = onPrimary.copy(alpha = 0.85f),
                )
                if (tenantName != null) {
                    Spacer(Modifier.height(6.dp))
                    Text(
                        tenantName,
                        style = MaterialTheme.typography.labelLarge,
                        color = onPrimary,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }

        Spacer(Modifier.height(24.dp))

        ElevatedCard(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            shape = RoundedCornerShape(16.dp),
        ) {
            Column(
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                OutlinedTextField(
                    value = state.tenantSlug,
                    onValueChange = vm::updateSlug,
                    label = { Text(strings.companyCode) },
                    placeholder = { Text(strings.companyCodeHint) },
                    singleLine = true,
                    enabled = !state.submitting,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = state.identity,
                    onValueChange = vm::updateIdentity,
                    label = { Text(strings.username) },
                    placeholder = { Text(strings.usernameHint) },
                    singleLine = true,
                    enabled = !state.submitting,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = state.password,
                    onValueChange = vm::updatePassword,
                    label = { Text(strings.password) },
                    singleLine = true,
                    visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    trailingIcon = {
                        val label = if (passwordVisible) "Hide" else "Show"
                        IconButton(onClick = { passwordVisible = !passwordVisible }) {
                            Text(
                                if (passwordVisible) "\uD83D\uDE48" else "\uD83D\uDC41",
                                style = MaterialTheme.typography.titleMedium,
                            )
                        }
                    },
                    enabled = !state.submitting,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth(),
                )

                state.error?.let { err ->
                    Text(
                        err.message,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }

                if (state.offlineNotice) {
                    Text(
                        strings.offlineBanner,
                        color = MaterialTheme.colorScheme.tertiary,
                        style = MaterialTheme.typography.bodySmall,
                    )
                }

                Spacer(Modifier.height(4.dp))

                PrimaryButton(
                    text = if (state.submitting) strings.loading else strings.accessPortal,
                    onClick = { vm.submit() },
                    enabled = !state.submitting,
                )

                Text(
                    strings.forgotPassword,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable(enabled = !state.submitting) { },
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary,
                )
            }
        }
    }
}

