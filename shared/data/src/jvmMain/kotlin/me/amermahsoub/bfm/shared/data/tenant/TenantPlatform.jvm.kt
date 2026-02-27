package me.amermahsoub.bfm.shared.data.tenant

import app.cash.sqldelight.driver.jdbc.sqlite.JdbcSqliteDriver
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.cio.CIO
import me.amermahsoub.bfm.shared.data.db.BfmDatabase
import org.koin.core.module.Module
import org.koin.dsl.module

actual class DatabaseDriverFactory {
    actual fun createDriver() = JdbcSqliteDriver("jdbc:sqlite:bfm.db").also {
        BfmDatabase.Schema.create(it)
    }
}

actual fun platformTenantModule(): Module = module {
    single { DatabaseDriverFactory().createDriver() }
}

actual fun platformHttpClientEngine(): HttpClientEngine = CIO.create()
