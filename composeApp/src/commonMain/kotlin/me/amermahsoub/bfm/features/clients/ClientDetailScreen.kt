package me.amermahsoub.bfm.features.clients

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.BadgeChip
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.ListRow
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.PrimaryButton
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SecondaryButton
import me.amermahsoub.bfm.app.ui.SectionTitle
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.clients.Client
import me.amermahsoub.bfm.shared.data.clients.ClientPayment
import me.amermahsoub.bfm.shared.data.clients.ClientsRepository
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class ClientDetailUiState(
    val loading: Boolean = true,
    val client: Client? = null,
    val payments: List<ClientPayment> = emptyList(),
    val error: AppError? = null,
    val actionInProgress: Boolean = false,
)

class ClientDetailViewModel(private val repo: ClientsRepository, private val id: Long) : FeatureViewModel() {
    private val _state = MutableStateFlow(ClientDetailUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val client = repo.get(id)
                val payments = runCatching { repo.payments(id) }.getOrElse { emptyList() }
                _state.value = ClientDetailUiState(loading = false, client = client, payments = payments)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }

    fun toggleBlock() {
        val current = _state.value.client ?: return
        scope.launch {
            _state.value = _state.value.copy(actionInProgress = true)
            try {
                val updated = if (current.isBlocked) repo.unblock(id) else repo.block(id)
                _state.value = _state.value.copy(client = updated, actionInProgress = false)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(actionInProgress = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun ClientDetailScreen(
    id: Long,
    onEdit: () -> Unit,
    onRecordPayment: () -> Unit,
) {
    val repo = remember { GlobalContext.get().get<ClientsRepository>() }
    val vm = rememberFeatureViewModel { ClientDetailViewModel(repo, id) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading -> LoadingState()
        state.error != null && state.client == null -> ErrorState(state.error!!, onRetry = vm::load)
        state.client != null -> {
            val client = state.client!!
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ScreenTitle(client.name)
                if (client.isBlocked) BadgeChip(text = "Blocked", color = MaterialTheme.colorScheme.error)

                ElevatedCard(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        KeyVal(strings.phone, client.phone)
                        KeyVal(strings.email, client.email)
                        KeyVal(strings.address, client.address)
                        KeyVal(strings.creditLimit, client.creditLimit)
                        KeyVal(strings.balance, client.balance)
                    }
                }

                PrimaryButton(strings.recordClientPayment, onClick = onRecordPayment)
                SecondaryButton(strings.editProfile, onClick = onEdit)
                SecondaryButton(
                    if (client.isBlocked) strings.unblockClient else strings.blockClient,
                    onClick = { vm.toggleBlock() },
                )

                if (state.payments.isNotEmpty()) {
                    SectionTitle(strings.recordPayment)
                    state.payments.forEach { pay ->
                        ListRow(
                            title = pay.reference ?: "Payment #${pay.id}",
                            subtitle = pay.paymentDate ?: pay.createdAt,
                            trailing = pay.amount,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun KeyVal(label: String, value: String?) {
    if (value.isNullOrBlank()) return
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, fontWeight = FontWeight.SemiBold)
    }
}
