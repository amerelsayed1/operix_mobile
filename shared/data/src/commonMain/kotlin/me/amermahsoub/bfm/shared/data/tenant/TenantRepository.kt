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

    suspend fun loginAndBootstrapSession(
        slug: String,
        email: String,
        password: String,
        rememberMe: Boolean = false,
    ): SessionBootstrap = coroutineScope {
        tenantContext.setTenantSlug(slug)
        val login = apiService.login(slug, email, password, rememberMe)
        val initial = SessionBootstrap(
            login = login,
            me = login.user,
            permissions = emptyList(),
            tenantConfig = null,
        )
        sessionStore.update(initial)
        persistSession(slug, initial)

        val meDeferred = async { runCatching { apiService.fetchCurrentUser() }.getOrNull() ?: login.user }
        val permissionsDeferred = async { runCatching { apiService.fetchPermissions() }.getOrNull().orEmpty() }
        val configDeferred = async { runCatching { apiService.fetchProtectedConfig() }.getOrNull() }

        val session = SessionBootstrap(
            login = login,
            me = meDeferred.await(),
            permissions = permissionsDeferred.await(),
            tenantConfig = configDeferred.await(),
        )
        sessionStore.update(session)
        persistSession(slug, session)
        session
    }

    suspend fun logout() {
        runCatching { apiService.logout() }
        sessionStore.clear()
        clearStoredSession()
    }

    /**
     * Hydrates [SessionStore] from the locally persisted session, if any.
     * Safe to call on cold start — silently no-ops when nothing is stored
     * or the stored payload cannot be decoded (e.g. after a schema change).
     */
    suspend fun restoreSession(): SessionBootstrap? = withContext(Dispatchers.Default) {
        val row = queries.selectSession().executeAsOneOrNull() ?: return@withContext null
        val stored = runCatching {
            json.decodeFromString<SessionBootstrap>(row.json)
        }.getOrElse {
            // Corrupt / incompatible payload — drop it so we don't wedge the app.
            queries.deleteSession()
            return@withContext null
        }
        tenantContext.setTenantSlug(row.tenant_slug)
        sessionStore.update(stored)
        stored
    }

    private suspend fun persistSession(slug: String, session: SessionBootstrap) {
        withContext(Dispatchers.Default) {
            queries.upsertSession(
                tenant_slug = slug,
                json = json.encodeToString(session),
                updated_at = nowIso(),
            )
        }
    }

    private suspend fun clearStoredSession() {
        withContext(Dispatchers.Default) {
            queries.deleteSession()
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
