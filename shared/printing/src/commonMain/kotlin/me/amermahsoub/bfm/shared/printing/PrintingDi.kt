package me.amermahsoub.bfm.shared.printing

import org.koin.core.module.Module
import org.koin.dsl.module

fun printingModule(): Module = module {
    includes(platformPrintingModule())
}

expect fun platformPrintingModule(): Module
