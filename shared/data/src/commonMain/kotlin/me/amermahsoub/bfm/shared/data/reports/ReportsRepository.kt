package me.amermahsoub.bfm.shared.data.reports

class ReportsRepository(private val api: ReportsApi) {
    suspend fun salesReport(from: String? = null, to: String? = null) = api.salesReport(from, to)
    suspend fun salesTrend(from: String? = null, to: String? = null) = api.salesTrend(from, to)
    suspend fun topProducts(from: String? = null, to: String? = null) = api.topProducts(from, to)
    suspend fun expenseReport(from: String? = null, to: String? = null) = api.expenseReport(from, to)
    suspend fun profitReport(from: String? = null, to: String? = null) = api.profitReport(from, to)
    suspend fun clientReport(from: String? = null, to: String? = null) = api.clientReport(from, to)
}
