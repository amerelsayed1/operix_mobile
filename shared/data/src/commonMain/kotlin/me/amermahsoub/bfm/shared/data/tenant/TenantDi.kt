package me.amermahsoub.bfm.shared.data.tenant

import io.ktor.client.HttpClient
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import me.amermahsoub.bfm.shared.data.db.BfmDatabase
import org.koin.core.module.Module
import org.koin.dsl.module

private const val DEFAULT_BASE_URL = "http://127.0.0.1:8000"

fun tenantBootstrapModule(baseUrl: String = DEFAULT_BASE_URL): Module = module {
    single {
        Json {
            ignoreUnknownKeys = true
            explicitNulls = false
        }
    }
    single { TenantContext(baseUrl) }
    single { TenantAwareApiUrlBuilder(get()) }
    single {
        val appJson = get<Json>()
        HttpClient(platformHttpClientEngine()) {
            install(ContentNegotiation) {
                json(appJson)
            }
        }
    }
    single { BfmDatabase(get()) }
    single { TenantApiService(get(), get()) }
    single { TenantRepository(get(), get(), get()) }
    single { ConfigStore(get(), get()) }
    includes(platformTenantModule())
}

expect fun platformTenantModule(): Module
expect fun platformHttpClientEngine(): io.ktor.client.engine.HttpClientEngine
