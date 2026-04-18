package me.amermahsoub.bfm.features.pos

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.pos.PosRepository
import me.amermahsoub.bfm.shared.data.pos.Shift
import me.amermahsoub.bfm.shared.data.pos.ShiftCloseRequest
import me.amermahsoub.bfm.shared.data.pos.ShiftSummary
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class CloseShiftUiState(
    val loading: Boolean = true,
    val summary: ShiftSummary? = null,
    val actualCash: String = "",
    val varianceNotes: String = "",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val closed: Shift? = null,
)

class CloseShiftViewModel(private val repo: PosRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(CloseShiftUiState())
    val state = _state.asStateFlow()

    init {
        scope.launch {
            try {
                val summary = repo.shiftSummary()
                _state.value = _state.value.copy(loading = false, summary = summary)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }

    fun updateActualCash(v: String) { _state.value = _state.value.copy(actualCash = v) }
    fun updateVarianceNotes(v: String) { _state.value = _state.value.copy(varianceNotes = v) }

    fun submit() {
        val s = _state.value
        if (s.actualCash.toDoubleOrNull() == null) {
            _state.value = s.copy(error = AppError.Validation("Enter counted cash"))
            return
        }
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                val closed = repo.closeShift(
                    ShiftCloseRequest(actualCash = s.actualCash, varianceNotes = s.varianceNotes.ifBlank { null }),
                )
                _state.value = _state.value.copy(submitting = false, closed = closed)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun CloseShiftScreen(onClosed: () -> Unit) {
    val repo = remember { GlobalContext.get().get<PosRepository>() }
    val vm = rememberFeatureViewModel { CloseShiftViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.closed) {
        if (state.closed != null) onClosed()
    }

    if (state.loading) {
        LoadingState()
        return
    }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.closeShift)
        state.summary?.let { summary ->
            SectionTitle(strings.shiftSummary)
            ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    SummaryRow(strings.totalSales, summary.totalSales ?: "—")
                    SummaryRow(strings.orders, summary.totalOrders?.toString() ?: "—")
                    SummaryRow(strings.cashIn, summary.cashIn ?: "—")
                    SummaryRow(strings.cashOut, summary.cashOut ?: "—")
                    SummaryRow("Expected cash", summary.expectedCash ?: "—")
                }
            }
        }
        OutlinedTextField(
            value = state.actualCash,
            onValueChange = vm::updateActualCash,
            label = { Text(strings.actualCash) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = state.varianceNotes,
            onValueChange = vm::updateVarianceNotes,
            label = { Text(strings.varianceNotes) },
            modifier = Modifier.fillMaxWidth(),
        )
        state.error?.let { Text(it.message, color = MaterialTheme.colorScheme.error) }
        PrimaryButton(
            text = if (state.submitting) strings.loading else strings.closeShift,
            onClick = { vm.submit() },
            enabled = !state.submitting,
        )
    }
}

@Composable
private fun SummaryRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value)
    }
}
