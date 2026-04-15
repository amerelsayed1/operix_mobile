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
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.clients.ClientPayment
import me.amermahsoub.bfm.shared.data.clients.ClientPaymentRequest
import me.amermahsoub.bfm.shared.data.clients.ClientsRepository
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class RecordPaymentUiState(
    val amount: String = "",
    val notes: String = "",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val saved: ClientPayment? = null,
)

class RecordClientPaymentViewModel(
    private val repo: ClientsRepository,
    private val clientId: Long,
) : FeatureViewModel() {
    private val _state = MutableStateFlow(RecordPaymentUiState())
    val state = _state.asStateFlow()

    fun updateAmount(v: String) { _state.value = _state.value.copy(amount = v) }
    fun updateNotes(v: String) { _state.value = _state.value.copy(notes = v) }

    fun submit() {
        val s = _state.value
        val amt = s.amount.toDoubleOrNull()
        if (amt == null || amt <= 0) {
            _state.value = s.copy(error = AppError.Validation("Enter amount"))
            return
        }
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                val saved = repo.recordPayment(
                    clientId,
                    ClientPaymentRequest(amount = s.amount, notes = s.notes.ifBlank { null }),
                )
                _state.value = _state.value.copy(submitting = false, saved = saved)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun RecordClientPaymentScreen(clientId: Long, onSaved: () -> Unit) {
    val repo = remember { GlobalContext.get().get<ClientsRepository>() }
    val vm = rememberFeatureViewModel { RecordClientPaymentViewModel(repo, clientId) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.saved) { if (state.saved != null) onSaved() }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.recordClientPayment)
        FieldRow(strings.amount, state.amount, vm::updateAmount)
        FieldRow(strings.description, state.notes, vm::updateNotes, singleLine = false)
        state.error?.let { Text(it.message, color = MaterialTheme.colorScheme.error) }
        PrimaryButton(
            text = if (state.submitting) strings.loading else strings.save,
            onClick = { vm.submit() },
            enabled = !state.submitting,
        )
    }
}
