package me.amermahsoub.bfm.shared.data.suppliers

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class SuppliersModelsSerializationTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun supplierRoundtrip() {
        val supplier = Supplier(
            id = 1,
            name = "ABC Supplies",
            phone = "+1234567890",
            email = "info@abc.com",
            address = "123 Main St",
            contactPerson = "John Doe",
            taxNumber = "TAX-999",
            balance = "5000.00",
            isActive = true,
            createdAt = "2026-01-10T12:00:00Z",
        )
        val encoded = json.encodeToString(Supplier.serializer(), supplier)
        val decoded = json.decodeFromString(Supplier.serializer(), encoded)
        assertEquals(supplier, decoded)
    }

    @Test
    fun supplierFromSnakeCaseJson() {
        val jsonStr = """
            {
                "id": 2,
                "name": "XYZ Corp",
                "phone": "+9876543210",
                "email": "contact@xyz.com",
                "address": "456 Oak Ave",
                "contact_person": "Jane Smith",
                "tax_number": "TAX-123",
                "balance": "12000.00",
                "is_active": false,
                "created_at": "2026-02-20T09:00:00Z"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(Supplier.serializer(), jsonStr)
        assertEquals(2L, decoded.id)
        assertEquals("XYZ Corp", decoded.name)
        assertEquals("+9876543210", decoded.phone)
        assertEquals("contact@xyz.com", decoded.email)
        assertEquals("456 Oak Ave", decoded.address)
        assertEquals("Jane Smith", decoded.contactPerson)
        assertEquals("TAX-123", decoded.taxNumber)
        assertEquals("12000.00", decoded.balance)
        assertEquals(false, decoded.isActive)
        assertEquals("2026-02-20T09:00:00Z", decoded.createdAt)
    }

    @Test
    fun supplierCreateRequestRoundtrip() {
        val request = SupplierCreateRequest(
            name = "New Supplier",
            phone = "+1112223333",
            email = "new@supplier.com",
            address = "789 Elm St",
            contactPerson = "Bob",
            taxNumber = "TAX-456",
        )
        val encoded = json.encodeToString(SupplierCreateRequest.serializer(), request)
        val decoded = json.decodeFromString(SupplierCreateRequest.serializer(), encoded)
        assertEquals(request, decoded)
    }

    @Test
    fun supplierCreateRequestFromSnakeCaseJson() {
        val jsonStr = """
            {
                "name": "Quick Parts",
                "phone": null,
                "email": "parts@quick.com",
                "address": null,
                "contact_person": "Alice",
                "tax_number": null
            }
        """.trimIndent()
        val decoded = json.decodeFromString(SupplierCreateRequest.serializer(), jsonStr)
        assertEquals("Quick Parts", decoded.name)
        assertEquals(null, decoded.phone)
        assertEquals("parts@quick.com", decoded.email)
        assertEquals(null, decoded.address)
        assertEquals("Alice", decoded.contactPerson)
        assertEquals(null, decoded.taxNumber)
    }

    @Test
    fun purchaseOrderRoundtrip() {
        val item = PurchaseOrderItem(
            id = 1,
            productId = 10,
            productName = "Steel Rod",
            quantity = 50.0,
            unitCost = "12.00",
            total = "600.00",
        )
        val order = PurchaseOrder(
            id = 100,
            purchaseOrderNumber = "PO-001",
            supplierId = 5,
            supplierName = "Steel Works",
            status = "received",
            total = "600.00",
            paidAmount = "600.00",
            dueAmount = "0.00",
            date = "2026-03-01",
            note = "Urgent",
            items = listOf(item),
            createdAt = "2026-03-01T08:00:00Z",
        )
        val encoded = json.encodeToString(PurchaseOrder.serializer(), order)
        val decoded = json.decodeFromString(PurchaseOrder.serializer(), encoded)
        assertEquals(order, decoded)
    }

    @Test
    fun purchaseOrderFromSnakeCaseJson() {
        val jsonStr = """
            {
                "id": 50,
                "purchase_order_number": "PO-050",
                "supplier_id": 3,
                "supplier_name": "Parts Inc",
                "status": "pending",
                "total": "1200.00",
                "paid_amount": "0.00",
                "due_amount": "1200.00",
                "date": "2026-04-01",
                "note": null,
                "items": [
                    {
                        "id": 10,
                        "product_id": 20,
                        "product_name": "Bolt",
                        "quantity": 200.0,
                        "unit_cost": "0.50",
                        "total": "100.00"
                    }
                ],
                "created_at": "2026-04-01T14:30:00Z"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(PurchaseOrder.serializer(), jsonStr)
        assertEquals(50L, decoded.id)
        assertEquals("PO-050", decoded.purchaseOrderNumber)
        assertEquals(3L, decoded.supplierId)
        assertEquals("Parts Inc", decoded.supplierName)
        assertEquals("pending", decoded.status)
        assertEquals("1200.00", decoded.total)
        assertEquals("0.00", decoded.paidAmount)
        assertEquals("1200.00", decoded.dueAmount)
        assertEquals("2026-04-01", decoded.date)
        assertEquals(null, decoded.note)
        assertEquals(1, decoded.items.size)
        assertEquals("Bolt", decoded.items[0].productName)
        assertEquals("2026-04-01T14:30:00Z", decoded.createdAt)
    }

    @Test
    fun purchaseOrderItemRoundtrip() {
        val item = PurchaseOrderItem(
            id = 5,
            productId = 30,
            productName = "Washer",
            quantity = 1000.0,
            unitCost = "0.10",
            total = "100.00",
        )
        val encoded = json.encodeToString(PurchaseOrderItem.serializer(), item)
        val decoded = json.decodeFromString(PurchaseOrderItem.serializer(), encoded)
        assertEquals(item, decoded)
    }

    @Test
    fun purchaseOrderItemFromSnakeCaseJson() {
        val jsonStr = """
            {
                "id": 3,
                "product_id": 25,
                "product_name": "Screw",
                "quantity": 500.0,
                "unit_cost": "0.05",
                "total": "25.00"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(PurchaseOrderItem.serializer(), jsonStr)
        assertEquals(3L, decoded.id)
        assertEquals(25L, decoded.productId)
        assertEquals("Screw", decoded.productName)
        assertEquals(500.0, decoded.quantity)
        assertEquals("0.05", decoded.unitCost)
        assertEquals("25.00", decoded.total)
    }

    @Test
    fun purchaseOrderWithMultipleItems() {
        val jsonStr = """
            {
                "id": 77,
                "items": [
                    {
                        "id": 1,
                        "product_id": 10,
                        "product_name": "Item A",
                        "quantity": 5.0,
                        "unit_cost": "10.00",
                        "total": "50.00"
                    },
                    {
                        "id": 2,
                        "product_id": 11,
                        "product_name": "Item B",
                        "quantity": 3.0,
                        "unit_cost": "20.00",
                        "total": "60.00"
                    },
                    {
                        "id": 3,
                        "product_id": 12,
                        "product_name": "Item C",
                        "quantity": 1.0,
                        "unit_cost": "100.00",
                        "total": "100.00"
                    }
                ]
            }
        """.trimIndent()
        val decoded = json.decodeFromString(PurchaseOrder.serializer(), jsonStr)
        assertEquals(77L, decoded.id)
        assertEquals(3, decoded.items.size)
        assertEquals("Item A", decoded.items[0].productName)
        assertEquals("Item B", decoded.items[1].productName)
        assertEquals("Item C", decoded.items[2].productName)
    }

    @Test
    fun supplierDefaultValues() {
        val jsonStr = """{"id": 1}"""
        val decoded = json.decodeFromString(Supplier.serializer(), jsonStr)
        assertEquals(1L, decoded.id)
        assertEquals("", decoded.name)
        assertEquals(null, decoded.phone)
        assertEquals(null, decoded.email)
        assertEquals(null, decoded.address)
        assertEquals(null, decoded.contactPerson)
        assertEquals(null, decoded.taxNumber)
        assertEquals(null, decoded.balance)
        assertTrue(decoded.isActive)
        assertEquals(null, decoded.createdAt)
    }
}
