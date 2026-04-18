package me.amermahsoub.bfm.shared.data

import me.amermahsoub.bfm.shared.data.accounts.AccountsApi
import me.amermahsoub.bfm.shared.data.accounts.AccountsRepository
import me.amermahsoub.bfm.shared.data.clients.ClientsApi
import me.amermahsoub.bfm.shared.data.clients.ClientsRepository
import me.amermahsoub.bfm.shared.data.dashboard.DashboardApi
import me.amermahsoub.bfm.shared.data.dashboard.DashboardRepository
import me.amermahsoub.bfm.shared.data.expenses.ExpensesApi
import me.amermahsoub.bfm.shared.data.expenses.ExpensesRepository
import me.amermahsoub.bfm.shared.data.inventory.InventoryApi
import me.amermahsoub.bfm.shared.data.inventory.InventoryRepository
import me.amermahsoub.bfm.shared.data.pos.PosApi
import me.amermahsoub.bfm.shared.data.pos.PosRepository
import me.amermahsoub.bfm.shared.data.products.ProductsApi
import me.amermahsoub.bfm.shared.data.products.ProductsRepository
import me.amermahsoub.bfm.shared.data.invoices.InvoicesApi
import me.amermahsoub.bfm.shared.data.invoices.InvoicesRepository
import me.amermahsoub.bfm.shared.data.notifications.NotificationsApi
import me.amermahsoub.bfm.shared.data.notifications.NotificationsRepository
import me.amermahsoub.bfm.shared.data.profile.ProfileApi
import me.amermahsoub.bfm.shared.data.profile.ProfileRepository
import me.amermahsoub.bfm.shared.data.reports.ReportsApi
import me.amermahsoub.bfm.shared.data.reports.ReportsRepository
import me.amermahsoub.bfm.shared.data.suppliers.SuppliersApi
import me.amermahsoub.bfm.shared.data.suppliers.SuppliersRepository
import org.koin.core.module.Module
import org.koin.dsl.module

/**
 * Registers APIs and repositories for every Phase 1 feature module. Relies on
 * HttpClient, TenantAwareApiUrlBuilder and Json already being provided by
 * [tenantBootstrapModule].
 */
fun featureModule(): Module = module {
    // Dashboard
    single { DashboardApi(get(), get(), get()) }
    single { DashboardRepository(get()) }

    // POS
    single { PosApi(get(), get(), get()) }
    single { PosRepository(get()) }

    // Clients
    single { ClientsApi(get(), get(), get()) }
    single { ClientsRepository(get()) }

    // Products
    single { ProductsApi(get(), get(), get()) }
    single { ProductsRepository(get()) }

    // Inventory
    single { InventoryApi(get(), get(), get()) }
    single { InventoryRepository(get()) }

    // Expenses
    single { ExpensesApi(get(), get(), get()) }
    single { ExpensesRepository(get()) }

    // Accounts
    single { AccountsApi(get(), get(), get()) }
    single { AccountsRepository(get()) }

    // Profile
    single { ProfileApi(get(), get(), get()) }
    single { ProfileRepository(get()) }

    // Reports
    single { ReportsApi(get(), get(), get()) }
    single { ReportsRepository(get()) }

    // Invoices
    single { InvoicesApi(get(), get(), get()) }
    single { InvoicesRepository(get()) }

    // Suppliers
    single { SuppliersApi(get(), get(), get()) }
    single { SuppliersRepository(get()) }

    // Notifications
    single { NotificationsApi(get(), get(), get()) }
    single { NotificationsRepository(get()) }
}
