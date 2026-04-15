package me.amermahsoub.bfm.features.expenses

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
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
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
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.expenses.Expense
import me.amermahsoub.bfm.shared.data.expenses.ExpenseCategory
import me.amermahsoub.bfm.shared.data.expenses.ExpenseCreateRequest
import me.amermahsoub.bfm.shared.data.expenses.ExpensesRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class ExpenseFormUiState(
    val loading: Boolean = true,
    val categories: List<ExpenseCategory> = emptyList(),
    val accounts: List<Account> = emptyList(),
    val selectedCategoryId: Long? = null,
    val selectedAccountId: Long? = null,
    val amount: String = "",
    val date: String = today(),
    val description: String = "",
    val isAds: Boolean = false,
    val submitting: Boolean = false,
    val error: AppError? = null,
    val saved: Expense? = null,
)

@OptIn(ExperimentalTime::class)
private fun today(): String {
    return Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date.toString()
}

class ExpenseFormViewModel(
    private val expenses: ExpensesRepository,
    private val accounts: AccountsRepository,
    private val existingId: Long?,
) : FeatureViewModel() {
    private val _state = MutableStateFlow(ExpenseFormUiState())
    val state = _state.asStateFlow()

    init {
        scope.launch {
            try {
                val cats = runCatching { expenses.categories() }.getOrElse { emptyList() }
                val accs = runCatching { accounts.list() }.getOrElse { emptyList() }
                val defaultAccount = accs.firstOrNull { it.isDefault } ?: accs.firstOrNull()
                var s = _state.value.copy(
                    loading = false,
                    categories = cats,
                    accounts = accs,
                    selectedAccountId = defaultAccount?.id,
                )
                if (existingId != null) {
                    val exp = expenses.get(existingId)
                    s = s.copy(
                        selectedCategoryId = exp.categoryId,
                        selectedAccountId = exp.accountId ?: s.selectedAccountId,
                        amount = exp.amount,
                        date = exp.date ?: s.date,
                        description = exp.description.orEmpty(),
                        isAds = exp.isAds,
                    )
                }
                _state.value = s
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }

    fun selectCategory(id: Long?) { _state.value = _state.value.copy(selectedCategoryId = id) }
    fun selectAccount(id: Long) { _state.value = _state.value.copy(selectedAccountId = id) }
    fun updateAmount(v: String) { _state.value = _state.value.copy(amount = v) }
    fun updateDate(v: String) { _state.value = _state.value.copy(date = v) }
    fun updateDescription(v: String) { _state.value = _state.value.copy(description = v) }
    fun toggleAds() { _state.value = _state.value.copy(isAds = !_state.value.isAds) }

    fun submit() {
        val s = _state.value
        val acct = s.selectedAccountId
        if (acct == null) {
            _state.value = s.copy(error = AppError.Validation("Select an account"))
            return
        }
        if (s.amount.toDoubleOrNull() == null) {
            _state.value = s.copy(error = AppError.Validation("Enter amount"))
            return
        }
        val req = ExpenseCreateRequest(
            accountId = acct,
            categoryId = s.selectedCategoryId,
            amount = s.amount,
            date = s.date,
            description = s.description.ifBlank { null },
            isAds = s.isAds,
        )
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                val saved = if (existingId == null) expenses.create(req)
                else expenses.update(existingId, req)
                _state.value = _state.value.copy(submitting = false, saved = saved)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun ExpenseFormScreen(existingId: Long?, onSaved: () -> Unit) {
    val koin = GlobalContext.get()
    val expensesRepo = remember { koin.get<ExpensesRepository>() }
    val accountsRepo = remember { koin.get<AccountsRepository>() }
    val vm = rememberFeatureViewModel { ExpenseFormViewModel(expensesRepo, accountsRepo, existingId) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    LaunchedEffect(state.saved) { if (state.saved != null) onSaved() }

    if (state.loading) { LoadingState(); return }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.addExpenseTitle)

        SectionTitle(strings.accountsTitle)
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            state.accounts.forEach { acc ->
                FilterChip(
                    selected = state.selectedAccountId == acc.id,
                    onClick = { vm.selectAccount(acc.id) },
                    label = { Text(acc.name) },
                )
            }
        }

        if (state.categories.isNotEmpty()) {
            SectionTitle(strings.category)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = state.selectedCategoryId == null,
                    onClick = { vm.selectCategory(null) },
                    label = { Text("—") },
                )
                state.categories.forEach { cat ->
                    FilterChip(
                        selected = state.selectedCategoryId == cat.id,
                        onClick = { vm.selectCategory(cat.id) },
                        label = { Text(cat.name) },
                    )
                }
            }
        }

        FieldRow(strings.amount, state.amount, vm::updateAmount)
        FieldRow(strings.date, state.date, vm::updateDate)
        FieldRow(strings.description, state.description, vm::updateDescription, singleLine = false)

        state.error?.let { Text(it.message, color = MaterialTheme.colorScheme.error) }
        PrimaryButton(
            text = if (state.submitting) strings.loading else strings.save,
            onClick = { vm.submit() },
            enabled = !state.submitting,
        )
    }
}
