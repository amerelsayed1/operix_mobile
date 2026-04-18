package me.amermahsoub.bfm.app.nav

import androidx.compose.runtime.Composable

@Composable
actual fun PlatformBackHandler(enabled: Boolean, onBack: () -> Unit) {
    // iOS uses swipe-back gesture handled by the system
}
