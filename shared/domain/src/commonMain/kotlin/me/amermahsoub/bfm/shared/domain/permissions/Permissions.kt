package me.amermahsoub.bfm.shared.domain.permissions

/**
 * Canonical permission catalogue (Phase 1). Keep string codes in sync with
 * backend `/me/permissions` output. Admin receives `["*"]`.
 */
object Permissions {
    // Dashboard
    const val DASHBOARD_VIEW = "dashboard.view"

    // POS
    const val POS_VIEW = "pos.view"
    const val POS_CREATE = "pos.create"
    const val POS_UPDATE = "pos.update"
    const val POS_DELETE = "pos.delete"
    const val POS_CLIENTS = "pos.clients"

    // Sales
    const val SALES_VIEW = "sales.view"
    const val SALES_CREATE = "sales.create"
    const val SALES_RETURN = "sales.return"
    const val SALES_PAY_CREDIT = "sales.pay_credit"
    const val SALES_COLLECT_PAYMENT = "sales.collect_payment"
    const val SALES_APPROVE = "sales.approve"

    // Shifts
    const val SHIFTS_VIEW = "shifts.view"
    const val SHIFTS_CREATE = "shifts.create"
    const val SHIFTS_UPDATE = "shifts.update"

    // Clients
    const val CLIENTS_VIEW = "clients.view"
    const val CLIENTS_CREATE = "clients.create"
    const val CLIENTS_UPDATE = "clients.update"
    const val CLIENTS_DELETE = "clients.delete"

    // Products
    const val PRODUCTS_VIEW = "products.view"
    const val PRODUCTS_CREATE = "products.create"
    const val PRODUCTS_UPDATE = "products.update"
    const val PRODUCTS_DELETE = "products.delete"

    // Inventory
    const val INVENTORY_VIEW = "inventory.view"
    const val INVENTORY_CREATE = "inventory.create"
    const val INVENTORY_UPDATE = "inventory.update"

    // Expenses
    const val EXPENSES_VIEW = "expenses.view"
    const val EXPENSES_CREATE = "expenses.create"
    const val EXPENSES_UPDATE = "expenses.update"
    const val EXPENSES_DELETE = "expenses.delete"

    // Accounts
    const val ACCOUNTS_VIEW = "accounts.view"
    const val ACCOUNTS_CREATE = "accounts.create"
    const val ACCOUNTS_UPDATE = "accounts.update"

    // Settings
    const val SETTINGS_VIEW = "settings.view"
    const val SETTINGS_EDIT = "settings.edit"

    // Reports
    const val REPORTS_VIEW = "reports.view"

    // Billing
    const val BILLING_VIEW = "billing.view"

    // Suppliers (Phase 2 exposure allowed on view permission)
    const val SUPPLIERS_VIEW = "suppliers.view"
    const val PURCHASES_VIEW = "purchases.view"
}

/**
 * Lightweight permission checker. Wraps the permission set fetched from
 * `/me/permissions`. Supports admin wildcard `*`.
 */
class PermissionGuard(private val permissions: Set<String>) {
    fun has(permission: String): Boolean =
        permissions.contains("*") || permissions.contains(permission)

    fun hasAny(vararg options: String): Boolean =
        permissions.contains("*") || options.any { it in permissions }

    fun hasAll(vararg required: String): Boolean =
        permissions.contains("*") || required.all { it in permissions }

    val isAdmin: Boolean get() = permissions.contains("*")

    companion object {
        val Empty: PermissionGuard = PermissionGuard(emptySet())
        fun of(list: List<String>): PermissionGuard = PermissionGuard(list.toSet())
    }
}
