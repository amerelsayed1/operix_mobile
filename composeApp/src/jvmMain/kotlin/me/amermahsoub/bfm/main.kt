package me.amermahsoub.bfm

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import me.amermahsoub.bfm.di.appModule
import me.amermahsoub.bfm.shared.data.tenant.tenantBootstrapModule
import me.amermahsoub.bfm.shared.printing.printingModule
import org.koin.core.context.GlobalContext
import org.koin.core.context.startKoin

fun main() {
    if (GlobalContext.getOrNull() == null) {
        startKoin {
            modules(tenantBootstrapModule(), printingModule(), appModule)
        }
    }

    application {
        Window(
            onCloseRequest = ::exitApplication,
            title = "Bfm",
        ) {
            App()
        }
    }
}
