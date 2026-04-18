package me.amermahsoub.bfm.shared.data.tenant

import java.util.prefs.Preferences

actual class SessionPrefs {
    private val prefs: Preferences = Preferences.userNodeForPackage(SessionPrefs::class.java)

    actual fun getString(key: String): String? = prefs.get(key, null)

    actual fun putString(key: String, value: String) {
        prefs.put(key, value)
        prefs.flush()
    }

    actual fun remove(key: String) {
        prefs.remove(key)
        prefs.flush()
    }
}
