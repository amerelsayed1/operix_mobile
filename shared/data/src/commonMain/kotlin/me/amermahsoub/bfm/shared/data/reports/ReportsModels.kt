package me.amermahsoub.bfm.shared.data.reports

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SalesReport(
    @SerialName("total_sales") val totalSales: String? = null,
    @SerialName("total_orders") val totalOrders: Int = 0,
    @SerialName("average_order") val averageOrder: String? = null,
    @SerialName("total_discount") val totalDiscount: String? = null,
    @SerialName("total_tax") val totalTax: String? = null,
    @SerialName("net_sales") val netSales: String? = null,
)

@Serializable
data class SalesTrendPoint(
    val date: String,
    val total: String? = null,
    val count: Int = 0,
)

@Serializable
data class TopProductReport(
    val id: Long? = null,
    val name: String = "",
    @SerialName("units_sold") val unitsSold: Int = 0,
    val revenue: String? = null,
    val category: String? = null,
)

@Serializable
data class ExpenseReport(
    @SerialName("total_expenses") val totalExpenses: String? = null,
    @SerialName("by_category") val byCategory: List<ExpenseCategoryBreakdown> = emptyList(),
)

@Serializable
data class ExpenseCategoryBreakdown(
    val category: String = "",
    val total: String? = null,
    val count: Int = 0,
    val percentage: Double = 0.0,
)

@Serializable
data class ProfitReport(
    @SerialName("total_revenue") val totalRevenue: String? = null,
    @SerialName("total_expenses") val totalExpenses: String? = null,
    @SerialName("gross_profit") val grossProfit: String? = null,
    @SerialName("net_profit") val netProfit: String? = null,
    @SerialName("profit_margin") val profitMargin: Double? = null,
)

@Serializable
data class ClientReport(
    @SerialName("total_clients") val totalClients: Int = 0,
    @SerialName("new_clients") val newClients: Int = 0,
    @SerialName("total_receivables") val totalReceivables: String? = null,
    @SerialName("total_collected") val totalCollected: String? = null,
)
