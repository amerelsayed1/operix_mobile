package me.amermahsoub.bfm.viewmodel.pos

// Koin module dependency chain (register in your appModule or posModule):
//   single { PosViewModel(get(), get()) }
// where the two dependencies are OperixApiService and SessionStore.
// Inject into Composables via koinInject<PosViewModel>().

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.BarcodeProduct
import me.amermahsoub.bfm.shared.data.models.CartItem
import me.amermahsoub.bfm.shared.data.models.CloseShiftRequest
import me.amermahsoub.bfm.shared.data.models.CreatePosOrderItemRequest
import me.amermahsoub.bfm.shared.data.models.CreatePosOrderPaymentRequest
import me.amermahsoub.bfm.shared.data.models.CreatePosOrderRequest
import me.amermahsoub.bfm.shared.data.models.Inventory
import me.amermahsoub.bfm.shared.data.models.OpenShiftRequest
import me.amermahsoub.bfm.shared.data.models.PaymentMethod
import me.amermahsoub.bfm.shared.data.models.PosOrder
import me.amermahsoub.bfm.shared.data.models.PosTerminal
import me.amermahsoub.bfm.shared.data.models.Product
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Shift
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class PosViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    // ── Terminals ─────────────────────────────────────────────────────────

    private val _terminals = MutableStateFlow<Result<List<PosTerminal>>>(Result.Loading)
    val terminals: StateFlow<Result<List<PosTerminal>>> = _terminals.asStateFlow()

    fun loadTerminals() {
        _terminals.load { api.getPosTerminals(slug) }
    }

    // ── Current shift ─────────────────────────────────────────────────────

    private val _currentShift = MutableStateFlow<Shift?>(null)
    val currentShift: StateFlow<Shift?> = _currentShift.asStateFlow()

    fun loadCurrentShift(terminalId: Int) {
        launch {
            _currentShift.value = api.getCurrentShift(slug, terminalId)
        }
    }

    fun openShift(terminalId: Int, openingCash: Double, notes: String?) {
        launch {
            val shift = api.openShift(slug, OpenShiftRequest(terminalId, openingCash, notes))
            _currentShift.value = shift
        }
    }

    fun closeShift(shiftId: Int, closingCash: Double, notes: String?) {
        launch {
            val shift = api.closeShift(slug, shiftId, CloseShiftRequest(closingCash, notes))
            _currentShift.value = shift
        }
    }

    // ── Inventories & payment methods ─────────────────────────────────────

    private val _inventories = MutableStateFlow<List<Inventory>>(emptyList())
    val inventories: StateFlow<List<Inventory>> = _inventories.asStateFlow()

    private val _paymentMethods = MutableStateFlow<List<PaymentMethod>>(emptyList())
    val paymentMethods: StateFlow<List<PaymentMethod>> = _paymentMethods.asStateFlow()

    private val _selectedInventoryId = MutableStateFlow<Int?>(null)
    val selectedInventoryId: StateFlow<Int?> = _selectedInventoryId.asStateFlow()

    fun loadSupportingData() {
        launch {
            _inventories.value = runCatching { api.getInventories(slug) }.getOrDefault(emptyList())
            _paymentMethods.value = runCatching { api.getPaymentMethods(slug) }.getOrDefault(emptyList())
            if (_selectedInventoryId.value == null) {
                _selectedInventoryId.value = _inventories.value.firstOrNull()?.id
            }
        }
    }

    fun setInventory(inventoryId: Int) {
        _selectedInventoryId.value = inventoryId
    }

    // ── Cart ──────────────────────────────────────────────────────────────

    private val _cart = MutableStateFlow<List<CartItem>>(emptyList())
    val cart: StateFlow<List<CartItem>> = _cart.asStateFlow()

    val cartSubtotal: Double
        get() = _cart.value.sumOf { it.lineTotal }

    val cartTax: Double
        get() = 0.0 // Tax is handled server-side; expose 0 locally unless tenant config provides rate

    val cartTotal: Double
        get() = cartSubtotal + cartTax

    fun addToCart(product: Product, quantity: Double, unitPrice: Double) {
        val current = _cart.value.toMutableList()
        val existing = current.indexOfFirst { it.productId == product.id && it.variantId == null }
        if (existing >= 0) {
            val item = current[existing]
            current[existing] = item.copy(quantity = item.quantity + quantity)
        } else {
            current.add(
                CartItem(
                    productId = product.id,
                    variantId = null,
                    name = product.name,
                    unitPrice = unitPrice,
                    quantity = quantity,
                    imageUrl = product.imageUrl,
                ),
            )
        }
        _cart.value = current
    }

    fun removeFromCart(productId: Int, variantId: Int? = null) {
        _cart.value = _cart.value.filter { !(it.productId == productId && it.variantId == variantId) }
    }

    fun updateCartItemQty(productId: Int, variantId: Int?, quantity: Double) {
        if (quantity <= 0.0) {
            removeFromCart(productId, variantId)
            return
        }
        _cart.value = _cart.value.map { item ->
            if (item.productId == productId && item.variantId == variantId) item.copy(quantity = quantity) else item
        }
    }

    fun clearCart() {
        _cart.value = emptyList()
    }

    // ── Checkout ──────────────────────────────────────────────────────────

    suspend fun checkout(
        shiftId: Int,
        payments: List<CreatePosOrderPaymentRequest>,
        discount: Double = 0.0,
        notes: String? = null,
    ): Result<PosOrder> {
        val inventoryId = _selectedInventoryId.value
            ?: return Result.Error("No inventory selected")
        val items = _cart.value.map { cartItem ->
            CreatePosOrderItemRequest(
                productId = cartItem.productId,
                variantId = cartItem.variantId,
                quantity = cartItem.quantity,
                unitPrice = cartItem.unitPrice,
                discount = cartItem.discount,
            )
        }
        if (items.isEmpty()) return Result.Error("Cart is empty")

        return try {
            val order = api.createPosOrder(
                slug,
                CreatePosOrderRequest(
                    shiftId = shiftId,
                    inventoryId = inventoryId,
                    items = items,
                    payments = payments,
                    discount = discount,
                    notes = notes,
                ),
            )
            clearCart()
            Result.Success(order)
        } catch (e: Exception) {
            Result.Error(e.message ?: "Checkout failed")
        }
    }

    // ── Product search & barcode ──────────────────────────────────────────

    suspend fun searchProducts(query: String): List<Product> =
        runCatching { api.searchPosProducts(slug, query, _selectedInventoryId.value) }
            .getOrDefault(emptyList())

    suspend fun lookupBarcode(barcode: String): BarcodeProduct? =
        runCatching { api.lookupBarcode(slug, barcode, _selectedInventoryId.value) }
            .getOrNull()
}
