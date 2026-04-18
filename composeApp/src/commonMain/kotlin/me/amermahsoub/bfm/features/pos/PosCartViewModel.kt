package me.amermahsoub.bfm.features.pos

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.time.Clock
import kotlin.time.ExperimentalTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import me.amermahsoub.bfm.app.ui.FeatureViewModel
import me.amermahsoub.bfm.shared.data.common.toAppError
import me.amermahsoub.bfm.shared.data.pos.PaymentMethodDto
import me.amermahsoub.bfm.shared.data.pos.PosAccountDto
import me.amermahsoub.bfm.shared.data.pos.PosOrderCreateRequest
import me.amermahsoub.bfm.shared.data.pos.PosOrderItemRequest
import me.amermahsoub.bfm.shared.data.pos.PosProduct
import me.amermahsoub.bfm.shared.data.pos.PosReferenceData
import me.amermahsoub.bfm.shared.data.pos.PosRepository
import me.amermahsoub.bfm.shared.data.pos.Shift
import me.amermahsoub.bfm.shared.data.pos.TaxDto
import me.amermahsoub.bfm.shared.domain.common.AppError

data class CartLine(
    val product: PosProduct,
    val quantity: Double,
) {
    val unitPrice: Double = product.displayPrice.toDoubleOrNull() ?: 0.0
    val lineTotal: Double = unitPrice * quantity
}

data class PosCartUiState(
    val loading: Boolean = true,
    val error: AppError? = null,
    val shift: Shift? = null,
    val reference: PosReferenceData = PosReferenceData(emptyList(), emptyList(), emptyList(), emptyList()),
    val searchQuery: String = "",
    val searchResults: List<PosProduct> = emptyList(),
    val searching: Boolean = false,
    val lines: List<CartLine> = emptyList(),
    val selectedPaymentMethod: PaymentMethodDto? = null,
    val selectedAccount: PosAccountDto? = null,
    val selectedTax: TaxDto? = null,
    val discountValue: Double = 0.0,
    val inventoryId: Long? = null,
    val submitting: Boolean = false,
    val submittedOrderId: Long? = null,
) {
    val subtotal: Double get() = lines.sumOf { it.lineTotal }
    val taxTotal: Double get() = selectedTax?.rate?.let { subtotal * (it / 100.0) } ?: 0.0
    val grandTotal: Double get() = (subtotal - discountValue).coerceAtLeast(0.0) + taxTotal
    val canCheckout: Boolean get() = lines.isNotEmpty() &&
        selectedPaymentMethod != null &&
        shift?.status == "open" &&
        !submitting
}

