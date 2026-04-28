package me.amermahsoub.bfm.di

import me.amermahsoub.bfm.viewmodel.accounts.AccountsViewModel
import me.amermahsoub.bfm.viewmodel.auth.LoginViewModel
import me.amermahsoub.bfm.viewmodel.clients.ClientViewModel
import me.amermahsoub.bfm.viewmodel.dashboard.DashboardViewModel
import me.amermahsoub.bfm.viewmodel.expenses.ExpenseViewModel
import me.amermahsoub.bfm.viewmodel.inventory.InventoryViewModel
import me.amermahsoub.bfm.viewmodel.invoices.PurchaseInvoiceViewModel
import me.amermahsoub.bfm.viewmodel.invoices.SalesInvoiceViewModel
import me.amermahsoub.bfm.viewmodel.pos.PosViewModel
import me.amermahsoub.bfm.viewmodel.pos.ShiftSummaryViewModel
import me.amermahsoub.bfm.viewmodel.products.ProductViewModel
import me.amermahsoub.bfm.viewmodel.reports.ReportViewModel
import me.amermahsoub.bfm.viewmodel.settings.SettingsViewModel
import me.amermahsoub.bfm.viewmodel.suppliers.SupplierViewModel
import org.koin.dsl.module

val appModule = module {
    factory { LoginViewModel(get(), get(), get()) }
    factory { DashboardViewModel(get(), get()) }
    factory { SettingsViewModel(get(), get()) }
    factory { ProductViewModel(get(), get()) }
    factory { ClientViewModel(get(), get()) }
    factory { SupplierViewModel(get(), get()) }
    factory { SalesInvoiceViewModel(get(), get()) }
    factory { PurchaseInvoiceViewModel(get(), get()) }
    single  { PosViewModel(get(), get()) }
    factory { ShiftSummaryViewModel(get(), get()) }
    factory { InventoryViewModel(get(), get()) }
    factory { ExpenseViewModel(get(), get()) }
    factory { ReportViewModel(get(), get()) }
    factory { AccountsViewModel(get(), get()) }
}
