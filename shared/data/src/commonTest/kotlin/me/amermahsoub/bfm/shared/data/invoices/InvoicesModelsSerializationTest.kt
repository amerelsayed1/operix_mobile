package me.amermahsoub.bfm.shared.data.invoices

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals

class InvoicesModelsSerializationTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun invoiceRoundtrip() {
        val item = InvoiceItem(
            id = 1,
            productId = 10,
            productName = "Widget",
            quantity = 3.0,
            unitPrice = "25.00",
            total = "75.00",
        )
        val invoice = Invoice(
            id = 100,
            invoiceNumber = "INV-001",
            orderId = 50,
            clientId = 20,
            clientName = "Acme Corp",
            status = "paid",
            subtotal = "150.00",
            discount = "10.00",
            tax = "14.00",
            total = "154.00",
            paidAmount = "154.00",
            dueAmount = "0.00",
            issueDate = "2026-01-01",
            dueDate = "2026-02-01",
            note = "Thank you",
            items = listOf(item),
            createdAt = "2026-01-01T10:00:00Z",
        )
        val encoded = json.encodeToString(Invoice.serializer(), invoice)
        val decoded = json.decodeFromString(Invoice.serializer(), encoded)
        assertEquals(invoice, decoded)
    }

    @Test
    fun invoiceFromSnakeCaseJson() {
        val jsonStr = """
            {
                "id": 1,
                "invoice_number": "INV-100",
                "order_id": 5,
                "client_id": 3,
                "client_name": "Test Client",
                "status": "pending",
                "subtotal": "500.00",
                "discount": "0.00",
                "tax": "50.00",
                "total": "550.00",
                "paid_amount": "0.00",
                "due_amount": "550.00",
                "issue_date": "2026-03-15",
                "due_date": "2026-04-15",
                "note": null,
                "items": [],
                "created_at": "2026-03-15T08:30:00Z"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(Invoice.serializer(), jsonStr)
        assertEquals(1L, decoded.id)
        assertEquals("INV-100", decoded.invoiceNumber)
        assertEquals(5L, decoded.orderId)
        assertEquals(3L, decoded.clientId)
        assertEquals("Test Client", decoded.clientName)
        assertEquals("pending", decoded.status)
        assertEquals("500.00", decoded.subtotal)
        assertEquals("0.00", decoded.discount)
        assertEquals("50.00", decoded.tax)
        assertEquals("550.00", decoded.total)
        assertEquals("0.00", decoded.paidAmount)
        assertEquals("550.00", decoded.dueAmount)
        assertEquals("2026-03-15", decoded.issueDate)
        assertEquals("2026-04-15", decoded.dueDate)
        assertEquals(null, decoded.note)
        assertEquals(0, decoded.items.size)
        assertEquals("2026-03-15T08:30:00Z", decoded.createdAt)
    }

    @Test
    fun invoiceItemRoundtrip() {
        val item = InvoiceItem(
            id = 7,
            productId = 42,
            productName = "Bolt",
            quantity = 100.0,
            unitPrice = "0.50",
            total = "50.00",
        )
        val encoded = json.encodeToString(InvoiceItem.serializer(), item)
        val decoded = json.decodeFromString(InvoiceItem.serializer(), encoded)
        assertEquals(item, decoded)
    }

    @Test
    fun invoiceItemFromSnakeCaseJson() {
        val jsonStr = """
            {
                "id": 2,
                "product_id": 15,
                "product_name": "Nut",
                "quantity": 50.0,
                "unit_price": "0.25",
                "total": "12.50"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(InvoiceItem.serializer(), jsonStr)
        assertEquals(2L, decoded.id)
        assertEquals(15L, decoded.productId)
        assertEquals("Nut", decoded.productName)
        assertEquals(50.0, decoded.quantity)
        assertEquals("0.25", decoded.unitPrice)
        assertEquals("12.50", decoded.total)
    }

    @Test
    fun invoiceCreateRequestRoundtrip() {
        val request = InvoiceCreateRequest(
            orderId = 10,
            clientId = 5,
            dueDate = "2026-06-01",
            note = "Rush order",
        )
        val encoded = json.encodeToString(InvoiceCreateRequest.serializer(), request)
        val decoded = json.decodeFromString(InvoiceCreateRequest.serializer(), encoded)
        assertEquals(request, decoded)
    }

    @Test
    fun invoiceCreateRequestFromSnakeCaseJson() {
        val jsonStr = """
            {
                "order_id": 20,
                "client_id": 8,
                "due_date": "2026-07-01",
                "note": "Net 30"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(InvoiceCreateRequest.serializer(), jsonStr)
        assertEquals(20L, decoded.orderId)
        assertEquals(8L, decoded.clientId)
        assertEquals("2026-07-01", decoded.dueDate)
        assertEquals("Net 30", decoded.note)
    }

    @Test
    fun invoiceWithNestedItems() {
        val jsonStr = """
            {
                "id": 99,
                "invoice_number": "INV-099",
                "items": [
                    {
                        "id": 1,
                        "product_id": 10,
                        "product_name": "A",
                        "quantity": 2.0,
                        "unit_price": "10.00",
                        "total": "20.00"
                    },
                    {
                        "id": 2,
                        "product_id": 11,
                        "product_name": "B",
                        "quantity": 1.0,
                        "unit_price": "30.00",
                        "total": "30.00"
                    }
                ]
            }
        """.trimIndent()
        val decoded = json.decodeFromString(Invoice.serializer(), jsonStr)
        assertEquals(99L, decoded.id)
        assertEquals(2, decoded.items.size)
        assertEquals("A", decoded.items[0].productName)
        assertEquals("B", decoded.items[1].productName)
        assertEquals(2.0, decoded.items[0].quantity)
        assertEquals(1.0, decoded.items[1].quantity)
    }
}