class PosCartViewModel(
    private val repository: PosRepository,
    private val defaultInventoryId: Long?,
) : FeatureViewModel() {

    private val _state = MutableStateFlow(PosCartUiState(inventoryId = defaultInventoryId))
    val state = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        scope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            try {
                val shift = runCatching { repository.currentShift() }.getOrNull()
                val reference = repository.loadReferenceData()
                val defaultPm = reference.paymentMethods.firstOrNull { it.code == "cash" }
                    ?: reference.paymentMethods.firstOrNull()
                val defaultAccount = reference.accounts.firstOrNull { it.isDrawer }
                    ?: reference.accounts.firstOrNull()
                _state.value = _state.value.copy(
                    loading = false,
                    shift = shift,
                    reference = reference,
                    searchResults = reference.products,
                    selectedPaymentMethod = defaultPm,
                    selectedAccount = defaultAccount,
                )
            } catch (e: Throwable) {
                _state.value = _state.value.copy(loading = false, error = e.toAppError())
            }
        }
    }

    fun updateSearch(q: String) {
        _state.value = _state.value.copy(searchQuery = q)
        scope.launch {
            _state.value = _state.value.copy(searching = true)
            val results = repository.searchProducts(q)
            _state.value = _state.value.copy(searchResults = results, searching = false)
        }
    }

    fun searchByBarcode(barcode: String) {
        _state.value = _state.value.copy(searchQuery = barcode)
        scope.launch {
            _state.value = _state.value.copy(searching = true)
            val results = repository.searchProducts(barcode)
            val exact = results.firstOrNull { it.barcode == barcode }
            if (exact != null) {
                addToCart(exact)
                _state.value = _state.value.copy(searchQuery = "", searchResults = emptyList(), searching = false)
            } else if (results.size == 1) {
                addToCart(results.first())
                _state.value = _state.value.copy(searchQuery = "", searchResults = emptyList(), searching = false)
            } else {
                _state.value = _state.value.copy(searchResults = results, searching = false)
            }
        }
    }

    fun addToCart(product: PosProduct) {
        val lines = _state.value.lines.toMutableList()
        val idx = lines.indexOfFirst { it.product.id == product.id }
        if (idx >= 0) {
            val existing = lines[idx]
            lines[idx] = existing.copy(quantity = existing.quantity + 1.0)
        } else {
            lines.add(CartLine(product, 1.0))
        }
        _state.value = _state.value.copy(lines = lines)
    }

    fun setQuantity(productId: Long, quantity: Double) {
        val lines = _state.value.lines.toMutableList()
        val idx = lines.indexOfFirst { it.product.id == productId }
        if (idx < 0) return
        if (quantity <= 0.0) {
            lines.removeAt(idx)
        } else {
            lines[idx] = lines[idx].copy(quantity = quantity)
        }
        _state.value = _state.value.copy(lines = lines)
    }

    fun removeLine(productId: Long) {
        _state.value = _state.value.copy(lines = _state.value.lines.filterNot { it.product.id == productId })
    }

    fun clearCart() {
        _state.value = _state.value.copy(lines = emptyList(), discountValue = 0.0, submittedOrderId = null)
    }

    fun selectPaymentMethod(pm: PaymentMethodDto) {
        _state.value = _state.value.copy(selectedPaymentMethod = pm)
    }

    fun selectAccount(acc: PosAccountDto?) {
        _state.value = _state.value.copy(selectedAccount = acc)
    }

    fun selectTax(tax: TaxDto?) {
        _state.value = _state.value.copy(selectedTax = tax)
    }

    fun updateDiscount(raw: String) {
        val v = raw.toDoubleOrNull() ?: 0.0
        _state.value = _state.value.copy(discountValue = v)
    }

    fun updateInventoryId(id: Long?) {
        _state.value = _state.value.copy(inventoryId = id)
    }

    fun checkout(clientId: Long? = null, note: String? = null) {
        val s = _state.value
        if (!s.canCheckout) return
        val invId = s.inventoryId ?: defaultInventoryId ?: return
        val items = s.lines.map {
            PosOrderItemRequest(
                productId = it.product.id,
                quantity = it.quantity,
                unitPrice = it.product.displayPrice,
            )
        }
        val req = PosOrderCreateRequest(
            clientId = clientId,
            inventoryId = invId,
            date = todayIso(),
            items = items,
            discountType = if (s.discountValue > 0) "fixed" else null,
            discountValue = if (s.discountValue > 0) s.discountValue else null,
            taxId = s.selectedTax?.id,
            paymentMethodId = s.selectedPaymentMethod?.id,
            paidAmount = s.grandTotal.format2(),
            accountId = s.selectedAccount?.id,
            note = note,
        )
        scope.launch {
            _state.value = s.copy(submitting = true, error = null)
            try {
                val order = repository.createOrder(req)
                _state.value = _state.value.copy(
                    submitting = false,
                    submittedOrderId = order.id,
                    lines = emptyList(),
                    discountValue = 0.0,
                )
            } catch (e: Throwable) {
                _state.value = _state.value.copy(submitting = false, error = e.toAppError())
            }
        }
    }

    fun acknowledgeSubmitted() {
        _state.value = _state.value.copy(submittedOrderId = null)
    }
}

private fun Double.format2(): String {
    val cents = (this * 100).toLong()
    val whole = cents / 100
    val frac = (if (cents < 0) -cents else cents) % 100
    val fracStr = if (frac < 10) "0$frac" else frac.toString()
    return "$whole.$fracStr"
}

@OptIn(ExperimentalTime::class)
private fun todayIso(): String {
    val now = Clock.System.now()
    val local = now.toLocalDateTime(TimeZone.currentSystemDefault()).date
    return local.toString()
}
