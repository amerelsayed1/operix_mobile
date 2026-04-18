package me.amermahsoub.bfm.features.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SecondaryButton
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.profile.ProfileInfo
import me.amermahsoub.bfm.shared.data.profile.ProfileRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class ProfileUiState(
    val loading: Boolean = true,
    val profile: ProfileInfo? = null,
    val error: AppError? = null,
)

class ProfileViewModel(private val repo: ProfileRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(ProfileUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val info = repo.get()
                _state.value = ProfileUiState(loading = false, profile = info)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun ProfileScreen(onEdit: () -> Unit, onChangePassword: () -> Unit, onLogout: () -> Unit) {
    val repo = remember { GlobalContext.get().get<ProfileRepository>() }
    val vm = rememberFeatureViewModel { ProfileViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null && state.profile == null -> ErrorState(state.error!!, onRetry = vm::load)
        state.profile != null -> {
            val p = state.profile!!
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ScreenTitle(strings.profileTitle)
                ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(p.name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        KeyVal(strings.email, p.email)
                        KeyVal(strings.phone, p.phone)
                        KeyVal("Role", p.role)
                        KeyVal(strings.language, p.locale)
                    }
                }
                PrimaryButton(strings.editProfile, onClick = onEdit)
                SecondaryButton(strings.changePassword, onClick = onChangePassword)
                SecondaryButton(strings.logout, onClick = onLogout)
            }
        }
    }
}

@Composable
private fun KeyVal(label: String, value: String?) {
    if (value.isNullOrBlank()) return
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, fontWeight = FontWeight.SemiBold)
    }
}
