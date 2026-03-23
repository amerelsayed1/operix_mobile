package me.amermahsoub.bfm.shared.data.tenant

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToOneOrNull
import io.ktor.util.date.getTimeMillis
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
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
    private val sessionStore: SessionStore,
    private val tenantContext: TenantContext,
    private val json: Json,
) {
    private val queries = database.tenantQueries

    private fun nowIso(): String = Instant.fromEpochMilliseconds(getTimeMillis()).toString()

    fun getSelectedTenantSlug(): Flow<String?> =
        queries.selectTenantSlug()
            .asFlow()
            .mapToOneOrNull(Dispatchers.Default)
            .distinctUntilChanged()

    suspend fun selectTenant(slug: String) {
        withContext(Dispatchers.Default) {
            queries.upsertSelectedTenant(
                tenant_slug = slug,
                selected_at = nowIso(),
            )
        }
        tenantContext.setTenantSlug(slug)
    }

    fun getCachedConfig(slug: String): Flow<TenantConfig?> =
        queries.selectTenantConfigBySlug(slug)
            .asFlow()
            .mapToOneOrNull(Dispatchers.Default)
            .map { jsonString ->
                jsonString?.let { json.decodeFromString<TenantBootstrapResponse>(it).tenant }
            }
            .distinctUntilChanged()

    suspend fun getCachedConfigOnce(slug: String): TenantConfig? = getCachedConfig(slug).first()

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

    suspend fun loginAndBootstrapSession(slug: String, username: String, password: String): SessionBootstrap = coroutineScope {
        tenantContext.setTenantSlug(slug)
        val login = apiService.login(slug, username, password)
        sessionStore.update(
            SessionBootstrap(
                login = login,
                me = login.user,
                permissions = emptyList(),
                tenantConfig = null,
            ),
        )

        val meDeferred = async { apiService.fetchCurrentUser() }
        val permissionsDeferred = async { apiService.fetchPermissions() }
        val configDeferred = async { runCatching { apiService.fetchProtectedConfig() }.getOrNull() }

        val session = SessionBootstrap(
            login = login,
            me = meDeferred.await(),
            permissions = permissionsDeferred.await(),
            tenantConfig = configDeferred.await(),
        )
        sessionStore.update(session)
        session
    }

    suspend fun logout() {
        runCatching { apiService.logout() }
        sessionStore.clear()
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
