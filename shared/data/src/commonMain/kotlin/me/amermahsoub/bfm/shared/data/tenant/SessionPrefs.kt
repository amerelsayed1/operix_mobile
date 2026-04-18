package me.amermahsoub.bfm.shared.data.tenant

expect class SessionPrefs {
    fun getString(key: String): String?
    fun putString(key: String, value: String)
    fun remove(key: String)
}
