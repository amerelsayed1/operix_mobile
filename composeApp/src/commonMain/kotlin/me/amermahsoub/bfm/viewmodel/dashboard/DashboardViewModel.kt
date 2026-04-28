package me.amermahsoub.bfm.viewmodel.dashboard

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.DashboardSummary
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.DashboardKpiItem
import me.amermahsoub.bfm.shared.data.tenant.LowStockItem
import me.amermahsoub.bfm.shared.data.tenant.RecentOrderItem
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class DashboardViewModel(
    private val apiService: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val _dashboardState = MutableStateFlow<Result<DashboardSummary>>(Result.Loading)
    val dashboardState: StateFlow<Result<DashboardSummary>> = _dashboardState.asStateFlow()

    private val _recentOrdersState = MutableStateFlow<Result<List<RecentOrderItem>>>(Result.Loading)
    val recentOrdersState: StateFlow<Result<List<RecentOrderItem>>> = _recentOrdersState.asStateFlow()

    private val _lowStockState = MutableStateFlow<Result<List<LowStockItem>>>(Result.Loading)
    val lowStockState: StateFlow<Result<List<LowStockItem>>> = _lowStockState.asStateFlow()

    init {
        loadAll()
    }

    fun refresh() {
        loadAll()
    }

    private fun loadAll() {
        val slug = sessionStore.session.value?.login?.tenant?.slug ?: return
        _dashboardState.load { apiService.getDashboardSummary(slug) }
        _recentOrdersState.load { apiService.getRecentOrders(slug).map {
            RecentOrderItem(
                id = (it["id"]?.toString()?.trim('"')?.toLongOrNull()),
                number = it["receipt_number"]?.toString()?.trim('"'),
                customer = it["client_name"]?.toString()?.trim('"'),
                total = it["grand_total"]?.toString()?.trim('"'),
                status = it["payment_status"]?.toString()?.trim('"'),
            )
        }}
        _lowStockState.load { apiService.getLowStock(slug).map {
            LowStockItem(
                id = it["id"]?.toString()?.trim('"')?.toLongOrNull(),
                name = it["name"]?.toString()?.trim('"') ?: "",
                sku  = it["sku"]?.toString()?.trim('"'),
                availableQty = it["current_stock"]?.toString()?.trim('"')?.toDoubleOrNull(),
                minimumQty   = it["minimum_stock_alert"]?.toString()?.trim('"')?.toDoubleOrNull(),
            )
        }}
    }
}
