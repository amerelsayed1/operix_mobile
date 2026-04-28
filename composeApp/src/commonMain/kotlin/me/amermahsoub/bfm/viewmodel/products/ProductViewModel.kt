package me.amermahsoub.bfm.viewmodel.products

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.PaginatedResponse
import me.amermahsoub.bfm.shared.data.models.Product
import me.amermahsoub.bfm.shared.data.models.ProductCategory
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Unit
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class ProductViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    private val _productsState = MutableStateFlow<Result<PaginatedResponse<Product>>>(Result.Loading)
    val productsState: StateFlow<Result<PaginatedResponse<Product>>> = _productsState.asStateFlow()

    private val _productDetail = MutableStateFlow<Result<Product>>(Result.Loading)
    val productDetail: StateFlow<Result<Product>> = _productDetail.asStateFlow()

    private val _categories = MutableStateFlow<List<ProductCategory>>(emptyList())
    val categories: StateFlow<List<ProductCategory>> = _categories.asStateFlow()

    private val _units = MutableStateFlow<List<Unit>>(emptyList())
    val units: StateFlow<List<Unit>> = _units.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    var currentPage: Int = 1
        private set

    fun loadProducts(search: String? = null, categoryId: Int? = null, page: Int = 1) {
        currentPage = page
        if (search != null) _searchQuery.value = search
        _productsState.load { api.getProducts(slug, search ?: _searchQuery.value.ifBlank { null }, categoryId, null, page) }
    }

    fun loadProducts(search: String? = null, categoryId: Int? = null, isActive: Boolean? = null, page: Int = 1) {
        currentPage = page
        if (search != null) _searchQuery.value = search
        _productsState.load { api.getProducts(slug, search ?: _searchQuery.value.ifBlank { null }, categoryId, isActive, page) }
    }

    fun loadProduct(id: Int) {
        _productDetail.load { api.getProduct(slug, id) }
    }

    fun loadCategories() {
        launch {
            try {
                _categories.value = api.getProductCategories(slug)
            } catch (_: Exception) {
                // silently ignore — categories are optional
            }
        }
    }

    fun loadUnits() {
        launch {
            try {
                _units.value = api.getUnits(slug)
            } catch (_: Exception) {
                // silently ignore — units are optional
            }
        }
    }

    suspend fun createProduct(
        name: String,
        sku: String,
        categoryId: Int,
        unitId: Int,
        costPrice: Double,
        sellingPrice: Double,
        barcode: String? = null,
        isActive: Boolean = true,
        minimumStockAlert: Int = 0,
    ): Result<Product> = try {
        val body = buildMap<String, Any?> {
            put("name", name)
            put("sku", sku)
            put("product_category_id", categoryId)
            put("unit_id", unitId)
            put("cost_price", costPrice)
            put("selling_price", sellingPrice)
            put("is_active", isActive)
            put("minimum_stock_alert", minimumStockAlert)
            if (!barcode.isNullOrBlank()) put("barcode", barcode)
        }
        Result.Success(api.createProduct(slug, body))
    } catch (e: Exception) {
        Result.Error(e.message ?: "Failed to create product")
    }

    suspend fun updateProduct(id: Int, updates: Map<String, Any?>): Result<Product> = try {
        Result.Success(api.updateProduct(slug, id, updates))
    } catch (e: Exception) {
        Result.Error(e.message ?: "Failed to update product")
    }

    suspend fun deleteProduct(id: Int): Result<kotlin.Unit> = try {
        api.deleteProduct(slug, id)
        Result.Success(kotlin.Unit)
    } catch (e: Exception) {
        Result.Error(e.message ?: "Failed to delete product")
    }

    suspend fun createCategory(nameEn: String, nameAr: String? = null): Result<ProductCategory> = try {
        val cat = api.createProductCategory(slug, nameEn, nameAr)
        _categories.value = _categories.value + cat
        Result.Success(cat)
    } catch (e: Exception) {
        Result.Error(e.message ?: "Failed to create category")
    }

    suspend fun createUnit(nameEn: String, nameAr: String? = null): Result<Unit> = try {
        val unit = api.createUnit(slug, nameEn, nameAr)
        _units.value = _units.value + unit
        Result.Success(unit)
    } catch (e: Exception) {
        Result.Error(e.message ?: "Failed to create unit")
    }
}
