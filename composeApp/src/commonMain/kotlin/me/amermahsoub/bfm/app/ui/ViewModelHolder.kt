package me.amermahsoub.bfm.app.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * Lightweight scope holder used by feature ViewModels. Each call to
 * [rememberFeatureViewModel] creates a ViewModel bound to a composition-scoped
 * [CoroutineScope] which is cancelled when the composition leaves.
 *
 * We use [Dispatchers.Default] so the scope works uniformly on Android and
 * desktop without pulling in a platform-specific Main dispatcher.
 */
abstract class FeatureViewModel {
    val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    open fun dispose() {
        scope.cancel()
    }
}

@Composable
inline fun <reified VM : FeatureViewModel> rememberFeatureViewModel(crossinline factory: () -> VM): VM {
    val vm = remember { factory() }
    DisposableEffect(vm) {
        onDispose { vm.dispose() }
    }
    return vm
}
