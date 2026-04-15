package me.amermahsoub.bfm.app.nav

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * Minimal stack-based navigator. Keeps feature code free of a router
 * dependency while supporting push/pop/replace and root swaps.
 */
@Stable
class AppNavigator internal constructor(initial: Route) {
    private val _stack = mutableStateListOf(initial)
    val stack: List<Route> get() = _stack
    val current: Route get() = _stack.last()

    fun push(route: Route) {
        _stack.add(route)
    }

    fun replace(route: Route) {
        if (_stack.isNotEmpty()) _stack.removeAt(_stack.lastIndex)
        _stack.add(route)
    }

    /** Swap the entire stack to a new root. Used post-login / post-logout. */
    fun reset(root: Route) {
        _stack.clear()
        _stack.add(root)
    }

    fun pop(): Boolean {
        if (_stack.size <= 1) return false
        _stack.removeAt(_stack.lastIndex)
        return true
    }
}

@Composable
fun rememberAppNavigator(initial: Route): AppNavigator =
    remember { AppNavigator(initial) }

val LocalAppNavigator = staticCompositionLocalOf<AppNavigator> {
    error("No AppNavigator provided")
}
