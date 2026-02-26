package me.amermahsoub.bfm

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform