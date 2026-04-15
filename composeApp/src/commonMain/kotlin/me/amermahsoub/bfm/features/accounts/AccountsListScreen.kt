package me.amermahsoub.bfm.features.accounts

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.EmptyState
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SecondaryButton
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.accounts.Account
import me.amermahsoub.bfm.shared.data.accounts.AccountsRepository
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class AccountsListUiState(
    val loading: Boolean = true,
    val items: List<Account> = emptyList(),
    val error: AppError? = null,
)

class AccountsListViewModel(private val repo: AccountsRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(AccountsListUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val items = repo.list()
                _state.value = AccountsListUiState(loading = false, items = items)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun AccountsListScreen(
    onAccount: (Long) -> Unit,
    onDeposit: () -> Unit,
    onWithdraw: () -> Unit,
    onTransfer: () -> Unit,
) {
    val repo = remember { GlobalContext.get().get<AccountsRepository>() }
    val vm = rememberFeatureViewModel { AccountsListViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null && state.items.isEmpty() -> ErrorState(state.error!!, onRetry = vm::load)
        else -> Column(
            modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ScreenTitle(strings.accountsTitle)
            PrimaryButton(strings.deposit, onClick = onDeposit)
            SecondaryButton(strings.withdraw, onClick = onWithdraw)
            SecondaryButton(strings.transfer, onClick = onTransfer)
            if (state.items.isEmpty()) {
                EmptyState()
            } else {
                state.items.forEach { acc ->
                    ListRow(
                        title = acc.name,
                        subtitle = acc.type,
                        trailing = acc.currentBalance ?: "",
                        badge = if (acc.isDefault) "Default" else null,
                        onClick = { onAccount(acc.id) },
                    )
                }
            }
        }
    }
}
