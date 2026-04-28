package me.amermahsoub.bfm.viewmodel.clients

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.Client
import me.amermahsoub.bfm.shared.data.models.ClientStatementEntry
import me.amermahsoub.bfm.shared.data.models.PaginatedResponse
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class ClientViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    private val _clientsState = MutableStateFlow<Result<PaginatedResponse<Client>>>(Result.Loading)
    val clientsState: StateFlow<Result<PaginatedResponse<Client>>> = _clientsState.asStateFlow()

    private val _clientDetail = MutableStateFlow<Result<Client>>(Result.Loading)
    val clientDetail: StateFlow<Result<Client>> = _clientDetail.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _statementState = MutableStateFlow<Result<List<ClientStatementEntry>>>(Result.Loading)
    val statementState: StateFlow<Result<List<ClientStatementEntry>>> = _statementState.asStateFlow()

    var currentPage: Int = 1
        private set

    fun loadClients(search: String? = null, page: Int = 1) {
        currentPage = page
        if (search != null) _searchQuery.value = search
        _clientsState.load { api.getClients(slug, search ?: _searchQuery.value.ifBlank { null }, null, page) }
    }

    fun loadClient(id: Int) {
        _clientDetail.load { api.getClient(slug, id) }
    }

    fun loadStatement(clientId: Int, fromDate: String, toDate: String) {
        _statementState.load { api.getClientStatement(slug, clientId, fromDate, toDate) }
    }

    suspend fun createClient(
        name: String,
        phone: String? = null,
        email: String? = null,
        address: String? = null,
        creditLimit: Double? = null,
        taxNumber: String? = null,
        notes: String? = null,
    ): Result<Client> = try {
        val body = buildMap<String, Any?> {
            put("name", name)
            if (!phone.isNullOrBlank()) put("phone", phone)
            if (!email.isNullOrBlank()) put("email", email)
            if (!address.isNullOrBlank()) put("address", address)
            if (creditLimit != null) put("credit_limit", creditLimit)
            if (!taxNumber.isNullOrBlank()) put("tax_number", taxNumber)
            if (!notes.isNullOrBlank()) put("notes", notes)
        }
        Result.Success(api.createClient(slug, body))
    } catch (e: Exception) {
        Result.Error(e.message ?: "Failed to create client")
    }

    suspend fun updateClient(id: Int, updates: Map<String, Any?>): Result<Client> = try {
        Result.Success(api.updateClient(slug, id, updates))
    } catch (e: Exception) {
        Result.Error(e.message ?: "Failed to update client")
    }
}
