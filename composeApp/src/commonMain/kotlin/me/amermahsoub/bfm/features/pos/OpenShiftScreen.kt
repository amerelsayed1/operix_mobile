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
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.pos.PosAccountDto
import me.amermahsoub.bfm.shared.data.pos.PosRepository
import me.amermahsoub.bfm.shared.data.pos.Shift
import me.amermahsoub.bfm.shared.data.pos.ShiftOpenRequest
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class OpenShiftUiState(
    val loading: Boolean = true,
    val drawers: List<PosAccountDto> = emptyList(),
    val selectedDrawer: PosAccountDto? = null,
    val openingCash: String = "",
    val note: String = "",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val openedShift: Shift? = null,
)

class OpenShiftViewModel(private val repo: PosRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(OpenShiftUiState())
    val state = _state.asStateFlow()

    init {
        scope.launch {
            try {
                val drawers = repo.availableDrawers()
                _state.value = _state.value.copy(loading = false, drawers = drawers, selectedDrawer = drawers.firstOrNull())
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }

    fun selectDrawer(d: PosAccountDto) { _state.value = _state.value.copy(selectedDrawer = d) }
    fun updateOpeningCash(v: String) { _state.value = _state.value.copy(openingCash = v) }
    fun updateNote(v: String) { _state.value = _state.value.copy(note = v) }

    fun submit() {
        val s = _state.value
        val cash = s.openingCash.trim()
        if (cash.isBlank() || cash.toDoubleOrNull() == null) {
            _state.value = s.copy(error = AppError.Validation("Enter opening cash"))
            return
        }
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                val shift = repo.openShift(
                    ShiftOpenRequest(
                        drawerAccountId = s.selectedDrawer?.id,
                        openingCash = cash,
                        note = s.note.ifBlank { null },
                    ),
                )
                _state.value = _state.value.copy(submitting = false, openedShift = shift)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun OpenShiftScreen(onOpened: () -> Unit, onCancel: () -> Unit) {
    val repo = remember { GlobalContext.get().get<PosRepository>() }
    val vm = rememberFeatureViewModel { OpenShiftViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.openedShift) {
        if (state.openedShift != null) onOpened()
    }

    if (state.loading) {
        LoadingState()
        return
    }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.openShift)
        if (state.drawers.isNotEmpty()) {
            SectionTitle(strings.drawerAccount)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                state.drawers.forEach { d ->
                    FilterChip(
                        selected = state.selectedDrawer?.id == d.id,
                        onClick = { vm.selectDrawer(d) },
                        label = { Text(d.name) },
                    )
                }
            }
        }
        OutlinedTextField(
            value = state.openingCash,
            onValueChange = vm::updateOpeningCash,
            label = { Text(strings.openingCash) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = state.note,
            onValueChange = vm::updateNote,
            label = { Text(strings.description) },
            modifier = Modifier.fillMaxWidth(),
        )
        state.error?.let { Text(it.message, color = MaterialTheme.colorScheme.error) }
        PrimaryButton(
            text = if (state.submitting) strings.loading else strings.openShift,
            onClick = { vm.submit() },
            enabled = !state.submitting,
        )
    }
}
