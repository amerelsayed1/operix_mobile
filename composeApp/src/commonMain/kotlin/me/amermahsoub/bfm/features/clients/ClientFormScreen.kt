package me.amermahsoub.bfm.features.clients

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
import me.amermahsoub.bfm.shared.data.clients.Client
import me.amermahsoub.bfm.shared.data.clients.ClientCreateRequest
import me.amermahsoub.bfm.shared.data.clients.ClientsRepository
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class ClientFormUiState(
    val loading: Boolean = false,
    val name: String = "",
    val phone: String = "",
    val email: String = "",
    val address: String = "",
    val creditLimit: String = "",
    val notes: String = "",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val saved: Client? = null,
)

class ClientFormViewModel(
    private val repo: ClientsRepository,
    private val existingId: Long?,
) : FeatureViewModel() {
    private val _state = MutableStateFlow(ClientFormUiState(loading = existingId != null))
    val state = _state.asStateFlow()

    init {
        if (existingId != null) {
            scope.launch {
                try {
                    val c = repo.get(existingId)
                    _state.value = _state.value.copy(
                        loading = false,
                        name = c.name,
                        phone = c.phone.orEmpty(),
                        email = c.email.orEmpty(),
                        address = c.address.orEmpty(),
                        creditLimit = c.creditLimit.orEmpty(),
                        notes = c.notes.orEmpty(),
                    )
                } catch (e: Throwable) {
                    _state.value = _state.value.copy(loading = false, error = e.toAppError())
                }
            }
        }
    }

    fun updateName(v: String) { _state.value = _state.value.copy(name = v) }
    fun updatePhone(v: String) { _state.value = _state.value.copy(phone = v) }
    fun updateEmail(v: String) { _state.value = _state.value.copy(email = v) }
    fun updateAddress(v: String) { _state.value = _state.value.copy(address = v) }
    fun updateCreditLimit(v: String) { _state.value = _state.value.copy(creditLimit = v) }
    fun updateNotes(v: String) { _state.value = _state.value.copy(notes = v) }

    fun submit() {
        val s = _state.value
        if (s.name.isBlank()) {
            _state.value = s.copy(error = AppError.Validation("Name is required"))
            return
        }
        val req = ClientCreateRequest(
            name = s.name.trim(),
            phone = s.phone.ifBlank { null },
            email = s.email.ifBlank { null },
            address = s.address.ifBlank { null },
            creditLimit = s.creditLimit.ifBlank { null },
            notes = s.notes.ifBlank { null },
        )
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                val saved = if (existingId == null) repo.create(req) else repo.update(existingId, req)
                _state.value = _state.value.copy(submitting = false, saved = saved)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun ClientFormScreen(existingId: Long?, onSaved: () -> Unit) {
    val repo = remember { GlobalContext.get().get<ClientsRepository>() }
    val vm = rememberFeatureViewModel { ClientFormViewModel(repo, existingId) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.saved) {
        if (state.saved != null) onSaved()
    }

    if (state.loading) {
        LoadingState()
        return
    }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(if (existingId == null) strings.addClient else strings.editProfile)
        FieldRow(strings.clientName, state.name, vm::updateName)
        FieldRow(strings.phone, state.phone, vm::updatePhone)
        FieldRow(strings.email, state.email, vm::updateEmail)
        FieldRow(strings.address, state.address, vm::updateAddress, singleLine = false)
        FieldRow(strings.creditLimit, state.creditLimit, vm::updateCreditLimit)
        FieldRow(strings.description, state.notes, vm::updateNotes, singleLine = false)
        state.error?.let { Text(it.message, color = MaterialTheme.colorScheme.error) }
        PrimaryButton(
            text = if (state.submitting) strings.loading else strings.save,
            onClick = { vm.submit() },
            enabled = !state.submitting,
        )
    }
}
