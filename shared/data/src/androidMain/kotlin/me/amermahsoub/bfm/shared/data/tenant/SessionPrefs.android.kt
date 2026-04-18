package me.amermahsoub.bfm.shared.data.tenant

import android.content.Context
import android.content.SharedPreferences

actual class SessionPrefs(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("bfm_session", Context.MODE_PRIVATE)

    actual fun getString(key: String): String? = prefs.getString(key, null)

    actual fun putString(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }

    actual fun remove(key: String) {
        prefs.edit().remove(key).apply()
    }
}
