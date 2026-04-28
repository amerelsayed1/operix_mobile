package me.amermahsoub.bfm.viewmodel.accounts

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.Account
import me.amermahsoub.bfm.shared.data.models.AccountingPeriod
import me.amermahsoub.bfm.shared.data.models.GlAccount
import me.amermahsoub.bfm.shared.data.models.JournalEntry
import me.amermahsoub.bfm.shared.data.models.PaginatedResponse
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class AccountsViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    // ── Cash / Bank Accounts ──────────────────────────────────────────────

    private val _accountsState = MutableStateFlow<Result<List<Account>>>(Result.Loading)
    val accountsState: StateFlow<Result<List<Account>>> = _accountsState.asStateFlow()

    // ── GL Accounts ───────────────────────────────────────────────────────

    private val _glAccountsState = MutableStateFlow<Result<List<GlAccount>>>(Result.Loading)
    val glAccountsState: StateFlow<Result<List<GlAccount>>> = _glAccountsState.asStateFlow()

    // ── Journal Entries ───────────────────────────────────────────────────

    private val _journalEntriesState = MutableStateFlow<Result<PaginatedResponse<JournalEntry>>>(Result.Loading)
    val journalEntriesState: StateFlow<Result<PaginatedResponse<JournalEntry>>> = _journalEntriesState.asStateFlow()

    // ── Accounting Periods ────────────────────────────────────────────────

    private val _periodsState = MutableStateFlow<Result<List<AccountingPeriod>>>(Result.Loading)
    val periodsState: StateFlow<Result<List<AccountingPeriod>>> = _periodsState.asStateFlow()

    init {
        loadAccounts()
        loadGlAccounts()
        loadJournalEntries()
        loadPeriods()
    }

    fun loadAccounts(type: String? = null) {
        _accountsState.load { api.getAccounts(slug, type) }
    }

    fun loadGlAccounts(accountType: String? = null) {
        _glAccountsState.load { api.getGlAccounts(slug, accountType) }
    }

    fun loadJournalEntries(
        sourceType: String? = null,
        fromDate: String? = null,
        toDate: String? = null,
        page: Int = 1,
    ) {
        _journalEntriesState.load {
            api.getJournalEntries(slug, sourceType, fromDate, toDate, page)
        }
    }

    fun loadPeriods() {
        _periodsState.load { api.getAccountingPeriods(slug) }
    }
}
