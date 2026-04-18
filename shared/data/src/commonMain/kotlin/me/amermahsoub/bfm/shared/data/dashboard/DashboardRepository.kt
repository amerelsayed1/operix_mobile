package me.amermahsoub.bfm.shared.data.dashboard

import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.domain.common.AppError

data class DashboardData(
    val summary: DashboardSummary?,
    val lowStock: List<DashboardLowStockItem>,
    val recentOrders: List<DashboardRecentOrder>,
    val topProducts: List<DashboardTopProduct>,
    val error: AppError? = null,
)

class DashboardRepository(
    private val api: DashboardApi,
) {
    /**
     * Fetches all dashboard components with best-effort semantics — any single
     * list failing does not abort the rest.
     */
    suspend fun load(): DashboardData {
        val summary = runCatching { api.getSummary() }.getOrNull()
        val lowStock = runCatching { api.getLowStock() }.getOrElse { emptyList() }
        val recent = runCatching { api.getRecentOrders() }.getOrElse { emptyList() }
        val top = runCatching { api.getTopProducts() }.getOrElse { emptyList() }

        val firstError = if (summary == null && lowStock.isEmpty() && recent.isEmpty() && top.isEmpty()) {
            runCatching { api.getSummary() }.exceptionOrNull()?.toAppError()
        } else null

        return DashboardData(
            summary = summary,
            lowStock = lowStock,
            recentOrders = recent,
            topProducts = top,
            error = firstError,
        )
    }
}
