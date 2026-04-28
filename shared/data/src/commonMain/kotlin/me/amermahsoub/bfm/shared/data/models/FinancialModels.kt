package me.amermahsoub.bfm.shared.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PaymentMethod(
    val id: Int,
    @SerialName("name_en") val nameEn: String? = null,
    @SerialName("name_ar") val nameAr: String? = null,
    val type: String,
    val slug: String? = null,
    @SerialName("is_active") val isActive: Boolean = true,
) {
    fun displayName(locale: String = "en") =
        if (locale == "ar") nameAr ?: nameEn ?: type else nameEn ?: type
}

@Serializable
data class Account(
    val id: Int,
    val name: String,
    val type: String? = null,
    @SerialName("current_balance") val currentBalance: String = "0.00",
    @SerialName("is_drawer") val isDrawer: Boolean = false,
    @SerialName("is_default") val isDefault: Boolean = false,
    @SerialName("is_active") val isActive: Boolean = true,
)

@Serializable
data class GlAccount(
    val id: Int,
    val code: String,
    val name: String,
    @SerialName("account_type") val accountType: String,
    @SerialName("normal_balance") val normalBalance: String,
    val balance: String = "0.00",
    @SerialName("is_active") val isActive: Boolean = true,
    val children: List<GlAccount> = emptyList(),
)

@Serializable
data class JournalEntry(
    val id: Int,
    val reference: String? = null,
    val description: String? = null,
    val status: String,
    @SerialName("source_type") val sourceType: String? = null,
    @SerialName("source_id") val sourceId: Int? = null,
    @SerialName("total_debits") val totalDebits: String,
    @SerialName("total_credits") val totalCredits: String,
    @SerialName("entry_date") val entryDate: String,
    val lines: List<JournalEntryLine> = emptyList(),
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class JournalEntryLine(
    val id: Int,
    @SerialName("gl_account_id") val glAccountId: Int,
    @SerialName("gl_account") val glAccount: GlAccount? = null,
    @SerialName("line_type") val lineType: String,
    val amount: String,
    val description: String? = null,
)

@Serializable
data class AccountingPeriod(
    val id: Int,
    val name: String,
    @SerialName("start_date") val startDate: String,
    @SerialName("end_date") val endDate: String,
    val status: String,
) {
    val isOpen get() = status == "open"
    val isClosed get() = status == "closed"
}

@Serializable
data class Inventory(
    val id: Int,
    val name: String,
    val location: String? = null,
    @SerialName("is_default") val isDefault: Boolean = false,
    @SerialName("is_active") val isActive: Boolean = true,
)

@Serializable
data class StockMovement(
    val id: Int,
    @SerialName("product_id") val productId: Int,
    val product: Product? = null,
    @SerialName("inventory_id") val inventoryId: Int,
    val type: String,
    val quantity: String,
    @SerialName("unit_cost") val unitCost: String? = null,
    @SerialName("reference_type") val referenceType: String? = null,
    @SerialName("reference_id") val referenceId: Int? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class ExpenseCategory(
    val id: Int,
    @SerialName("name_en") val nameEn: String,
    @SerialName("name_ar") val nameAr: String? = null,
    @SerialName("is_default") val isDefault: Boolean = false,
) {
    fun displayName(locale: String = "en") =
        if (locale == "ar") nameAr ?: nameEn else nameEn
}

@Serializable
data class Expense(
    val id: Int,
    @SerialName("expense_category_id") val expenseCategoryId: Int,
    val category: ExpenseCategory? = null,
    val amount: String,
    val description: String,
    @SerialName("expense_date") val expenseDate: String,
    @SerialName("payment_method_id") val paymentMethodId: Int,
    @SerialName("payment_method") val paymentMethod: PaymentMethodRef? = null,
    val reference: String? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

@Serializable
data class CreateExpenseRequest(
    @SerialName("expense_category_id") val expenseCategoryId: Int,
    val amount: Double,
    @SerialName("payment_method_id") val paymentMethodId: Int,
    @SerialName("expense_date") val expenseDate: String,
    val description: String,
    val reference: String? = null,
    val notes: String? = null,
)

// Report models
@Serializable
data class ProfitLossReport(
    val revenue: String,
    val cogs: String,
    @SerialName("gross_profit") val grossProfit: String,
    @SerialName("total_expenses") val totalExpenses: String,
    @SerialName("net_profit") val netProfit: String,
    @SerialName("revenue_breakdown") val revenueBreakdown: List<ReportLine> = emptyList(),
    @SerialName("expense_breakdown") val expenseBreakdown: List<ReportLine> = emptyList(),
)

@Serializable
data class ReportLine(
    val label: String,
    val amount: String,
    val count: Int? = null,
)

@Serializable
data class TrialBalanceRow(
    val code: String,
    val name: String,
    @SerialName("account_type") val accountType: String,
    @SerialName("total_debits") val totalDebits: String,
    @SerialName("total_credits") val totalCredits: String,
    @SerialName("net_balance") val netBalance: String,
)

@Serializable
data class AccountStatementEntry(
    val id: Int,
    val date: String,
    val description: String,
    @SerialName("reference_type") val referenceType: String? = null,
    @SerialName("debit_amount") val debitAmount: String? = null,
    @SerialName("credit_amount") val creditAmount: String? = null,
    val balance: String,
)

@Serializable
data class ClientStatementEntry(
    val id: Int,
    val date: String,
    val type: String,
    val reference: String,
    val amount: String,
    @SerialName("paid_amount") val paidAmount: String = "0.00",
    val balance: String,
)
