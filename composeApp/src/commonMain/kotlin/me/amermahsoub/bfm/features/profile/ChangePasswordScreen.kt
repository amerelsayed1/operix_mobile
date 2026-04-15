package me.amermahsoub.bfm.features.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.profile.ChangePasswordRequest
import me.amermahsoub.bfm.shared.data.profile.ProfileRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class ChangePasswordUiState(
    val current: String = "",
    val password: String = "",
    val confirmation: String = "",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val done: Boolean = false,
)

class ChangePasswordViewModel(private val repo: ProfileRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(ChangePasswordUiState())
    val state = _state.asStateFlow()

    fun updateCurrent(v: String) { _state.value = _state.value.copy(current = v) }
    fun updatePassword(v: String) { _state.value = _state.value.copy(password = v) }
    fun updateConfirmation(v: String) { _state.value = _state.value.copy(confirmation = v) }

    fun submit() {
        val s = _state.value
        if (s.current.isBlank() || s.password.isBlank()) {
            _state.value = s.copy(error = AppError.Validation("Enter all fields"))
            return
        }
        if (s.password != s.confirmation) {
            _state.value = s.copy(error = AppError.Validation("Passwords do not match"))
            return
        }
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                repo.changePassword(
                    ChangePasswordRequest(
                        currentPassword = s.current,
                        password = s.password,
                        passwordConfirmation = s.confirmation,
                    ),
                )
                _state.value = _state.value.copy(submitting = false, done = true)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun ChangePasswordScreen(onDone: () -> Unit) {
    val repo = remember { GlobalContext.get().get<ProfileRepository>() }
    val vm = rememberFeatureViewModel { ChangePasswordViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.done) { if (state.done) onDone() }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.changePassword)
        OutlinedTextField(
            value = state.current,
            onValueChange = vm::updateCurrent,
            label = { Text("Current password") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = state.password,
            onValueChange = vm::updatePassword,
            label = { Text(strings.password) },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = state.confirmation,
            onValueChange = vm::updateConfirmation,
            label = { Text("Confirm password") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth(),
        )
        state.error?.let { Text(it.message, color = MaterialTheme.colorScheme.error) }
        PrimaryButton(
            text = if (state.submitting) strings.loading else strings.save,
            onClick = { vm.submit() },
            enabled = !state.submitting,
        )
    }
}
