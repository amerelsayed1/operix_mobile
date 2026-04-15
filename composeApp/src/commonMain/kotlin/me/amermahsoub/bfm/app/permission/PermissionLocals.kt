package me.amermahsoub.bfm.app.permission

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import me.amermahsoub.bfm.shared.domain.permissions.PermissionGuard

/**
 * Exposes the current [PermissionGuard] to composables. Use
 * `LocalPermissionGuard.current.has("pos.create")` in UI gates.
 */
val LocalPermissionGuard = staticCompositionLocalOf { PermissionGuard.Empty }

@Composable
fun IfPermitted(vararg anyOf: String, content: @Composable () -> Unit) {
    val guard = LocalPermissionGuard.current
    if (anyOf.isEmpty() || guard.hasAny(*anyOf)) content()
}
