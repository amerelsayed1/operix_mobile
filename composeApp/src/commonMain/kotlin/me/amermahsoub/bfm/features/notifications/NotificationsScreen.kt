package me.amermahsoub.bfm.features.notifications

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import me.amermahsoub.bfm.app.i18n.appStrings
import me.amermahsoub.bfm.app.ui.EmptyState
import me.amermahsoub.bfm.app.ui.ErrorState
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.app.ui.LoadingState
import me.amermahsoub.bfm.app.ui.ScreenTitle
import me.amermahsoub.bfm.app.ui.SecondaryButton
import me.amermahsoub.bfm.app.ui.rememberFeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.notifications.AppNotification
import me.amermahsoub.bfm.shared.data.notifications.NotificationsRepository
import me.amermahsoub.bfm.shared.domain.common.AppError
import org.koin.core.context.GlobalContext

data class NotificationsUiState(
    val loading: Boolean = true,
    val items: List<AppNotification> = emptyList(),
    val error: AppError? = null,
)

class NotificationsViewModel(private val repo: NotificationsRepository) : FeatureViewModel() {
    private val _state = MutableStateFlow(NotificationsUiState())
    val state = _state.asStateFlow()

    init { load() }

    fun refresh() = load()

    fun markAsRead(id: Long) {
        scope.launch {
            runCatching { repo.markAsRead(id) }
            _state.value = _state.value.copy(
                items = _state.value.items.map { if (it.id == id) it.copy(isRead = true) else it }
            )
        }
    }

    fun markAllRead() {
        scope.launch {
            runCatching { repo.markAllRead() }
            _state.value = _state.value.copy(
                items = _state.value.items.map { it.copy(isRead = true) }
            )
        }
    }

    private fun load() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val result = repo.list()
                _state.value = _state.value.copy(loading = false, items = result.data)
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }
}

@Composable
fun NotificationsScreen() {
    val repo = remember { GlobalContext.get().get<NotificationsRepository>() }
    val vm = rememberFeatureViewModel { NotificationsViewModel(repo) }
    val state by vm.state.collectAsState()
    val strings = appStrings()

    when {
        state.loading && state.items.isEmpty() -> LoadingState()
        state.error != null && state.items.isEmpty() -> ErrorState(state.error!!, onRetry = vm::refresh)
        else -> {
            Column(
                modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    ScreenTitle(strings.notificationsTitle)
                    if (state.items.any { !it.isRead }) {
                        SecondaryButton(
                            text = strings.markAllRead,
                            onClick = vm::markAllRead,
                            modifier = Modifier,
                        )
                    }
                }

                if (state.items.isEmpty()) {
                    EmptyState(strings.noNotifications)
                } else {
                    state.items.forEach { notif ->
                        NotificationCard(notif, onRead = { vm.markAsRead(notif.id) })
                    }
                }
            }
        }
    }
}

@Composable
private fun NotificationCard(notif: AppNotification, onRead: () -> Unit) {
    val bgColor = if (notif.isRead)
        MaterialTheme.colorScheme.surface
    else
        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.15f)

    ElevatedCard(
        onClick = { if (!notif.isRead) onRead() },
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.background(bgColor).padding(16.dp).fillMaxWidth(),
            verticalAlignment = Alignment.Top,
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(
                        notifColor(notif.type).copy(alpha = 0.12f),
                    ),
                contentAlignment = Alignment.Center,
            ) {
                Text(notifEmoji(notif.type), style = MaterialTheme.typography.titleMedium)
            }
            Spacer(Modifier.size(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text(
                        notif.title ?: notif.type ?: "",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = if (notif.isRead) FontWeight.Normal else FontWeight.Bold,
                        modifier = Modifier.weight(1f),
                    )
                    if (!notif.isRead) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primary),
                        )
                    }
                }
                notif.body?.let {
                    Spacer(Modifier.height(2.dp))
                    Text(
                        it,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                notif.createdAt?.let {
                    Spacer(Modifier.height(4.dp))
                    Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
private fun notifColor(type: String?): androidx.compose.ui.graphics.Color = when (type?.lowercase()) {
    "low_stock", "stock" -> androidx.compose.ui.graphics.Color(0xFFFF9800)
    "payment", "payment_reminder" -> androidx.compose.ui.graphics.Color(0xFF4CAF50)
    "order" -> MaterialTheme.colorScheme.primary
    "shift" -> androidx.compose.ui.graphics.Color(0xFF9C27B0)
    else -> MaterialTheme.colorScheme.primary
}

private fun notifEmoji(type: String?): String = when (type?.lowercase()) {
    "low_stock", "stock" -> "\uD83D\uDCE6"
    "payment", "payment_reminder" -> "\uD83D\uDCB0"
    "order" -> "\uD83D\uDED2"
    "shift" -> "\u23F0"
    else -> "\uD83D\uDD14"
}
