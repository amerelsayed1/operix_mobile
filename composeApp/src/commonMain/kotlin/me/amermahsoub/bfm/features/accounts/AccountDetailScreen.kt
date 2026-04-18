package me.amermahsoub.bfm.features.accounts

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
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
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.StatCard
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.accounts.Account
import me.amermahsoub.bfm.shared.data.accounts.AccountHistoryEntry
import me.amermahsoub.bfm.shared.data.accounts.AccountsRepository
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class AccountDetailUiState(
    val loading: Boolean = true,
    val account: Account? = null,
    val history: List<AccountHistoryEntry> = emptyList(),
    val error: AppError? = null,
)

class AccountDetailViewModel(private val repo: AccountsRepository, private val id: Long) : FeatureViewModel() {
    private val _state = MutableStateFlow(AccountDetailUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val account = repo.get(id)
                val history = runCatching { repo.history(id).data }.getOrElse { emptyList() }
                _state.value = AccountDetailUiState(loading = false, account = account, history = history)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun AccountDetailScreen(id: Long) {
    val repo = remember { GlobalContext.get().get<AccountsRepository>() }
    val vm = rememberFeatureViewModel { AccountDetailViewModel(repo, id) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null && state.account == null -> ErrorState(state.error!!, onRetry = vm::load)
        state.account != null -> {
            val acc = state.account!!
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ScreenTitle(acc.name)
                StatCard(strings.balance, acc.currentBalance ?: "—", accent = MaterialTheme.colorScheme.primary)

                SectionTitle("History")
                state.history.forEach { e ->
                    ListRow(
                        title = e.type,
                        subtitle = e.reference ?: e.createdAt,
                        trailing = e.amount,
                        badge = e.balanceAfter,
                    )
                }
            }
        }
    }
}
