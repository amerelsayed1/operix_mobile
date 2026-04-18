package me.amermahsoub.bfm.features.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.FieldRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.profile.ProfileInfo
import me.amermahsoub.bfm.shared.data.profile.ProfileRepository
import me.amermahsoub.bfm.shared.data.profile.UpdateProfileRequest
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class EditProfileUiState(
    val loading: Boolean = true,
    val name: String = "",
    val email: String = "",
    val phone: String = "",
    val locale: String = "en",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val saved: ProfileInfo? = null,
)

class EditProfileViewModel(private val repo: ProfileRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(EditProfileUiState())
    val state = _state.asStateFlow()

    init {
        scope.launch {
            try {
                val p = repo.get()
                _state.value = EditProfileUiState(
                    loading = false,
                    name = p.name,
                    email = p.email.orEmpty(),
                    phone = p.phone.orEmpty(),
                    locale = p.locale.orEmpty().ifBlank { "en" },
                )
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }

    fun updateName(v: String) { _state.value = _state.value.copy(name = v) }
    fun updateEmail(v: String) { _state.value = _state.value.copy(email = v) }
    fun updatePhone(v: String) { _state.value = _state.value.copy(phone = v) }
    fun updateLocale(v: String) { _state.value = _state.value.copy(locale = v) }

    fun submit() {
        val s = _state.value
        if (s.name.isBlank()) {
            _state.value = s.copy(error = AppError.Validation("Name required"))
            return
        }
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                val saved = repo.update(
                    UpdateProfileRequest(
                        name = s.name.trim(),
                        email = s.email.ifBlank { null },
                        phone = s.phone.ifBlank { null },
                        locale = s.locale.ifBlank { null },
                    ),
                )
                _state.value = _state.value.copy(submitting = false, saved = saved)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun EditProfileScreen(onSaved: () -> Unit) {
    val repo = remember { GlobalContext.get().get<ProfileRepository>() }
    val vm = rememberFeatureViewModel { EditProfileViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.saved) { if (state.saved != null) onSaved() }

    if (state.loading) { LoadingState(); return }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.editProfile)
        FieldRow(strings.clientName, state.name, vm::updateName)
        FieldRow(strings.email, state.email, vm::updateEmail)
        FieldRow(strings.phone, state.phone, vm::updatePhone)
        FieldRow(strings.language, state.locale, vm::updateLocale)
        state.error?.let { Text(it.message, color = MaterialTheme.colorScheme.error) }
        PrimaryButton(
            text = if (state.submitting) strings.loading else strings.save,
            onClick = { vm.submit() },
            enabled = !state.submitting,
        )
    }
}
