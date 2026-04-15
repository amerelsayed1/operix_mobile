package me.amermahsoub.bfm.features.clients

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
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
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.StatCard
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.clients.Client
import me.amermahsoub.bfm.shared.data.clients.ClientsRepository
import me.amermahsoub.bfm.shared.data.clients.ClientsSummary
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class ClientsListUiState(
    val loading: Boolean = true,
    val query: String = "",
    val clients: List<Client> = emptyList(),
    val summary: ClientsSummary? = null,
    val error: AppError? = null,
)

class ClientsListViewModel(private val repo: ClientsRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(ClientsListUiState())
    val state = _state.asStateFlow()

    init { refresh() }

    fun updateQuery(q: String) {
        _state.value = _state.value.copy(query = q)
        scope.launch {
            try {
                val page = repo.list(search = q.ifBlank { null })
                _state.value = _state.value.copy(clients = page.data)
            } catch (_: Throwable) {}
        }
    }

    fun refresh() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val summary = runCatching { repo.summary() }.getOrNull()
                val page = repo.list()
                _state.value = ClientsListUiState(loading = false, clients = page.data, summary = summary)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun ClientsListScreen(onClient: (Long) -> Unit, onAddClient: () -> Unit) {
    val repo = remember { GlobalContext.get().get<ClientsRepository>() }
    val vm = rememberFeatureViewModel { ClientsListViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    if (state.loading && state.clients.isEmpty()) {
        LoadingState()
        return
    }

    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ScreenTitle(strings.clientsTitle)
        state.summary?.let { summary ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Column(modifier = Modifier.weight(1f)) {
                    StatCard(strings.totalReceivables, summary.totalReceivables ?: "—")
                }
                Column(modifier = Modifier.weight(1f)) {
                    StatCard(
                        strings.overdue,
                        summary.overdueAmount ?: "—",
                        accent = MaterialTheme.colorScheme.error,
                    )
                }
            }
        }
        OutlinedTextField(
            value = state.query,
            onValueChange = vm::updateQuery,
            label = { Text(strings.search) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        PrimaryButton(text = strings.addClient, onClick = onAddClient)
        state.error?.let { Text(it.message, color = MaterialTheme.colorScheme.error) }
        state.clients.forEach { client ->
            ListRow(
                title = client.name,
                subtitle = client.phone ?: client.email,
                trailing = client.balance ?: "",
                badge = if (client.isBlocked) "Blocked" else null,
                onClick = { onClient(client.id) },
            )
        }
    }
}
