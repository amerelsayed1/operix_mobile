package me.amermahsoub.bfm.shared.data.dashboard

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder

@Serializable
data class DashboardSummary(
    @SerialName("total_balance") val totalBalance: String? = null,
    @SerialName("total_revenue") val totalRevenue: String? = null,
    @SerialName("total_expenses") val totalExpenses: String? = null,
    @SerialName("total_purchases") val totalPurchases: String? = null,
    @SerialName("total_returns") val totalReturns: String? = null,
    @SerialName("returns_count") val returnsCount: Int? = null,
    @SerialName("net_profit") val netProfit: String? = null,
    val currency: String? = null,
)

@Serializable
data class DashboardLowStockItem(
    val id: Long? = null,
    val name: String,
    val sku: String? = null,
    @SerialName("available_qty") val availableQty: Double? = null,
    @SerialName("minimum_qty") val minimumQty: Double? = null,
)

@Serializable
data class DashboardRecentOrder(
    val id: Long? = null,
    @SerialName("receipt_number") val receiptNumber: String? = null,
    val number: String? = null,
    val customer: String? = null,
    val total: String? = null,
    val status: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
) {
    val displayNumber: String get() = receiptNumber ?: number ?: "—"
}

@Serializable
data class DashboardTopProduct(
    val id: Long? = null,
    val name: String,
    val revenue: String? = null,
    @SerialName("units_sold") val unitsSold: Int? = null,
    val category: String? = null,
)

class DashboardApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun getSummary(): DashboardSummary =
        json.decodeData(DashboardSummary.serializer()) { client.get(urls.dashboard()) }

    suspend fun getLowStock(): List<DashboardLowStockItem> =
        json.decodeData(ListSerializer(DashboardLowStockItem.serializer())) {
            client.get(urls.lowStock())
        }

    suspend fun getRecentOrders(): List<DashboardRecentOrder> =
        json.decodeData(ListSerializer(DashboardRecentOrder.serializer())) {
            client.get(urls.recentOrders())
        }

    suspend fun getTopProducts(): List<DashboardTopProduct> =
        json.decodeData(ListSerializer(DashboardTopProduct.serializer())) {
            client.get(urls.dashboardTopProducts())
        }
}
