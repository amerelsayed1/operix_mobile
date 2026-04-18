package me.amermahsoub.bfm.shared.data.notifications

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class NotificationsModelsSerializationTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun appNotificationRoundtrip() {
        val notification = AppNotification(
            id = 1,
            type = "order",
            title = "New Order",
            body = "You have a new order #123",
            isRead = true,
            actionType = "navigate",
            actionId = 123,
            createdAt = "2026-04-01T10:00:00Z",
        )
        val encoded = json.encodeToString(AppNotification.serializer(), notification)
        val decoded = json.decodeFromString(AppNotification.serializer(), encoded)
        assertEquals(notification, decoded)
    }

    @Test
    fun appNotificationFromSnakeCaseJson() {
        val jsonStr = """
            {
                "id": 42,
                "type": "payment",
                "title": "Payment Received",
                "body": "Payment of $500 received",
                "is_read": true,
                "action_type": "open_invoice",
                "action_id": 99,
                "created_at": "2026-04-10T15:30:00Z"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(AppNotification.serializer(), jsonStr)
        assertEquals(42L, decoded.id)
        assertEquals("payment", decoded.type)
        assertEquals("Payment Received", decoded.title)
        assertEquals("Payment of $500 received", decoded.body)
        assertTrue(decoded.isRead)
        assertEquals("open_invoice", decoded.actionType)
        assertEquals(99L, decoded.actionId)
        assertEquals("2026-04-10T15:30:00Z", decoded.createdAt)
    }

    @Test
    fun appNotificationDefaultIsReadFalse() {
        val jsonStr = """
            {
                "id": 10,
                "type": "alert",
                "title": "Low Stock",
                "body": "Product X is low on stock"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(AppNotification.serializer(), jsonStr)
        assertEquals(10L, decoded.id)
        assertEquals("alert", decoded.type)
        assertEquals("Low Stock", decoded.title)
        assertEquals("Product X is low on stock", decoded.body)
        assertFalse(decoded.isRead)
        assertEquals(null, decoded.actionType)
        assertEquals(null, decoded.actionId)
        assertEquals(null, decoded.createdAt)
    }

    @Test
    fun appNotificationWithNullOptionalFields() {
        val notification = AppNotification(
            id = 5,
            type = null,
            title = null,
            body = null,
            isRead = false,
            actionType = null,
            actionId = null,
            createdAt = null,
        )
        val encoded = json.encodeToString(AppNotification.serializer(), notification)
        val decoded = json.decodeFromString(AppNotification.serializer(), encoded)
        assertEquals(notification, decoded)
    }

    @Test
    fun appNotificationIsReadExplicitlyFalse() {
        val jsonStr = """
            {
                "id": 20,
                "is_read": false
            }
        """.trimIndent()
        val decoded = json.decodeFromString(AppNotification.serializer(), jsonStr)
        assertEquals(20L, decoded.id)
        assertFalse(decoded.isRead)
    }

    @Test
    fun appNotificationIsReadExplicitlyTrue() {
        val jsonStr = """
            {
                "id": 21,
                "is_read": true
            }
        """.trimIndent()
        val decoded = json.decodeFromString(AppNotification.serializer(), jsonStr)
        assertEquals(21L, decoded.id)
        assertTrue(decoded.isRead)
    }
}
