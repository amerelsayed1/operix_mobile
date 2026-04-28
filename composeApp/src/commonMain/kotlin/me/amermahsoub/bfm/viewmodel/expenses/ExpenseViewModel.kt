package me.amermahsoub.bfm.viewmodel.expenses

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import me.amermahsoub.bfm.shared.data.api.OperixApiService
import me.amermahsoub.bfm.shared.data.models.CreateExpenseRequest
import me.amermahsoub.bfm.shared.data.models.Expense
import me.amermahsoub.bfm.shared.data.models.ExpenseCategory
import me.amermahsoub.bfm.shared.data.models.PaginatedResponse
import me.amermahsoub.bfm.shared.data.models.PaymentMethod
import me.amermahsoub.bfm.shared.data.models.Result
import me.amermahsoub.bfm.shared.data.tenant.SessionStore
import me.amermahsoub.bfm.viewmodel.BaseViewModel

class ExpenseViewModel(
    private val api: OperixApiService,
    private val sessionStore: SessionStore,
) : BaseViewModel() {

    private val slug: String
        get() = sessionStore.session.value?.login?.tenant?.slug ?: ""

    // ── Expenses list ─────────────────────────────────────────────────────

    private val _expensesState = MutableStateFlow<Result<PaginatedResponse<Expense>>>(Result.Loading)
    val expensesState: StateFlow<Result<PaginatedResponse<Expense>>> = _expensesState.asStateFlow()

    // ── Form supporting data ──────────────────────────────────────────────

    private val _categories = MutableStateFlow<List<ExpenseCategory>>(emptyList())
    val categories: StateFlow<List<ExpenseCategory>> = _categories.asStateFlow()

    private val _paymentMethods = MutableStateFlow<List<PaymentMethod>>(emptyList())
    val paymentMethods: StateFlow<List<PaymentMethod>> = _paymentMethods.asStateFlow()

    // ── Filter state ──────────────────────────────────────────────────────

    private val _categoryFilter = MutableStateFlow<Int?>(null)
    val categoryFilter: StateFlow<Int?> = _categoryFilter.asStateFlow()

    private val _dateFrom = MutableStateFlow("")
    val dateFrom: StateFlow<String> = _dateFrom.asStateFlow()

    private val _dateTo = MutableStateFlow("")
    val dateTo: StateFlow<String> = _dateTo.asStateFlow()

    init {
        loadExpenses()
        loadFormData()
    }

    fun loadExpenses(
        categoryId: Int? = _categoryFilter.value,
        fromDate: String? = _dateFrom.value.takeIf { it.isNotBlank() },
        toDate: String? = _dateTo.value.takeIf { it.isNotBlank() },
        page: Int = 1,
    ) {
        _expensesState.load {
            api.getExpenses(slug = slug, categoryId = categoryId, fromDate = fromDate, toDate = toDate, page = page)
        }
    }

    fun loadFormData() {
        launch {
            _categories.value = runCatching { api.getExpenseCategories(slug) }.getOrDefault(emptyList())
            _paymentMethods.value = runCatching { api.getPaymentMethods(slug) }.getOrDefault(emptyList())
        }
    }

    fun setCategoryFilter(categoryId: Int?) {
        _categoryFilter.value = categoryId
        loadExpenses(categoryId = categoryId)
    }

    fun setDateFrom(date: String) {
        _dateFrom.value = date
    }

    fun setDateTo(date: String) {
        _dateTo.value = date
    }

    fun applyDateFilter() {
        loadExpenses(
            fromDate = _dateFrom.value.takeIf { it.isNotBlank() },
            toDate = _dateTo.value.takeIf { it.isNotBlank() },
        )
    }

    suspend fun createExpense(
        categoryId: Int,
        amount: Double,
        paymentMethodId: Int,
        date: String,
        description: String,
        reference: String? = null,
        notes: String? = null,
    ): Result<Expense> {
        return try {
            val expense = api.createExpense(
                slug,
                CreateExpenseRequest(
                    expenseCategoryId = categoryId,
                    amount = amount,
                    paymentMethodId = paymentMethodId,
                    expenseDate = date,
                    description = description,
                    reference = reference,
                    notes = notes,
                ),
            )
            loadExpenses()
            Result.Success(expense)
        } catch (e: Exception) {
            Result.Error(e.message ?: "Failed to create expense")
        }
    }
}
