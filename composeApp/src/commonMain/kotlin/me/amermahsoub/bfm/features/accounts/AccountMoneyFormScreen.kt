package me.amermahsoub.bfm.features.accounts

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
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
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.accounts.Account
import me.amermahsoub.bfm.shared.data.accounts.AccountsRepository
import me.amermahsoub.bfm.shared.data.accounts.DepositRequest
import me.amermahsoub.bfm.shared.data.accounts.TransferRequest
import me.amermahsoub.bfm.shared.data.accounts.WithdrawRequest
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

enum class MoneyFormMode { DEPOSIT, WITHDRAW, TRANSFER }

data class MoneyFormUiState(
    val loading: Boolean = true,
    val accounts: List<Account> = emptyList(),
    val fromAccountId: Long? = null,
    val toAccountId: Long? = null,
    val amount: String = "",
    val notes: String = "",
    val submitting: Boolean = false,
    val error: AppError? = null,
    val saved: Boolean = false,
)

class MoneyFormViewModel(
    private val repo: AccountsRepository,
    private val mode: MoneyFormMode,
    private val preselectedAccount: Long?,
) : FeatureViewModel() {
    private val _state = MutableStateFlow(MoneyFormUiState())
    val state = _state.asStateFlow()

    init {
        scope.launch {
            try {
                val accs = repo.list()
                val from = preselectedAccount ?: accs.firstOrNull { it.isDefault }?.id ?: accs.firstOrNull()?.id
                val to = accs.firstOrNull { it.id != from }?.id
                _state.value = MoneyFormUiState(
                    loading = false,
                    accounts = accs,
                    fromAccountId = from,
                    toAccountId = to,
                )
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }

    fun selectFrom(id: Long) { _state.value = _state.value.copy(fromAccountId = id) }
    fun selectTo(id: Long) { _state.value = _state.value.copy(toAccountId = id) }
    fun updateAmount(v: String) { _state.value = _state.value.copy(amount = v) }
    fun updateNotes(v: String) { _state.value = _state.value.copy(notes = v) }

    fun submit() {
        val s = _state.value
        val from = s.fromAccountId
        if (from == null) {
            _state.value = s.copy(error = AppError.Validation("Select an account"))
            return
        }
        if (s.amount.toDoubleOrNull() == null) {
            _state.value = s.copy(error = AppError.Validation("Enter amount"))
            return
        }
        if (mode == MoneyFormMode.TRANSFER && (s.toAccountId == null || s.toAccountId == from)) {
            _state.value = s.copy(error = AppError.Validation("Select a different destination"))
            return
        }
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                when (mode) {
                    MoneyFormMode.DEPOSIT -> repo.deposit(DepositRequest(accountId = from, amount = s.amount, notes = s.notes.ifBlank { null }))
                    MoneyFormMode.WITHDRAW -> repo.withdraw(WithdrawRequest(accountId = from, amount = s.amount, notes = s.notes.ifBlank { null }))
                    MoneyFormMode.TRANSFER -> repo.transfer(
                        TransferRequest(
                            fromAccountId = from,
                            toAccountId = s.toAccountId!!,
                            amount = s.amount,
                            notes = s.notes.ifBlank { null },
                        ),
                    )
                }
                _state.value = _state.value.copy(submitting = false, saved = true)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun AccountMoneyFormScreen(
    mode: MoneyFormMode,
    preselectedAccount: Long?,
    onSaved: () -> Unit,
) {
    val repo = remember { GlobalContext.get().get<AccountsRepository>() }
    val vm = rememberFeatureViewModel { MoneyFormViewModel(repo, mode, preselectedAccount) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.saved) { if (state.saved) onSaved() }

    if (state.loading) { LoadingState(); return }

    val title = when (mode) {
        MoneyFormMode.DEPOSIT -> strings.deposit
        MoneyFormMode.WITHDRAW -> strings.withdraw
        MoneyFormMode.TRANSFER -> strings.transfer
    }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(title)

        SectionTitle(if (mode == MoneyFormMode.TRANSFER) strings.fromAccount else strings.accountsTitle)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            state.accounts.forEach { acc ->
                FilterChip(
                    selected = state.fromAccountId == acc.id,
                    onClick = { vm.selectFrom(acc.id) },
                    label = { Text(acc.name) },
                )
            }
        }

        if (mode == MoneyFormMode.TRANSFER) {
            SectionTitle(strings.toAccount)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                state.accounts.forEach { acc ->
                    FilterChip(
                        selected = state.toAccountId == acc.id,
                        onClick = { vm.selectTo(acc.id) },
                        label = { Text(acc.name) },
                        enabled = acc.id != state.fromAccountId,
                    )
                }
            }
        }

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
