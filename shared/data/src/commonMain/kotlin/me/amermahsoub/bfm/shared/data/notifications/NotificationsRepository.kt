package me.amermahsoub.bfm.shared.data.notifications

import me.amermahsoub.bfm.shared.domain.common.Paginated

class NotificationsRepository(private val api: NotificationsApi) {
    suspend fun list(page: Int = 1): Paginated<AppNotification> = api.list(page)
    suspend fun markAsRead(id: Long) = api.markAsRead(id)
    suspend fun markAllRead() = api.markAllRead()
    suspend fun unreadCount(): Int = api.unreadCount()
}
