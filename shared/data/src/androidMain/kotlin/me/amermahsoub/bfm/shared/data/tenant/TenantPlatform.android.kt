package me.amermahsoub.bfm.shared.data.tenant

import android.content.Context
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.okhttp.OkHttp
import me.amermahsoub.bfm.shared.data.db.BfmDatabase
import org.koin.core.module.Module
import org.koin.dsl.module

actual class DatabaseDriverFactory(private val context: Context) {
    actual fun createDriver() = AndroidSqliteDriver(BfmDatabase.Schema, context, "bfm.db")
}

actual fun platformTenantModule(): Module = module {
    single { DatabaseDriverFactory(get()).createDriver() }
}

actual fun platformHttpClientEngine(): HttpClientEngine = OkHttp.create()
