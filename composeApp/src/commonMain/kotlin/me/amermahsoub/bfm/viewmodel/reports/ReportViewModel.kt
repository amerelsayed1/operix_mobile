package me.amermahsoub.bfm.viewmodel.reports

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlin.time.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.TimeZone
import kotlinx.datetime.minus
import kotlinx.datetime.toLocalDateTime
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.Account
import me.amermahsoub.bfm.shared.data.models.AccountStatementEntry
import me.amermahsoub.bfm.shared.data.models.ProfitLossReport
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.models.TrialBalanceRow
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class ReportViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    // ── Date helpers ──────────────────────────────────────────────────────

    private fun defaultFromDate(): String {
        val tz = TimeZone.currentSystemDefault()
        val today = Clock.System.now().toLocalDateTime(tz).date
        val firstOfMonth = today.minus(today.dayOfMonth - 1, DateTimeUnit.DAY)
        return firstOfMonth.toString() // YYYY-MM-DD
    }

    private fun defaultToDate(): String {
        val tz = TimeZone.currentSystemDefault()
        return Clock.System.now().toLocalDateTime(tz).date.toString() // YYYY-MM-DD
    }

    // ── Date range state ──────────────────────────────────────────────────

    private val _fromDate = MutableStateFlow(defaultFromDate())
    val fromDate: StateFlow<String> = _fromDate.asStateFlow()

    private val _toDate = MutableStateFlow(defaultToDate())
    val toDate: StateFlow<String> = _toDate.asStateFlow()

    // ── Profit & Loss ─────────────────────────────────────────────────────

    private val _plState = MutableStateFlow<Result<ProfitLossReport>>(Result.Loading)
    val plState: StateFlow<Result<ProfitLossReport>> = _plState.asStateFlow()

    // ── Trial Balance ─────────────────────────────────────────────────────

    private val _trialBalanceState = MutableStateFlow<Result<List<TrialBalanceRow>>>(Result.Loading)
    val trialBalanceState: StateFlow<Result<List<TrialBalanceRow>>> = _trialBalanceState.asStateFlow()

    // ── Account Statement ─────────────────────────────────────────────────

    private val _accountStatementState = MutableStateFlow<Result<List<AccountStatementEntry>>>(Result.Loading)
    val accountStatementState: StateFlow<Result<List<AccountStatementEntry>>> = _accountStatementState.asStateFlow()

    // ── Accounts ──────────────────────────────────────────────────────────

    private val _accounts = MutableStateFlow<List<Account>>(emptyList())
    val accounts: StateFlow<List<Account>> = _accounts.asStateFlow()

    // ── Actions ───────────────────────────────────────────────────────────

    fun setDateRange(from: String, to: String) {
        _fromDate.value = from
        _toDate.value = to
    }

    fun loadProfitLoss() {
        _plState.load {
            api.getProfitLoss(slug, _fromDate.value, _toDate.value)
        }
    }

    fun loadTrialBalance() {
        _trialBalanceState.load {
            api.getTrialBalance(slug, _fromDate.value, _toDate.value)
        }
    }

    fun loadAccountStatement(accountId: Int) {
        _accountStatementState.load {
            api.getAccountStatement(slug, accountId, _fromDate.value, _toDate.value)
        }
    }

    fun loadAccounts() {
        launch {
            _accounts.value = runCatching { api.getAccounts(slug) }.getOrDefault(emptyList())
        }
    }
}
