package me.amermahsoub.bfm.shared.data.notifications

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class AppNotification(
    val id: Long,
    val type: String? = null,
    val title: String? = null,
    val body: String? = null,
    @SerialName("is_read") val isRead: Boolean = false,
    @SerialName("action_type") val actionType: String? = null,
    @SerialName("action_id") val actionId: Long? = null,
    @SerialName("created_at") val createdAt: String? = null,
)
