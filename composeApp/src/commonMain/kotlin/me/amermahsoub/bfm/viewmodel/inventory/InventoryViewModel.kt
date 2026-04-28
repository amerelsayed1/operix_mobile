package me.amermahsoub.bfm.viewmodel.inventory

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.Inventory
import me.amermahsoub.bfm.shared.data.models.InventoryProduct
import me.amermahsoub.bfm.shared.data.models.PaginatedResponse
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.StockMovement
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class InventoryViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    // ── Inventories list ──────────────────────────────────────────────────

    private val _inventoriesState = MutableStateFlow<Result<List<Inventory>>>(Result.Loading)
    val inventoriesState: StateFlow<Result<List<Inventory>>> = _inventoriesState.asStateFlow()

    private val _selectedInventory = MutableStateFlow<Inventory?>(null)
    val selectedInventory: StateFlow<Inventory?> = _selectedInventory.asStateFlow()

    // ── Stock levels ──────────────────────────────────────────────────────

    private val _stockState = MutableStateFlow<Result<PaginatedResponse<InventoryProduct>>>(Result.Loading)
    val stockState: StateFlow<Result<PaginatedResponse<InventoryProduct>>> = _stockState.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _showLowStockOnly = MutableStateFlow(false)
    val showLowStockOnly: StateFlow<Boolean> = _showLowStockOnly.asStateFlow()

    // ── Movements ─────────────────────────────────────────────────────────

    private val _movementsState = MutableStateFlow<Result<PaginatedResponse<StockMovement>>>(Result.Loading)
    val movementsState: StateFlow<Result<PaginatedResponse<StockMovement>>> = _movementsState.asStateFlow()

    init {
        loadInventories()
    }

    fun loadInventories() {
        _inventoriesState.load {
            val list = api.getInventories(slug)
            if (_selectedInventory.value == null) {
                _selectedInventory.value = list.firstOrNull { it.isDefault } ?: list.firstOrNull()
                _selectedInventory.value?.let { loadStock() }
            }
            list
        }
    }

    fun selectInventory(inventory: Inventory) {
        _selectedInventory.value = inventory
        loadStock()
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    fun setLowStockFilter(enabled: Boolean) {
        _showLowStockOnly.value = enabled
    }

    fun loadStock(
        search: String? = _searchQuery.value.takeIf { it.isNotBlank() },
        lowStockOnly: Boolean = _showLowStockOnly.value,
        page: Int = 1,
    ) {
        val inventoryId = _selectedInventory.value?.id ?: return
        _stockState.load {
            api.getInventoryProducts(slug, inventoryId, search, lowStockOnly.takeIf { it }, page)
        }
    }

    fun loadMovements(
        productId: Int? = null,
        type: String? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
    ) {
        val inventoryId = _selectedInventory.value?.id
        _movementsState.load {
            api.getStockMovements(slug, inventoryId, productId, type, fromDate, toDate, page)
        }
    }
}
