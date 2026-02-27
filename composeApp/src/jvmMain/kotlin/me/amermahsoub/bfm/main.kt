package me.amermahsoub.bfm

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import me.amermahsoub.bfm.logging.AppLogger
import me.amermahsoub.bfm.logging.DesktopBootstrapLogging
import me.amermahsoub.bfm.shared.data.tenant.tenantBootstrapModule
import me.amermahsoub.bfm.shared.printing.printingModule
import org.koin.core.context.GlobalContext
import org.koin.core.context.startKoin

fun main() {
    val logger = AppLogger.logger("desktop.main")
    logger.info { "Desktop application startup initiated" }

    if (GlobalContext.getOrNull() == null) {
        startKoin {
            modules(tenantBootstrapModule(), printingModule())
        }
        logger.info { "Koin modules started for desktop runtime" }
    }

    DesktopBootstrapLogging.logTenantCacheWarmup()

    application {
        logger.info { "Creating main desktop window" }
        Window(
            onCloseRequest = ::exitApplication,
            title = "Bfm",
        ) {
            App()
        }
    }
}
