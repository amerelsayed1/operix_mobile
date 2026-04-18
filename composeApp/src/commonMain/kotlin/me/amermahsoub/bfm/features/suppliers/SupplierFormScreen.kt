package me.amermahsoub.bfm.features.suppliers

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
import me.amermahsoub.bfm.shared.data.suppliers.Supplier
import me.amermahsoub.bfm.shared.data.suppliers.SupplierCreateRequest
import me.amermahsoub.bfm.shared.data.suppliers.SuppliersRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class SupplierFormUiState(
    val loading: Boolean = false,
    val name: String = "",
    val phone: String = "",
    val email: String = "",
    val address: String = "",
    val contactPerson: String = "",
    val taxNumber: String = "",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val saved: Supplier? = null,
)

class SupplierFormViewModel(
    private val repo: SuppliersRepository,
    private val existingId: Long?,
) : FeatureViewModel() {
    private val _state = MutableStateFlow(SupplierFormUiState())
    val state = _state.asStateFlow()

    init {
        if (existingId != null) loadExisting()
    }

    private fun loadExisting() {
        scope.launch {
            _state.value = _state.value.copy(loading = true)
            try {
                val s = repo.get(existingId!!)
                _state.value = _state.value.copy(
                    loading = false,
                    name = s.name,
                    phone = s.phone ?: "",
                    email = s.email ?: "",
                    address = s.address ?: "",
                    contactPerson = s.contactPerson ?: "",
                    taxNumber = s.taxNumber ?: "",
                )
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }

    fun updateName(v: String) { _state.value = _state.value.copy(name = v) }
    fun updatePhone(v: String) { _state.value = _state.value.copy(phone = v) }
    fun updateEmail(v: String) { _state.value = _state.value.copy(email = v) }
    fun updateAddress(v: String) { _state.value = _state.value.copy(address = v) }
    fun updateContact(v: String) { _state.value = _state.value.copy(contactPerson = v) }
    fun updateTax(v: String) { _state.value = _state.value.copy(taxNumber = v) }

    fun submit() {
        val s = _state.value
        if (s.name.isBlank()) {
            _state.value = s.copy(error = AppError.Validation("Name is required"))
            return
        }
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                val req = SupplierCreateRequest(
                    name = s.name,
                    phone = s.phone.ifBlank { null },
                    email = s.email.ifBlank { null },
                    address = s.address.ifBlank { null },
                    contactPerson = s.contactPerson.ifBlank { null },
                    taxNumber = s.taxNumber.ifBlank { null },
                )
                val saved = if (existingId != null) repo.update(existingId, req) else repo.create(req)
                _state.value = _state.value.copy(submitting = false, saved = saved)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun SupplierFormScreen(existingId: Long?, onSaved: () -> Unit) {
    val repo = remember { GlobalContext.get().get<SuppliersRepository>() }
    val vm = rememberFeatureViewModel { SupplierFormViewModel(repo, existingId) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.saved) { if (state.saved != null) onSaved() }

    if (state.loading) { LoadingState(); return }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(if (existingId != null) strings.editSupplier else strings.addSupplier)

        FieldRow(label = strings.supplierName, value = state.name, onValueChange = vm::updateName)
        FieldRow(label = strings.contactPerson, value = state.contactPerson, onValueChange = vm::updateContact)
        FieldRow(label = strings.phone, value = state.phone, onValueChange = vm::updatePhone)
        FieldRow(label = strings.email, value = state.email, onValueChange = vm::updateEmail)
        FieldRow(label = strings.address, value = state.address, onValueChange = vm::updateAddress)
        FieldRow(label = strings.taxNumber, value = state.taxNumber, onValueChange = vm::updateTax)

        state.error?.let { Text(it.message, color = MaterialTheme.colorScheme.error) }

        PrimaryButton(
            text = if (state.submitting) strings.loading else strings.save,
            onClick = vm::submit,
            enabled = !state.submitting,
        )
    }
}
