package me.amermahsoub.bfm.viewmodel.invoices

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.CreatePurchaseInvoiceRequest
import me.amermahsoub.bfm.shared.data.models.Inventory
import me.amermahsoub.bfm.shared.data.models.PaginatedResponse
import me.amermahsoub.bfm.shared.data.models.PaymentMethod
import me.amermahsoub.bfm.shared.data.models.Product
import me.amermahsoub.bfm.shared.data.models.PurchaseInvoice
import me.amermahsoub.bfm.shared.data.models.RecordPaymentRequest
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Supplier
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class PurchaseInvoiceViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    // ── Invoice list ──────────────────────────────────────────────────────

    private val _invoicesState =
        MutableStateFlow<Result<PaginatedResponse<PurchaseInvoice>>>(Result.Loading)
    val invoicesState: StateFlow<Result<PaginatedResponse<PurchaseInvoice>>> =
        _invoicesState.asStateFlow()

    // ── Invoice detail ─────────────────────────────────────────────────────

    private val _invoiceDetail = MutableStateFlow<Result<PurchaseInvoice>>(Result.Loading)
    val invoiceDetail: StateFlow<Result<PurchaseInvoice>> = _invoiceDetail.asStateFlow()

    // ── Filters ───────────────────────────────────────────────────────────

    private val _statusFilter = MutableStateFlow<String?>(null)
    val statusFilter: StateFlow<String?> = _statusFilter.asStateFlow()

    // ── Form data ─────────────────────────────────────────────────────────

    private val _suppliers = MutableStateFlow<List<Supplier>>(emptyList())
    val suppliers: StateFlow<List<Supplier>> = _suppliers.asStateFlow()

    private val _products = MutableStateFlow<List<Product>>(emptyList())
    val products: StateFlow<List<Product>> = _products.asStateFlow()

    private val _inventories = MutableStateFlow<List<Inventory>>(emptyList())
    val inventories: StateFlow<List<Inventory>> = _inventories.asStateFlow()

    private val _paymentMethods = MutableStateFlow<List<PaymentMethod>>(emptyList())
    val paymentMethods: StateFlow<List<PaymentMethod>> = _paymentMethods.asStateFlow()

    // ── Actions ───────────────────────────────────────────────────────────

    fun loadInvoices(status: String? = null, supplierId: Int? = null, page: Int = 1) {
        _statusFilter.value = status
        _invoicesState.load {
            api.getPurchaseInvoices(slug = slug, status = status, supplierId = supplierId, page = page)
        }
    }

    fun loadInvoice(id: Int) {
        _invoiceDetail.load {
            api.getPurchaseInvoice(slug, id)
        }
    }

    fun loadFormData() {
        launch {
            runCatching { api.getSuppliers(slug, perPage = 200) }
                .getOrNull()
                ?.let { _suppliers.value = it.data }

            runCatching { api.getProducts(slug, perPage = 200) }
                .getOrNull()
                ?.let { _products.value = it.data }

            runCatching { api.getInventories(slug) }
                .getOrNull()
                ?.let { _inventories.value = it }

            runCatching { api.getPaymentMethods(slug) }
                .getOrNull()
                ?.let { _paymentMethods.value = it }
        }
    }

    fun setStatusFilter(status: String?) {
        loadInvoices(status)
    }

    suspend fun createInvoice(request: CreatePurchaseInvoiceRequest): Result<PurchaseInvoice> =
        runCatching { api.createPurchaseInvoice(slug, request) }
            .fold(
                onSuccess = { Result.Success(it) },
                onFailure = { Result.Error(it.message ?: "Failed to create invoice") },
            )

    suspend fun postInvoice(id: Int): Result<PurchaseInvoice> =
        runCatching { api.postPurchaseInvoice(slug, id) }
            .fold(
                onSuccess = { Result.Success(it) },
                onFailure = { Result.Error(it.message ?: "Failed to post invoice") },
            )

    suspend fun recordSupplierPayment(
        invoiceId: Int,
        amount: Double,
        paymentMethodId: Int,
        paymentDate: String,
        notes: String?,
    ): Result<PurchaseInvoice> =
        runCatching {
            api.recordSupplierPayment(
                slug,
                RecordPaymentRequest(
                    amount = amount,
                    paymentMethodId = paymentMethodId,
                    paymentDate = paymentDate,
                    notes = notes,
                ),
                invoiceId,
            )
        }.fold(
            onSuccess = { Result.Success(it) },
            onFailure = { Result.Error(it.message ?: "Failed to record payment") },
        )
}
