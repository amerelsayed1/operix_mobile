package me.amermahsoub.bfm.navigation

sealed class NavRoutes(val route: String) {
    // Auth
    data object Login : NavRoutes("login")

    // Main tabs
    data object Dashboard : NavRoutes("dashboard")
    data object Pos : NavRoutes("pos")
    data object Invoices : NavRoutes("invoices")
    data object Products : NavRoutes("products")
    data object More : NavRoutes("more")

    // POS sub-screens
    data object PosTerminals : NavRoutes("pos/terminals")
    data object PosActiveShift : NavRoutes("pos/shift")
    data object PosCart : NavRoutes("pos/cart")
    data object PosReceipt : NavRoutes("pos/receipt/{orderId}") {
        fun build(orderId: Int) = "pos/receipt/$orderId"
    }
    data object ShiftSummary : NavRoutes("pos/shift/{shiftId}/summary") {
        fun build(shiftId: Int) = "pos/shift/$shiftId/summary"
    }

    // Products sub-screens
    data object ProductList : NavRoutes("products/list")
    data object ProductDetail : NavRoutes("products/{productId}") {
        fun build(id: Int) = "products/$id"
    }
    data object ProductCreate : NavRoutes("products/create")
    data object ProductEdit : NavRoutes("products/{productId}/edit") {
        fun build(id: Int) = "products/$id/edit"
    }
    data object ProductCategories : NavRoutes("products/categories")
    data object ProductUnits : NavRoutes("products/units")

    // Sales invoices
    data object SalesInvoiceList : NavRoutes("invoices/sales")
    data object SalesInvoiceDetail : NavRoutes("invoices/sales/{invoiceId}") {
        fun build(id: Int) = "invoices/sales/$id"
    }
    data object SalesInvoiceCreate : NavRoutes("invoices/sales/create")

    // Purchase invoices
    data object PurchaseInvoiceList : NavRoutes("invoices/purchases")
    data object PurchaseInvoiceDetail : NavRoutes("invoices/purchases/{invoiceId}") {
        fun build(id: Int) = "invoices/purchases/$id"
    }
    data object PurchaseInvoiceCreate : NavRoutes("invoices/purchases/create")

    // Clients
    data object ClientList : NavRoutes("clients")
    data object ClientDetail : NavRoutes("clients/{clientId}") {
        fun build(id: Int) = "clients/$id"
    }
    data object ClientCreate : NavRoutes("clients/create")

    // Suppliers
    data object SupplierList : NavRoutes("suppliers")
    data object SupplierDetail : NavRoutes("suppliers/{supplierId}") {
        fun build(id: Int) = "suppliers/$id"
    }
    data object SupplierCreate : NavRoutes("suppliers/create")

    // Inventory
    data object InventoryList : NavRoutes("inventory")
    data object InventoryDetail : NavRoutes("inventory/{inventoryId}") {
        fun build(id: Int) = "inventory/$id"
    }
    data object StockMovements : NavRoutes("inventory/movements")

    // Expenses
    data object ExpenseList : NavRoutes("expenses")
    data object ExpenseCreate : NavRoutes("expenses/create")

    // Reports
    data object Reports : NavRoutes("reports")
    data object ProfitLoss : NavRoutes("reports/profit-loss")
    data object TrialBalance : NavRoutes("reports/trial-balance")
    data object AccountStatement : NavRoutes("reports/account-statement")

    // Accounts / GL
    data object Accounts : NavRoutes("accounts")

    // Settings
    data object Settings : NavRoutes("settings")
    data object Users : NavRoutes("settings/users")
}
