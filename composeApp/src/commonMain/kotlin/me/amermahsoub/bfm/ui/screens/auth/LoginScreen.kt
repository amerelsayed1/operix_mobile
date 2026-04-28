package me.amermahsoub.bfm.ui.screens.auth

import androidx.compose.foundation.background
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
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import compose.icons.FeatherIcons
import compose.icons.feathericons.Eye
import compose.icons.feathericons.EyeOff
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.shared.data.tenant.TenantContext
import me.amermahsoub.bfm.shared.data.tenant.TenantRepository
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixSurface
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary
import me.amermahsoub.bfm.viewmodel.auth.LoginViewModel
import org.koin.core.context.GlobalContext

@Composable
fun LoginScreen(onLoginSuccess: () -> Unit) {
    val koin = GlobalContext.get()
    val viewModel = remember {
        LoginViewModel(
            repository = koin.get<TenantRepository>(),
            tenantContext = koin.get<TenantContext>(),
            sessionStore = koin.get<SessionStore>(),
        )
    }

    val email by viewModel.email.collectAsState()
    val password by viewModel.password.collectAsState()
    val tenantSlug by viewModel.tenantSlug.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()

    var passwordVisible by remember { mutableStateOf(false) }
    val focusManager = LocalFocusManager.current

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = OperixSurface,
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 48.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            // Logo / Title
            Spacer(Modifier.height(24.dp))
            Box(
                modifier = Modifier
                    .size(72.dp)
                    .background(OperixPrimary, shape = RoundedCornerShape(20.dp)),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "O",
                    color = Color.White,
                    fontSize = 36.sp,
                    fontWeight = FontWeight.ExtraBold,
                )
            }
            Spacer(Modifier.height(12.dp))
            Text(
                text = "Operix",
                style = MaterialTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = OperixPrimary,
            )
            Text(
                text = "Business Finance Manager",
                style = MaterialTheme.typography.bodyMedium,
                color = OperixTextSecondary,
            )
            Spacer(Modifier.height(32.dp))

            // Company Code field
            OutlinedTextField(
                value = tenantSlug,
                onValueChange = { viewModel.onSlugChange(it) },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Company Code") },
                placeholder = { Text("e.g. my-company") },
                singleLine = true,
                enabled = !isLoading,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Ascii,
                    imeAction = ImeAction.Next,
                ),
                keyboardActions = KeyboardActions(
                    onNext = { focusManager.moveFocus(FocusDirection.Down) },
                ),
                shape = RoundedCornerShape(12.dp),
            )

            // Email field
            OutlinedTextField(
                value = email,
                onValueChange = { viewModel.onEmailChange(it) },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Email") },
                placeholder = { Text("you@company.com") },
                singleLine = true,
                enabled = !isLoading,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Next,
                ),
                keyboardActions = KeyboardActions(
                    onNext = { focusManager.moveFocus(FocusDirection.Down) },
                ),
                shape = RoundedCornerShape(12.dp),
            )

            // Password field
            OutlinedTextField(
                value = password,
                onValueChange = { viewModel.onPasswordChange(it) },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Password") },
                placeholder = { Text("••••••••") },
                singleLine = true,
                enabled = !isLoading,
                visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Done,
                ),
                keyboardActions = KeyboardActions(
                    onDone = {
                        focusManager.clearFocus()
                        if (!isLoading) viewModel.login(onLoginSuccess)
                    },
                ),
                trailingIcon = {
                    IconButton(onClick = { passwordVisible = !passwordVisible }) {
                        Icon(
                            imageVector = if (passwordVisible) FeatherIcons.EyeOff else FeatherIcons.Eye,
                            contentDescription = if (passwordVisible) "Hide password" else "Show password",
                            tint = OperixTextSecondary,
                        )
                    }
                },
                shape = RoundedCornerShape(12.dp),
            )

            Spacer(Modifier.height(8.dp))

            // Sign In button
            Button(
                onClick = {
                    focusManager.clearFocus()
                    viewModel.login(onLoginSuccess)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                enabled = !isLoading,
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = OperixPrimary),
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(22.dp),
                        color = Color.White,
                        strokeWidth = 2.5.dp,
                    )
                } else {
                    Text(
                        text = "Sign In",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }

            // Error message
            if (error != null) {
                Spacer(Modifier.height(4.dp))
                Text(
                    text = error!!,
                    color = OperixError,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}
