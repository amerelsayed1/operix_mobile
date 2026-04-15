package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.HttpClient
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.db.BfmDatabase
import org.koin.core.module.Module
import org.koin.dsl.module

/**
 * Bootstrap module wiring the tenant HTTP stack, DB, and core stores.
 *
 * [engineFactory] defaults to the real platform engine but can be swapped for
 * a Ktor `MockEngine` in instrumentation tests to render a fully-populated UI
 * without a live backend.
 */
fun tenantBootstrapModule(
    baseUrl: String = defaultTenantBaseUrl(),
    engineFactory: () -> HttpClientEngine = ::platformHttpClientEngine,
): Module = module {
    single {
        Json {
            ignoreUnknownKeys = true
            explicitNulls = false
        }
    }
    single { TenantContext() }
    single { SessionStore() }
    single { TenantAwareApiUrlBuilder(baseUrl, get()) }
    single {
        val appJson = get<Json>()
        val sessionStore = get<SessionStore>()
        val tenantContext = get<TenantContext>()
        HttpClient(engineFactory()) {
            install(ContentNegotiation) {
                json(appJson)
            }
            install(TenantNetworkInterceptor) {
                tokenProvider = { sessionStore.token }
                tenantSlugProvider = { tenantContext.tenantSlug.value }
            }
        }
    }
    single { BfmDatabase(get()) }
    single { TenantApiService(get(), get(), get()) }
    single { TenantRepository(get(), get(), get(), get(), get()) }
    single { ConfigStore(get(), get()) }
    includes(platformTenantModule())
}

expect fun platformTenantModule(): Module
expect fun platformHttpClientEngine(): HttpClientEngine
expect fun defaultTenantBaseUrl(): String
expect fun normalizeTenantBaseUrl(baseUrl: String): String
