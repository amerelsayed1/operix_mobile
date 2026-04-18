package me.amermahsoub.bfm.shared.data.reports

import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.common.decodeData
import me.amermahsoub.bfm.shared.data.tenant.TenantAwareApiUrlBuilder

class ReportsApi(
    private val client: HttpClient,
    private val urls: TenantAwareApiUrlBuilder,
    private val json: Json,
) {
    suspend fun salesReport(from: String? = null, to: String? = null): SalesReport =
        json.decodeData(SalesReport.serializer()) {
            client.get(urls.reportsSales()) {
                from?.let { parameter("from", it) }
                to?.let { parameter("to", it) }
            }
        }

    suspend fun salesTrend(from: String? = null, to: String? = null): List<SalesTrendPoint> =
        json.decodeData(kotlinx.serialization.builtins.ListSerializer(SalesTrendPoint.serializer())) {
            client.get(urls.reportsSalesTrend()) {
                from?.let { parameter("from", it) }
                to?.let { parameter("to", it) }
            }
        }

    suspend fun topProducts(from: String? = null, to: String? = null, limit: Int = 10): List<TopProductReport> =
        json.decodeData(kotlinx.serialization.builtins.ListSerializer(TopProductReport.serializer())) {
            client.get(urls.reportsTopProducts()) {
                from?.let { parameter("from", it) }
                to?.let { parameter("to", it) }
                parameter("limit", limit)
            }
        }

    suspend fun expenseReport(from: String? = null, to: String? = null): ExpenseReport =
        json.decodeData(ExpenseReport.serializer()) {
            client.get(urls.reportsExpenses()) {
                from?.let { parameter("from", it) }
                to?.let { parameter("to", it) }
            }
        }

    suspend fun profitReport(from: String? = null, to: String? = null): ProfitReport =
        json.decodeData(ProfitReport.serializer()) {
            client.get(urls.reportsProfit()) {
                from?.let { parameter("from", it) }
                to?.let { parameter("to", it) }
            }
        }

    suspend fun clientReport(from: String? = null, to: String? = null): ClientReport =
        json.decodeData(ClientReport.serializer()) {
            client.get(urls.reportsClients()) {
                from?.let { parameter("from", it) }
                to?.let { parameter("to", it) }
            }
        }
}
