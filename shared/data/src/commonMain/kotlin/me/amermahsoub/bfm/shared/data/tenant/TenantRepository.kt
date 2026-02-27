package me.amermahsoub.bfm.shared.data.tenant

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToOneOrNull
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import kotlinx.datetime.Clock
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.db.BfmDatabase

class TenantRepository(
    private val database: BfmDatabase,
    private val apiService: TenantApiService,
    private val json: Json,
) {
    private val queries = database.tenantQueries

    fun getSelectedTenantSlug(): Flow<String?> =
        queries.selectTenantSlug().asFlow().mapToOneOrNull(Dispatchers.IO).map { it?.tenant_slug }.distinctUntilChanged()

    suspend fun selectTenant(slug: String) {
        withContext(Dispatchers.IO) {
            queries.upsertSelectedTenant(slug, Clock.System.now().toString())
        }
    }

    fun getCachedConfig(slug: String): Flow<TenantConfig?> =
        queries.selectTenantConfigBySlug(slug).asFlow().mapToOneOrNull(Dispatchers.IO).map { row ->
            row?.json?.let { json.decodeFromString<TenantBootstrapResponse>(it).tenant }
        }


    suspend fun getCachedConfigOnce(slug: String): TenantConfig? = getCachedConfig(slug).first()

    suspend fun refreshConfig(slug: String): TenantConfig {
        val response = apiService.fetchBootstrap(slug)
        withContext(Dispatchers.IO) {
            queries.upsertTenantConfig(
                tenant_slug = slug,
                json = json.encodeToString(response),
                updated_at = Clock.System.now().toString(),
                config_etag = null,
                config_version = response.app.minVersion,
            )
        }
        return response.tenant
    }

    suspend fun clearTenantData(slug: String) {
        withContext(Dispatchers.IO) {
            queries.transaction {
                queries.deleteEmployeeCacheByTenant(slug)
                queries.deleteProductCacheByTenant(slug)
                queries.deleteOrderCacheByTenant(slug)
            }
        }
    }
}
