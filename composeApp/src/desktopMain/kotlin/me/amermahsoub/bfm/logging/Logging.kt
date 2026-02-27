package me.amermahsoub.bfm.logging

import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging

object AppLogger {
    fun logger(name: String): KLogger = KotlinLogging.logger(name)
}
