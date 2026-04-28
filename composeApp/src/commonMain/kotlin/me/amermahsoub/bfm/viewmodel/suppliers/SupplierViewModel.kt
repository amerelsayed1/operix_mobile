package me.amermahsoub.bfm.viewmodel.suppliers

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.ClientStatementEntry
import me.amermahsoub.bfm.shared.data.models.PaginatedResponse
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.Supplier
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class SupplierViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    private val _suppliersState = MutableStateFlow<Result<PaginatedResponse<Supplier>>>(Result.Loading)
    val suppliersState: StateFlow<Result<PaginatedResponse<Supplier>>> = _suppliersState.asStateFlow()

    private val _supplierDetail = MutableStateFlow<Result<Supplier>>(Result.Loading)
    val supplierDetail: StateFlow<Result<Supplier>> = _supplierDetail.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _statementState = MutableStateFlow<Result<List<ClientStatementEntry>>>(Result.Loading)
    val statementState: StateFlow<Result<List<ClientStatementEntry>>> = _statementState.asStateFlow()

    var currentPage: Int = 1
        private set

    fun loadSuppliers(search: String? = null, page: Int = 1) {
        currentPage = page
        if (search != null) _searchQuery.value = search
        _suppliersState.load { api.getSuppliers(slug, search ?: _searchQuery.value.ifBlank { null }, null, page) }
    }

    fun loadSupplier(id: Int) {
        _supplierDetail.load { api.getSupplier(slug, id) }
    }

    fun loadStatement(supplierId: Int, fromDate: String, toDate: String) {
        _statementState.load { api.getSupplierStatement(slug, supplierId, fromDate, toDate) }
    }

    suspend fun createSupplier(
        companyName: String,
        contactName: String? = null,
        phone: String? = null,
        email: String? = null,
        address: String? = null,
        taxNumber: String? = null,
        paymentTerms: Int? = null,
        notes: String? = null,
    ): Result<Supplier> = try {
        val body = buildMap<String, Any?> {
            put("company_name", companyName)
            if (!contactName.isNullOrBlank()) put("contact_name", contactName)
            if (!phone.isNullOrBlank()) put("phone", phone)
            if (!email.isNullOrBlank()) put("email", email)
            if (!address.isNullOrBlank()) put("address", address)
            if (!taxNumber.isNullOrBlank()) put("tax_number", taxNumber)
            if (paymentTerms != null) put("payment_terms", paymentTerms)
            if (!notes.isNullOrBlank()) put("notes", notes)
        }
        Result.Success(api.createSupplier(slug, body))
    } catch (e: Exception) {
        Result.Error(e.message ?: "Failed to create supplier")
    }

    suspend fun updateSupplier(id: Int, updates: Map<String, Any?>): Result<Supplier> = try {
        Result.Success(api.updateSupplier(slug, id, updates))
    } catch (e: Exception) {
        Result.Error(e.message ?: "Failed to update supplier")
    }
}
