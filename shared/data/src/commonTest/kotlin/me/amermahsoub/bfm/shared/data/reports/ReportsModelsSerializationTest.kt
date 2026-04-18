package me.amermahsoub.bfm.shared.data.reports

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals

class ReportsModelsSerializationTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun salesReportRoundtrip() {
        val report = SalesReport(
            totalSales = "5000.00",
            totalOrders = 42,
            averageOrder = "119.05",
            totalDiscount = "200.00",
            totalTax = "450.00",
            netSales = "4350.00",
        )
        val encoded = json.encodeToString(SalesReport.serializer(), report)
        val decoded = json.decodeFromString(SalesReport.serializer(), encoded)
        assertEquals(report, decoded)
    }

    @Test
    fun salesReportFromSnakeCaseJson() {
        val jsonStr = """
            {
                "total_sales": "1000.00",
                "total_orders": 10,
                "average_order": "100.00",
                "total_discount": "50.00",
                "total_tax": "90.00",
                "net_sales": "860.00"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(SalesReport.serializer(), jsonStr)
        assertEquals("1000.00", decoded.totalSales)
        assertEquals(10, decoded.totalOrders)
        assertEquals("100.00", decoded.averageOrder)
        assertEquals("50.00", decoded.totalDiscount)
        assertEquals("90.00", decoded.totalTax)
        assertEquals("860.00", decoded.netSales)
    }

    @Test
    fun salesTrendPointRoundtrip() {
        val point = SalesTrendPoint(
            date = "2026-01-15",
            total = "300.00",
            count = 5,
        )
        val encoded = json.encodeToString(SalesTrendPoint.serializer(), point)
        val decoded = json.decodeFromString(SalesTrendPoint.serializer(), encoded)
        assertEquals(point, decoded)
    }

    @Test
    fun salesTrendPointFromJson() {
        val jsonStr = """{"date":"2026-03-01","total":"750.00","count":12}"""
        val decoded = json.decodeFromString(SalesTrendPoint.serializer(), jsonStr)
        assertEquals("2026-03-01", decoded.date)
        assertEquals("750.00", decoded.total)
        assertEquals(12, decoded.count)
    }

    @Test
    fun topProductReportRoundtrip() {
        val report = TopProductReport(
            id = 99,
            name = "Widget",
            unitsSold = 200,
            revenue = "4000.00",
            category = "Electronics",
        )
        val encoded = json.encodeToString(TopProductReport.serializer(), report)
        val decoded = json.decodeFromString(TopProductReport.serializer(), encoded)
        assertEquals(report, decoded)
    }

    @Test
    fun topProductReportFromSnakeCaseJson() {
        val jsonStr = """
            {
                "id": 1,
                "name": "Gadget",
                "units_sold": 50,
                "revenue": "1500.00",
                "category": "Tools"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(TopProductReport.serializer(), jsonStr)
        assertEquals(1L, decoded.id)
        assertEquals("Gadget", decoded.name)
        assertEquals(50, decoded.unitsSold)
        assertEquals("1500.00", decoded.revenue)
        assertEquals("Tools", decoded.category)
    }

    @Test
    fun expenseReportRoundtrip() {
        val breakdown = ExpenseCategoryBreakdown(
            category = "Rent",
            total = "2000.00",
            count = 1,
            percentage = 40.0,
        )
        val report = ExpenseReport(
            totalExpenses = "5000.00",
            byCategory = listOf(breakdown),
        )
        val encoded = json.encodeToString(ExpenseReport.serializer(), report)
        val decoded = json.decodeFromString(ExpenseReport.serializer(), encoded)
        assertEquals(report, decoded)
    }

    @Test
    fun expenseReportFromSnakeCaseJson() {
        val jsonStr = """
            {
                "total_expenses": "3000.00",
                "by_category": [
                    {
                        "category": "Utilities",
                        "total": "500.00",
                        "count": 3,
                        "percentage": 16.67
                    }
                ]
            }
        """.trimIndent()
        val decoded = json.decodeFromString(ExpenseReport.serializer(), jsonStr)
        assertEquals("3000.00", decoded.totalExpenses)
        assertEquals(1, decoded.byCategory.size)
        assertEquals("Utilities", decoded.byCategory[0].category)
        assertEquals("500.00", decoded.byCategory[0].total)
        assertEquals(3, decoded.byCategory[0].count)
        assertEquals(16.67, decoded.byCategory[0].percentage)
    }

    @Test
    fun expenseCategoryBreakdownRoundtrip() {
        val breakdown = ExpenseCategoryBreakdown(
            category = "Salaries",
            total = "10000.00",
            count = 5,
            percentage = 60.0,
        )
        val encoded = json.encodeToString(ExpenseCategoryBreakdown.serializer(), breakdown)
        val decoded = json.decodeFromString(ExpenseCategoryBreakdown.serializer(), encoded)
        assertEquals(breakdown, decoded)
    }

    @Test
    fun profitReportRoundtrip() {
        val report = ProfitReport(
            totalRevenue = "20000.00",
            totalExpenses = "15000.00",
            grossProfit = "8000.00",
            netProfit = "5000.00",
            profitMargin = 25.0,
        )
        val encoded = json.encodeToString(ProfitReport.serializer(), report)
        val decoded = json.decodeFromString(ProfitReport.serializer(), encoded)
        assertEquals(report, decoded)
    }

    @Test
    fun profitReportFromSnakeCaseJson() {
        val jsonStr = """
            {
                "total_revenue": "10000.00",
                "total_expenses": "7000.00",
                "gross_profit": "4000.00",
                "net_profit": "3000.00",
                "profit_margin": 30.0
            }
        """.trimIndent()
        val decoded = json.decodeFromString(ProfitReport.serializer(), jsonStr)
        assertEquals("10000.00", decoded.totalRevenue)
        assertEquals("7000.00", decoded.totalExpenses)
        assertEquals("4000.00", decoded.grossProfit)
        assertEquals("3000.00", decoded.netProfit)
        assertEquals(30.0, decoded.profitMargin)
    }

    @Test
    fun clientReportRoundtrip() {
        val report = ClientReport(
            totalClients = 100,
            newClients = 15,
            totalReceivables = "25000.00",
            totalCollected = "20000.00",
        )
        val encoded = json.encodeToString(ClientReport.serializer(), report)
        val decoded = json.decodeFromString(ClientReport.serializer(), encoded)
        assertEquals(report, decoded)
    }

    @Test
    fun clientReportFromSnakeCaseJson() {
        val jsonStr = """
            {
                "total_clients": 50,
                "new_clients": 8,
                "total_receivables": "12000.00",
                "total_collected": "9500.00"
            }
        """.trimIndent()
        val decoded = json.decodeFromString(ClientReport.serializer(), jsonStr)
        assertEquals(50, decoded.totalClients)
        assertEquals(8, decoded.newClients)
        assertEquals("12000.00", decoded.totalReceivables)
        assertEquals("9500.00", decoded.totalCollected)
    }
}
