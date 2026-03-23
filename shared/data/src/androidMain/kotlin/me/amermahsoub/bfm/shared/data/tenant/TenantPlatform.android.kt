package me.amermahsoub.bfm.shared.data.tenant

import android.content.Context
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.okhttp.OkHttp
import me.amermahsoub.bfm.shared.data.db.BfmDatabase
import org.koin.core.module.Module
import org.koin.dsl.module

actual class DatabaseDriverFactory(private val context: Context) {
    actual fun createDriver(): SqlDriver = AndroidSqliteDriver(BfmDatabase.Schema, context, "bfm.db")
}

actual fun platformTenantModule(): Module = module {
    single { DatabaseDriverFactory(get()).createDriver() }
}

actual fun platformHttpClientEngine(): HttpClientEngine = OkHttp.create()

actual fun defaultTenantBaseUrl(): String = "http://10.0.2.2:8000"

actual fun normalizeTenantBaseUrl(baseUrl: String): String =
    baseUrl
        .replace("http://localhost", "http://10.0.2.2")
        .replace("https://localhost", "http://10.0.2.2")
        .replace("http://127.0.0.1", "http://10.0.2.2")
        .replace("https://127.0.0.1", "http://10.0.2.2")
