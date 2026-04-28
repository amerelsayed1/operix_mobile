package me.amermahsoub.bfm.viewmodel.dashboard

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.decodeFromJsonElement
import me.amermahsoub.bfm.shared.data.api.OperixApiService
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

    private val _dashboardState = MutableStateFlow<Result<List<DashboardKpiItem>>>(Result.Loading)
    val dashboardState: StateFlow<Result<List<DashboardKpiItem>>> = _dashboardState.asStateFlow()

    private val _recentOrdersState = MutableStateFlow<Result<List<RecentOrderItem>>>(Result.Loading)
    val recentOrdersState: StateFlow<Result<List<RecentOrderItem>>> = _recentOrdersState.asStateFlow()

    private val _lowStockState = MutableStateFlow<Result<List<LowStockItem>>>(Result.Loading)
    val lowStockState: StateFlow<Result<List<LowStockItem>>> = _lowStockState.asStateFlow()

    private val json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
        isLenient = true
    }

    init {
        loadAll()
    }

    fun refresh() {
        loadAll()
    }

    private fun loadAll() {
        val slug = sessionStore.session.value?.login?.tenant?.slug ?: return

        launch {
            _dashboardState.value = Result.Loading
            _recentOrdersState.value = Result.Loading
            _lowStockState.value = Result.Loading

            try {
                val rawJson = apiService.getDashboard(slug)

                // Decode KPI items
                _dashboardState.value = try {
                    val dataEl = rawJson["data"] ?: rawJson["items"] ?: rawJson
                    Result.Success(json.decodeFromJsonElement<List<DashboardKpiItem>>(dataEl))
                } catch (e: Exception) {
                    Result.Error(e.message ?: "Failed to parse KPI data")
                }

                // Decode recent orders
                _recentOrdersState.value = try {
                    val ordersEl = rawJson["recent_orders"]
                    if (ordersEl != null) {
                        Result.Success(json.decodeFromJsonElement<List<RecentOrderItem>>(ordersEl))
                    } else {
                        Result.Success(emptyList())
                    }
                } catch (e: Exception) {
                    Result.Error(e.message ?: "Failed to parse recent orders")
                }

                // Decode low stock items
                _lowStockState.value = try {
                    val lowStockEl = rawJson["low_stock"]
                    if (lowStockEl != null) {
                        Result.Success(json.decodeFromJsonElement<List<LowStockItem>>(lowStockEl))
                    } else {
                        Result.Success(emptyList())
                    }
                } catch (e: Exception) {
                    Result.Error(e.message ?: "Failed to parse low stock data")
                }
            } catch (e: Exception) {
                val errorMessage = e.message ?: "Failed to load dashboard"
                _dashboardState.value = Result.Error(errorMessage)
                _recentOrdersState.value = Result.Error(errorMessage)
                _lowStockState.value = Result.Error(errorMessage)
            }
        }
    }
}
