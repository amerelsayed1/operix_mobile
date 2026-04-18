package me.amermahsoub.bfm.shared.data.notifications

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.common.decodePaginated
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder
import me.amermahsoub.bfm.shared.domain.common.Paginated

class NotificationsApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun list(page: Int = 1): Paginated<AppNotification> =
        json.decodePaginated(AppNotification.serializer()) {
            client.get(urls.notifications()) {
                parameter("page", page)
            }
        }

    suspend fun markAsRead(id: Long) {
        client.post(urls.notificationMarkRead(id))
    }

    suspend fun markAllRead() {
        client.post(urls.notificationsMarkAllRead())
    }

    suspend fun unreadCount(): Int {
        return runCatching {
            list(page = 1).data.count { !it.isRead }
        }.getOrElse { 0 }
    }
}
