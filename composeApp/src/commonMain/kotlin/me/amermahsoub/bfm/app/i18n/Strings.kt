package me.amermahsoub.bfm.app.i18n

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.unit.LayoutDirection

/**
 * Minimal i18n layer supporting English (LTR) and Arabic (RTL). Strings are
 * plain Kotlin objects for Phase 1 — no codegen dependency. Additional locales
 * can slot in via [Strings.forLocale].
 */
interface AppStrings {
    val localeCode: String
    val layoutDirection: LayoutDirection get() =
        if (localeCode == "ar") LayoutDirection.Rtl else LayoutDirection.Ltr

    // Global
    val appName: String
    val loading: String
    val retry: String
    val cancel: String
    val save: String
    val delete: String
    val ok: String
    val yes: String
    val no: String
    val search: String
    val empty: String
    val error: String
    val offlineBanner: String
    val seeAll: String
    val close: String
    val logout: String

    // Login
    val loginTitle: String
    val loginSubtitle: String
    val companyCode: String
    val companyCodeHint: String
    val username: String
    val usernameHint: String
    val password: String
    val accessPortal: String
    val forgotPassword: String

    // Home tabs
    val tabDashboard: String
    val tabPos: String
    val tabClients: String
    val tabProducts: String
    val tabMore: String

    // Dashboard
    val dashboardTitle: String
    val welcomeBack: String
    val totalSales: String
    val totalExpenses: String
    val netProfit: String
    val totalBalance: String
    val lowStockItems: String
    val recentOrders: String
    val topSelling: String
    val quickActions: String
    val startSale: String
    val recordPayment: String
    val addExpense: String
    val viewReports: String

    // POS
    val posTitle: String
    val searchProducts: String
    val scanBarcode: String
    val cart: String
    val emptyCart: String
    val subtotal: String
    val discount: String
    val tax: String
    val grandTotal: String
    val paymentMethod: String
    val charge: String
    val completeSale: String
    val openShift: String
    val closeShift: String
    val shiftClosed: String
    val shiftOpen: String
    val openingCash: String
    val actualCash: String
    val variance: String
    val varianceNotes: String
    val shiftSummary: String
    val cashIn: String
    val cashOut: String
    val orders: String
    val receiptNumber: String
    val drawerAccount: String

    // Clients
    val clientsTitle: String
    val addClient: String
    val clientName: String
    val phone: String
    val email: String
    val address: String
    val creditLimit: String
    val balance: String
    val blockClient: String
    val unblockClient: String
    val recordClientPayment: String
    val totalReceivables: String
    val overdue: String

    // Products
    val productsTitle: String
    val inStock: String
    val outOfStock: String
    val lowStock: String
    val sku: String
    val barcode: String
    val category: String
    val price: String

    // Inventory
    val inventoryTitle: String
    val defaultInventory: String

    // Expenses
    val expensesTitle: String
    val addExpenseTitle: String
    val amount: String
    val date: String
    val description: String

    // Accounts
    val accountsTitle: String
    val deposit: String
    val withdraw: String
    val transfer: String
    val fromAccount: String
    val toAccount: String

    // Profile
    val profileTitle: String
    val editProfile: String
    val changePassword: String
    val language: String
    val settings: String
    val theme: String
    val lightMode: String
    val darkMode: String
    val currentPassword: String
    val newPassword: String
    val confirmPassword: String
}

val LocalAppStrings = staticCompositionLocalOf<AppStrings> { EnStrings }

@Composable
@ReadOnlyComposable
fun appStrings(): AppStrings = LocalAppStrings.current

@Composable
fun ProvideAppStrings(locale: String, content: @Composable () -> Unit) {
    val strings = AppStringsRegistry.forLocale(locale)
    CompositionLocalProvider(LocalAppStrings provides strings, content = content)
}

object AppStringsRegistry {
    fun forLocale(code: String?): AppStrings = when (code?.lowercase()) {
        "ar" -> ArStrings
        else -> EnStrings
    }
}
