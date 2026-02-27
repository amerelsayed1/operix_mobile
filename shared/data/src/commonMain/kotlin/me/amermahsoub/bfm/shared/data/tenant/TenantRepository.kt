package me.amermahsoub.bfm.shared.data.tenant

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToOneOrNull
import io.ktor.util.date.getTimeMillis
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import kotlinx.datetime.Instant
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.db.BfmDatabase

class TenantRepository(
    private val database: BfmDatabase,
    private val apiService: TenantApiService,
    private val json: Json,
) {
    private val queries = database.tenantQueries

    private fun nowIso(): String =
        Instant.fromEpochMilliseconds(getTimeMillis()).toString()

    fun getSelectedTenantSlug(): Flow<String?> =
        queries.selectTenantSlug()
            .asFlow()
            .mapToOneOrNull(Dispatchers.Default)
            .distinctUntilChanged()

    suspend fun selectTenant(slug: String) {
        withContext(Dispatchers.Default) {
            queries.upsertSelectedTenant(
                tenant_slug = slug,
                selected_at = nowIso()
            )
        }
    }

    fun getCachedConfig(slug: String): Flow<TenantConfig?> =
        queries.selectTenantConfigBySlug(slug)
            .asFlow()
            .mapToOneOrNull(Dispatchers.Default)
            .map { jsonString ->
                jsonString?.let {
                    // Stored JSON is the full bootstrap response
                    json.decodeFromString<TenantBootstrapResponse>(it).tenant
                }
            }
            .distinctUntilChanged()

    suspend fun getCachedConfigOnce(slug: String): TenantConfig? =
        getCachedConfig(slug).first()

    suspend fun refreshConfig(slug: String): TenantConfig {
        val response = apiService.fetchBootstrap(slug)

        withContext(Dispatchers.Default) {
            queries.upsertTenantConfig(
                tenant_slug = slug,
                json = json.encodeToString(response),
                updated_at = nowIso(),
                config_etag = null,
                config_version = response.app.minVersion,
            )
        }

        return response.tenant
    }


    suspend fun clearSelectedTenant() {
        withContext(Dispatchers.Default) {
            queries.deleteSelectedTenant()
        }
    }

    suspend fun clearTenantData(slug: String) {
        withContext(Dispatchers.Default) {
            queries.transaction {
                queries.deleteEmployeeCacheByTenant(slug)
                queries.deleteProductCacheByTenant(slug)
                queries.deleteOrderCacheByTenant(slug)
            }
        }
    }
}