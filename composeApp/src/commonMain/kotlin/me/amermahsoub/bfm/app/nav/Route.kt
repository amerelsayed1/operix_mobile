package me.amermahsoub.bfm.app.nav

/**
 * Sealed navigation graph for the app. We avoid a third-party router for
 * Phase 1 and ship a minimal stack-based navigator (see [AppNavigator]).
 */
sealed class Route {
    data object Login : Route()
    data object Home : Route()

    // POS
    data object PosCart : Route()
    data object PosOrders : Route()
    data class PosOrderDetail(val id: Long) : Route()
    data object ShiftHistory : Route()
    data object OpenShift : Route()
    data object CloseShift : Route()
    data object CashMovement : Route()
    data object BarcodeScanner : Route()

    // Clients
    data object ClientsList : Route()
    data class ClientDetail(val id: Long) : Route()
    data class ClientForm(val id: Long? = null) : Route()
    data class RecordClientPayment(val clientId: Long) : Route()

    // Products & Inventory
    data object ProductsList : Route()
    data class ProductDetail(val id: Long) : Route()
    data object InventoryList : Route()
    data class InventoryDetail(val id: Long) : Route()

    // Expenses
    data object ExpensesList : Route()
    data class ExpenseForm(val id: Long? = null) : Route()

    // Accounts
    data object AccountsList : Route()
    data class AccountDetail(val id: Long) : Route()
    data class AccountDepositForm(val accountId: Long? = null) : Route()
    data class AccountWithdrawForm(val accountId: Long? = null) : Route()
    data object AccountTransferForm : Route()

    // Profile
    data object Profile : Route()
    data object EditProfile : Route()
    data object ChangePassword : Route()

    // Reports
    data object Reports : Route()

    // Invoices
    data object InvoicesList : Route()
    data class InvoiceDetail(val id: Long) : Route()

    // Suppliers
    data object SuppliersList : Route()
    data class SupplierDetail(val id: Long) : Route()
    data class SupplierForm(val id: Long? = null) : Route()

    // Notifications
    data object Notifications : Route()

    // Misc
    data object BillingStatus : Route()
    data object Settings : Route()
}
