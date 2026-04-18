package me.amermahsoub.bfm.features.pos

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.pos.CashMovement
import me.amermahsoub.bfm.shared.data.pos.CashMovementRequest
import me.amermahsoub.bfm.shared.data.pos.PosRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class CashMovementUiState(
    val type: String = "in",
    val amount: String = "",
    val reason: String = "",
    val notes: String = "",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val saved: CashMovement? = null,
)

class CashMovementViewModel(private val repo: PosRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(CashMovementUiState())
    val state = _state.asStateFlow()

    fun selectType(t: String) { _state.value = _state.value.copy(type = t) }
    fun updateAmount(v: String) { _state.value = _state.value.copy(amount = v) }
    fun updateReason(v: String) { _state.value = _state.value.copy(reason = v) }
    fun updateNotes(v: String) { _state.value = _state.value.copy(notes = v) }

    fun submit() {
        val s = _state.value
        if (s.amount.toDoubleOrNull() == null || s.reason.isBlank()) {
            _state.value = s.copy(error = AppError.Validation("Amount and reason required"))
            return
        }
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                val saved = repo.addCashMovement(
                    CashMovementRequest(
                        type = s.type,
                        amount = s.amount,
                        reason = s.reason,
                        notes = s.notes.ifBlank { null },
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
fun CashMovementScreen(onSaved: () -> Unit) {
    val repo = remember { GlobalContext.get().get<PosRepository>() }
    val vm = rememberFeatureViewModel { CashMovementViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.saved) {
        if (state.saved != null) onSaved()
    }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle("${strings.cashIn} / ${strings.cashOut}")
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(
                selected = state.type == "in",
                onClick = { vm.selectType("in") },
                label = { Text(strings.cashIn) },
            )
            FilterChip(
                selected = state.type == "out",
                onClick = { vm.selectType("out") },
                label = { Text(strings.cashOut) },
            )
        }
        OutlinedTextField(
            value = state.amount,
            onValueChange = vm::updateAmount,
            label = { Text(strings.amount) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = state.reason,
            onValueChange = vm::updateReason,
            label = { Text(strings.description) },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = state.notes,
            onValueChange = vm::updateNotes,
            label = { Text(strings.varianceNotes) },
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
