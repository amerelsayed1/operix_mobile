package me.amermahsoub.bfm.logging

object DesktopBootstrapLogging {
    private val logger = AppLogger.logger("desktop.bootstrap")

    fun logTenantCacheWarmup() {
        logger.info { "Starting tenant cache warmup" }

        val tenantSlug = "default"
        logger.debug { "Fetching bootstrap state for tenantSlug=$tenantSlug" }

        logger.info { "Tenant cache warmup complete for tenantSlug=$tenantSlug" }
    }
}
